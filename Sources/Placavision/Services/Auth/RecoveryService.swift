import Foundation

public final class RecoveryService {
    private let repository = Repository()

    public init() {}

    /// Valida el correo electrónico antes de iniciar recuperación.
    public func validateEmail(_ email: String) -> Result<Void, ValidationError> {
        guard !email.isEmpty else {
            return .failure(.emptyEmail)
        }

        guard email.contains("@"), email.contains(".") else {
            return .failure(.invalidEmail)
        }

        return .success(())
    }

    /// Solicita al backend la recuperación de contraseña.
    public func recoverPassword(email: String, completion: @escaping (Result<String, Error>) -> Void) {
        repository.recoverPassword(email: email) { result in
            switch result {
            case .success(let json):
                let tempPassword = json["temp_password"] as? String ?? "N/A"
                completion(.success(tempPassword))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public enum ValidationError: Error {
        case emptyEmail
        case invalidEmail
    }
}
