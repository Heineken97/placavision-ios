import Foundation

public final class RecoveryService {
    private let repository = Repository()
    private let recoveryPattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#

    public init() {}

    /// Validates email format before starting recovery process
    public func validateEmail(_ email: String) -> Result<Void, ValidationError> {
        guard !email.isEmpty else {
            return .failure(.emptyEmail)
        }

        guard email.range(of: recoveryPattern, options: .regularExpression) != nil else {
            return .failure(.invalidEmail)
        }

        return .success(())
    }

    /// Requests password recovery from backend
    /// - Parameters:
    ///   - email: User's email address
    ///   - completion: Called with temporary password or error
    public func recoverPassword(email: String, completion: @escaping (Result<RecoveryResponse, Error>) -> Void) {
        // First validate email locally
        switch validateEmail(email) {
        case .success:
            repository.recoverPassword(email: email) { result in
                switch result {
                case .success(let json):
                    if let tempPassword = json["temp_password"] as? String {
                        let response = RecoveryResponse(
                            tempPassword: tempPassword,
                            message: "Contraseña temporal enviada al correo"
                        )
                        completion(.success(response))
                    } else {
                        completion(.failure(ValidationError.serverError))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        case .failure(let error):
            completion(.failure(error))
        }
    }

    public struct RecoveryResponse {
        public let tempPassword: String
        public let message: String
    }

    public enum ValidationError: Error, LocalizedError {
        case emptyEmail
        case invalidEmail
        case serverError

        public var errorDescription: String? {
            switch self {
            case .emptyEmail:
                return "El correo no puede estar vacío"
            case .invalidEmail:
                return "Formato de correo inválido"
            case .serverError:
                return "Error al procesar la solicitud"
            }
        }
    }
}
