import Foundation

public final class AuthService {
    private let repository: RepositoryProtocol
    private let fileHelper: FileHelperProtocol
    private var refreshTimer: DispatchSourceTimer?
    private let refreshQueue = DispatchQueue(label: "com.placavision.auth", qos: .utility)
    private let tokenRefreshInterval: TimeInterval = 15 * 60 // 15 minutes
    private var lastLoginDate: Date?
    private var isRefreshing = false

    public convenience init() {
        self.init(repository: Repository(), fileHelper: FileHelper())
    }
    
    public init(repository: Repository, fileHelper: FileHelper) {
        self.repository = repository
        self.fileHelper = fileHelper
        setupTokenRefresh()
    }

    deinit {
        refreshTimer?.cancel()
    }

    /// Attempts to log in a user with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    ///   - completion: Called with AuthResponse on success or error on failure
    public func login(email: String, password: String, completion: @escaping (Result<AuthResponse, Error>) -> Void) {
        // Try backup credentials first
        if Self.isValidBackupCredentials(email: email, password: password) {
            fileHelper.setCurrentUser(email)
            let response = AuthResponse(
                token: "backup_token",
                message: "Inicio de sesión con credenciales de respaldo",
                user: User(correo: email, contrasena: "", role: "admin")
            )
            lastLoginDate = Date()
            startTokenRefresh()
            completion(.success(response))
            return
        }

        // Validate credentials format
        guard validateCredentials(email: email, password: password) else {
            completion(.failure(AuthError.invalidCredentials))
            return
        }

        // Attempt remote login
        repository.login(email: email, password: password) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let json):
                if let token = json["access_token"] as? String {
                    self.handleSuccessfulLogin(
                        token: token,
                        email: email,
                        userData: json,
                        completion: completion
                    )
                } else {
                    completion(.failure(AuthError.tokenMissing))
                }
            case .failure(let error):
                if let apiError = error as? APIClient.APIError {
                    switch apiError {
                    case .invalidStatusCode(401):
                        completion(.failure(AuthError.invalidCredentials))
                    case .invalidStatusCode(403):
                        completion(.failure(AuthError.accountDisabled))
                    default:
                        completion(.failure(AuthError.networkError))
                    }
                } else {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func validateCredentials(email: String, password: String) -> Bool {
        let emailPattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let emailValid = email.range(of: emailPattern, options: .regularExpression) != nil
        let passwordValid = password.count >= 6
        return emailValid && passwordValid
    }
    
    private func handleSuccessfulLogin(
        token: String,
        email: String,
        userData: [String: Any],
        completion: @escaping (Result<AuthResponse, Error>) -> Void
    ) {
        fileHelper.saveAuthToken(token)
        fileHelper.clearUsersFile()
        fileHelper.setCurrentUser(email)
        
        let user = User(
            correo: email,
            contrasena: "",
            nombre_usuario: userData["username"] as? String,
            identificador_nacional: userData["national_id"] as? String,
            telefono: userData["phone"] as? String,
            role: userData["role"] as? String
        )
        
        fileHelper.saveUser(user)
        lastLoginDate = Date()
        startTokenRefresh()
        
        let response = AuthResponse(
            token: token,
            message: "Inicio de sesión exitoso",
            user: user
        )
        completion(.success(response))
    }

    /// Logs out the current user
    public func logout() {
        stopTokenRefresh()
        fileHelper.clearCurrentUser()
        lastLoginDate = nil
    }

    /// Checks if there's a valid auth token
    public var isAuthenticated: Bool {
        guard !fileHelper.isTokenExpired() else {
            refreshTokenIfNeeded()
            return false
        }
        return true
    }

    /// Gets the current authentication token
    public var currentToken: String? {
        fileHelper.getAuthToken()
    }

    /// Get current authentication state with more details
    public var sessionState: SessionState {
        guard currentToken != nil else {
            return .loggedOut
        }
        
        if fileHelper.isTokenExpired() {
            return .expired
        }
        
        if isRefreshing {
            return .refreshing
        }
        
        guard let user = fileHelper.getCurrentUser() else {
            return .loggedOut
        }
        
        if !user.correo.isEmpty {
            return .authenticated(user)
        }
        
        return .loggedOut
    }

    /// Validates backup admin credentials
    public static func isValidBackupCredentials(email: String, password: String) -> Bool {
        return email == FileHelper.backupAdminEmail && password == FileHelper.backupAdminPassword
    }
    
    private func setupTokenRefresh() {
        let timer = DispatchSource.makeTimerSource(queue: refreshQueue)
        timer.schedule(deadline: .now() + tokenRefreshInterval, repeating: tokenRefreshInterval)
        timer.setEventHandler { [weak self] in
            self?.refreshTokenIfNeeded()
        }
        refreshTimer = timer
    }
    
    private func startTokenRefresh() {
        refreshTimer?.resume()
    }
    
    private func stopTokenRefresh() {
        refreshTimer?.cancel()
        refreshTimer = nil
        isRefreshing = false
    }
    
    private func refreshTokenIfNeeded() {
        guard !isRefreshing,
              let lastLogin = lastLoginDate,
              Date().timeIntervalSince(lastLogin) >= tokenRefreshInterval else {
            return
        }
        
        isRefreshing = true
        
        // Use current credentials to refresh token
        guard let user = fileHelper.getCurrentUser() else {
            isRefreshing = false
            return
        }
        
        repository.login(email: user.correo, password: user.contrasena) { [weak self] result in
            guard let self = self else { return }
            defer { self.isRefreshing = false }
            
            switch result {
            case .success(let json):
                if let token = json["access_token"] as? String {
                    self.fileHelper.saveAuthToken(token)
                    self.lastLoginDate = Date()
                }
            case .failure:
                self.stopTokenRefresh()
            }
        }
    }

    public struct AuthResponse {
        public let token: String
        public let message: String
        public let user: User
    }

    public enum SessionState: Equatable {
        case loggedOut
        case authenticated(User)
        case expired
        case refreshing
        
        public static func == (lhs: SessionState, rhs: SessionState) -> Bool {
            switch (lhs, rhs) {
            case (.loggedOut, .loggedOut),
                 (.expired, .expired),
                 (.refreshing, .refreshing):
                return true
            case (.authenticated(let l), .authenticated(let r)):
                return l.correo == r.correo
            default:
                return false
            }
        }
        
        public var description: String {
            switch self {
            case .loggedOut:
                return "No autenticado"
            case .authenticated:
                return "Autenticado"
            case .expired:
                return "Sesión expirada"
            case .refreshing:
                return "Actualizando sesión"
            }
        }
    }
    
    public enum AuthError: Error, LocalizedError {
        case tokenMissing
        case invalidCredentials
        case sessionExpired
        case networkError
        case accountDisabled
        case tokenRefreshFailed

        public var errorDescription: String? {
            switch self {
            case .tokenMissing:
                return "Token de autenticación no encontrado"
            case .invalidCredentials:
                return "Credenciales inválidas"
            case .sessionExpired:
                return "Sesión expirada"
            case .networkError:
                return "Error de conexión"
            case .accountDisabled:
                return "Cuenta deshabilitada"
            case .tokenRefreshFailed:
                return "Error al actualizar la sesión"
            }
        }
        
        public var isRecoverable: Bool {
            switch self {
            case .networkError, .sessionExpired, .tokenRefreshFailed:
                return true
            case .tokenMissing, .invalidCredentials, .accountDisabled:
                return false
            }
        }
    }
}
