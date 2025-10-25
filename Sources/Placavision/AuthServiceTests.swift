import Foundation

public struct AuthService {
    public static func login(email: String, password: String, completion: @escaping (Bool) -> Void) {
        let success = (email == "test@example.com" && password == "1234")
        completion(success)
    }

    public static func register(name: String, email: String, password: String, completion: @escaping (Bool) -> Void) {
        completion(true) // Simulado
    }
}
