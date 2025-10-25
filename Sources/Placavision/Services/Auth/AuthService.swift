import Foundation

public struct AuthService {
    public static let backupAdminEmail = "admin@placavision.com"
    public static let backupAdminPassword = "admin123"

    public static func isValidBackupCredentials(email: String, password: String) -> Bool {
        return email == backupAdminEmail && password == backupAdminPassword
    }

    public static func login(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        let credentials = ["email": email, "password": password]
        APIClient.post(endpoint: "/login", body: credentials) { result in
            switch result {
            case .success(let data):
                if let token = data["access_token"] as? String {
                    completion(.success(token))
                } else {
                    completion(.failure(AuthError.tokenMissing))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public enum AuthError: Error {
        case tokenMissing
    }
}
