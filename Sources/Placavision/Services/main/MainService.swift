import Foundation

public final class MainService {
    private let repository = Repository()
    private let fileHelper = FileHelper()
    private let authService = AuthService()

    public init() {}

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

    /// Get current user profile
    public func getCurrentUser() -> User? {
        fileHelper.getCurrentUser()
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
