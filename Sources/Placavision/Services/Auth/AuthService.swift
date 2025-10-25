import Foundation

public final class AuthService {
    private let repository = Repository()
    private let fileHelper = FileHelper()

    public init() {}

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
            completion(.success(response))
            return
        }

        // Validate credentials format
        guard email.contains("@"), !password.isEmpty else {
            completion(.failure(AuthError.invalidCredentials))
            return
        }

        // Attempt remote login
        repository.login(email: email, password: password) { result in
            switch result {
            case .success(let json):
                if let token = json["access_token"] as? String {
                    self.fileHelper.saveAuthToken(token)
                    self.fileHelper.clearUsersFile()
                    self.fileHelper.setCurrentUser(email)
                    
                    let response = AuthResponse(
                        token: token,
                        message: "Inicio de sesión exitoso",
                        user: User(
                            correo: email,
                            contrasena: "",
                            nombre_usuario: json["username"] as? String,
                            role: json["role"] as? String
                        )
                    )
                    completion(.success(response))
                } else {
                    completion(.failure(AuthError.tokenMissing))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Logs out the current user
    public func logout() {
        fileHelper.clearCurrentUser()
    }

    /// Checks if there's a valid auth token
    public var isAuthenticated: Bool {
        !fileHelper.isTokenExpired()
    }

    /// Gets the current authentication token
    public var currentToken: String? {
        fileHelper.getAuthToken()
    }

    /// Validates backup admin credentials
    public static func isValidBackupCredentials(email: String, password: String) -> Bool {
        return email == FileHelper.backupAdminEmail && password == FileHelper.backupAdminPassword
    }

    public struct AuthResponse {
        public let token: String
        public let message: String
        public let user: User
    }

    public enum AuthError: Error, LocalizedError {
        case tokenMissing
        case invalidCredentials
        case sessionExpired
        case networkError

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
            }
        }
    }
}
