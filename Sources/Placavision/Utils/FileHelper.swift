import Foundation

public final class FileHelper {
    private let fileManager = FileManager.default
    private let usersFile: URL
    private let prefs = UserDefaults.standard
    private let imageDir: URL

    public init() {
        let baseDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.usersFile = baseDir.appendingPathComponent("users.json")
        self.imageDir = baseDir.appendingPathComponent("images")

        if !fileManager.fileExists(atPath: imageDir.path) {
            try? fileManager.createDirectory(at: imageDir, withIntermediateDirectories: true)
        }
    }

    public func getCurrentUser() -> User? {
        guard let email = prefs.string(forKey: "current_user_email") else {
            return nil
        }
        return findUserByEmail(email)
    }

    public func setCurrentUser(_ email: String) {
        if findUserByEmail(email) != nil {
            prefs.set(email, forKey: "current_user_email")
        }
    }

    public func clearCurrentUser() {
        let email = prefs.string(forKey: "current_user_email")
        prefs.removeObject(forKey: "current_user_email")
        let users = getUsers().filter { $0.correo != email }
        saveUserList(users)
    }

    public func saveUser(_ user: User) {
        var users = getUsers()
        if let index = users.firstIndex(where: { $0.correo == user.correo }) {
            users[index] = user
        } else {
            users.append(user)
        }
        saveUserList(users)
        if getCurrentUser().correo == user.correo {
            setCurrentUser(user.correo)
        }
    }

    public func getUsers() -> [User] {
        guard fileManager.fileExists(atPath: usersFile.path),
              let data = try? Data(contentsOf: usersFile),
              let users = try? JSONDecoder().decode([User].self, from: data) else {
            return []
        }
        return users
    }

    public func findUserByEmail(_ email: String) -> User? {
        return getUsers().first { $0.correo == email }
    }

    public func findUserByUsername(_ username: String) -> User? {
        return getUsers().first { $0.nombre_usuario == username }
    }

    public func saveUserList(_ users: [User]) {
        if let data = try? JSONEncoder().encode(users) {
            try? data.write(to: usersFile)
        }
    }

    public func saveAuthToken(_ token: String) {
        prefs.set(token, forKey: "auth_token")
    }

    public func getAuthToken() -> String? {
        return prefs.string(forKey: "auth_token")
    }

    public func isTokenExpired() -> Bool {
        guard let token = getAuthToken(),
              let payload = decodeJWT(token),
              let exp = payload["exp"] as? Double else {
            return true
        }
        return exp * 1000 < Date().timeIntervalSince1970 * 1000
    }

    public func clearUsersFile() {
        try? "[]".data(using: .utf8)?.write(to: usersFile)
    }

    private func decodeJWT(_ token: String) -> [String: Any]? {
        let parts = token.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        let payloadBase64 = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        guard let data = Data(base64Encoded: payloadBase64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json
    }

    public static let backupAdminEmail = "admin@placavision.com"
    public static let backupAdminPassword = "admin123"
}
