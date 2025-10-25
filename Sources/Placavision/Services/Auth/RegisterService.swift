import Foundation

public final class RegisterService {
    private let repository = Repository()
    private let fileHelper = FileHelper()

    public init() {}

    public func register(user: User, completion: @escaping (Result<String, Error>) -> Void) {
        // Validaciones locales
        guard validateEmail(user.correo) else {
            completion(.failure(RegisterError.invalidEmail))
            return
        }

        guard validatePassword(user.contrasena) else {
            completion(.failure(RegisterError.weakPassword))
            return
        }

        if fileHelper.findUserByEmail(user.correo) != nil {
            completion(.failure(RegisterError.emailAlreadyExists))
            return
        }

        if let username = user.nombre_usuario,
           fileHelper.findUserByUsername(username) != nil {
            completion(.failure(RegisterError.usernameAlreadyExists))
            return
        }

        // Registro remoto
        repository.register(user: user) { result in
            switch result {
            case .success:
                self.fileHelper.clearUsersFile()
                self.fileHelper.saveUser(user)
                self.fileHelper.setCurrentUser(user.correo)
                completion(.success("Registro exitoso"))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func validateEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    private func validatePassword(_ password: String) -> Bool {
        return getPasswordStrength(password) >= 80
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

    public enum RegisterError: Error {
        case invalidEmail
        case weakPassword
        case emailAlreadyExists
        case usernameAlreadyExists
    }
}
