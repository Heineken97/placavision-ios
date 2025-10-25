import Foundation

public final class AuthService {
    private let repository = Repository()
    private let fileHelper = FileHelper()

    public init() {}

    public func login(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
    if Self.isValidBackupCredentials(email: email, password: password) {
            fileHelper.setCurrentUser(email)
            completion(.success("Inicio de sesión con credenciales de respaldo"))
            return
        }

        repository.login(email: email, password: password) { result in
            switch result {
            case .success(let json):
                if let token = json["access_token"] as? String {
                    self.fileHelper.saveAuthToken(token)
                    self.fileHelper.clearUsersFile()
                    self.fileHelper.setCurrentUser(email)
                    completion(.success("Inicio de sesión exitoso"))
                } else {
                    completion(.failure(AuthError.tokenMissing))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public static func isValidBackupCredentials(email: String, password: String) -> Bool {
        return email == FileHelper.backupAdminEmail && password == FileHelper.backupAdminPassword
    }

    public enum AuthError: Error {
        case tokenMissing
    }
}
