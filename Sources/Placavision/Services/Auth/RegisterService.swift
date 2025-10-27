import Foundation

public final class RegisterService {
    private let repository: RepositoryProtocol
    private let fileHelper: FileHelperProtocol
    private let emailPattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#

    public init() {
        let repo = Repository()
        let fh = FileHelper()
        self.repository = repo
        self.fileHelper = fh
    }

    // DI initializer for tests
    public init(repository: RepositoryProtocol, fileHelper: FileHelperProtocol) {
        self.repository = repository
        self.fileHelper = fileHelper
    }

    /// Register a new user with validation
    /// - Parameters:
    ///   - user: User data for registration
    ///   - completion: Called with RegisterResponse on success or error on failure
    public func register(user: User, completion: @escaping (Result<RegisterResponse, Error>) -> Void) {
        // Validate all fields first
        do {
            try validateRegistration(user)
        } catch let error as RegisterError {
            completion(.failure(error))
            return
        } catch {
            completion(.failure(RegisterError.validationFailed))
            return
        }

        // Attempt remote registration
        repository.register(user: user) { result in
            switch result {
            case .success:
                self.fileHelper.clearUsersFile()
                self.fileHelper.saveUser(user)
                self.fileHelper.setCurrentUser(user.correo)
                
                let response = RegisterResponse(
                    user: user,
                    message: "Registro exitoso",
                    validationStatus: .success
                )
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Validates all registration fields
    private func validateRegistration(_ user: User) throws {
        // Email validation
        guard validateEmail(user.correo) else {
            throw RegisterError.invalidEmail
        }

        // Password strength
        guard validatePassword(user.contrasena) else {
            throw RegisterError.weakPassword
        }

        // Check existing email
        if fileHelper.findUserByEmail(user.correo) != nil {
            throw RegisterError.emailAlreadyExists
        }

        // Check username if provided
        if let username = user.nombre_usuario {
            if username.isEmpty {
                throw RegisterError.invalidUsername
            }
            if fileHelper.findUserByUsername(username) != nil {
                throw RegisterError.usernameAlreadyExists
            }
        }

        // Additional validations
        if let phone = user.telefono, !validatePhone(phone) {
            throw RegisterError.invalidPhone
        }
    }

    private func validateEmail(_ email: String) -> Bool {
        return email.range(of: emailPattern, options: .regularExpression) != nil
    }

    private func validatePassword(_ password: String) -> Bool {
        return getPasswordStrength(password) >= 80
    }

    private func validatePhone(_ phone: String) -> Bool {
        return phone.count >= 8 && phone.allSatisfy(\.isNumber)
    }

    private func getPasswordStrength(_ password: String) -> Int {
        var score = 0
        if password.count >= 8 { score += 30 }
        if password.contains(where: \.isUppercase) { score += 20 }
        if password.contains(where: \.isLowercase) { score += 20 }
        if password.contains(where: \.isNumber) { score += 20 }
        if password.contains(where: { !$0.isLetter && !$0.isNumber }) { score += 10 }
        return min(score, 100)
    }

    public struct RegisterResponse {
        public let user: User
        public let message: String
        public let validationStatus: ValidationStatus
        
        public enum ValidationStatus {
            case success
            case pending
            case failed
        }
    }

    public enum RegisterError: Error, LocalizedError {
        case invalidEmail
        case weakPassword
        case emailAlreadyExists
        case usernameAlreadyExists
        case invalidUsername
        case invalidPhone
        case validationFailed
        case networkError

        public var errorDescription: String? {
            switch self {
            case .invalidEmail:
                return "Formato de correo inválido"
            case .weakPassword:
                return "Contraseña débil"
            case .emailAlreadyExists:
                return "Correo ya registrado"
            case .usernameAlreadyExists:
                return "Nombre de usuario no disponible"
            case .invalidUsername:
                return "Nombre de usuario inválido"
            case .invalidPhone:
                return "Número de teléfono inválido"
            case .validationFailed:
                return "Error de validación"
            case .networkError:
                return "Error de conexión"
            }
        }
    }
}
