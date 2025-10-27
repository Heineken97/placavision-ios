import Foundation

public final class MainService {
    private let repository: RepositoryProtocol
    private let fileHelper: FileHelperProtocol
    private let authService: AuthService

    public init() {
        let repo = Repository()
        let fh = FileHelper()
        self.repository = repo
        self.fileHelper = fh
        self.authService = AuthService(repository: repo, fileHelper: fh)
    }

    // Dependency-injection initializer used by tests
    public init(repository: RepositoryProtocol, fileHelper: FileHelperProtocol) {
        self.repository = repository
        self.fileHelper = fileHelper
        self.authService = AuthService(repository: repository, fileHelper: fileHelper)
    }

    /// Check current session state and return appropriate screen
    public func checkInitialState() -> MainTarget {
        if !authService.isAuthenticated {
            return .login
        }
        return .viewReports
    }

    /// Handle user session management
    public func logout(completion: @escaping (Result<String, Error>) -> Void) {
        fileHelper.clearCurrentUser()
        completion(.success("Sesión cerrada exitosamente"))
    }

    /// Get current user profile, optionally syncing with remote
    /// - Parameters:
    ///   - sync: Whether to fetch latest profile from server
    ///   - completion: Called with updated user or error if sync=true
    public func getCurrentUser(sync: Bool = false, completion: ((Result<User?, Error>) -> Void)? = nil) -> User? {
        let local = fileHelper.getCurrentUser()
        
        if sync {
            repository.getUser { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let json):
                    if let email = json["email"] as? String,
                       let role = json["role"] as? String {
                        let updated = User(
                            correo: email,
                            contrasena: local?.contrasena ?? "",
                            nombre_usuario: json["username"] as? String,
                            identificador_nacional: json["national_id"] as? String,
                            telefono: json["phone"] as? String,
                            role: role
                        )
                        self.fileHelper.saveUser(updated)
                        completion?(.success(updated))
                    } else {
                        completion?(.success(local))
                    }
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
        } else if let completion = completion {
            completion(.success(local))
        }
        
        return local
    }

    /// Check if user has admin privileges
    public var isAdmin: Bool {
        getCurrentUser()?.role == "admin"
    }

    /// Get current session state
    public var sessionState: SessionState {
        if !authService.isAuthenticated {
            return .loggedOut
        }
        if let user = getCurrentUser() {
            return .active(user: user)
        }
        return .error(message: "Usuario no encontrado")
    }

    public enum SessionState {
        case active(user: User)
        case loggedOut
        case error(message: String)
    }

    public enum MainTarget: Equatable {
        case login
        case reportPlate
        case gps
        case viewReports
        case editProfile
        case videoFeed

        public var requiresAuth: Bool {
            switch self {
            case .login:
                return false
            default:
                return true
            }
        }
    }
}
