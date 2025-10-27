import Foundation
@testable import Placavision

/// Mock FileHelper for testing that uses in-memory storage
final class MockFileHelper: FileHelperProtocol {
    private var users: [User] = []
    private var currentUserEmail: String?
    private var authToken: String?
    var isTokenExpired: Bool = false

    public init() {}

    public func getCurrentUser() -> User? {
        guard let email = currentUserEmail else { return nil }
        return findUserByEmail(email)
    }

    public func setCurrentUser(_ email: String) {
        if findUserByEmail(email) != nil {
            currentUserEmail = email
        }
    }

    public func clearCurrentUser() {
        currentUserEmail = nil
        users.removeAll()
    }

    public func saveUser(_ user: User) {
        if let index = users.firstIndex(where: { $0.correo == user.correo }) {
            users[index] = user
        } else {
            users.append(user)
        }
    }

    public func getUsers() -> [User] {
        return users
    }

    public func findUserByEmail(_ email: String) -> User? {
        return users.first { $0.correo == email }
    }

    public func findUserByUsername(_ username: String) -> User? {
        return users.first { $0.nombre_usuario == username }
    }

    public func saveUserList(_ users: [User]) {
        self.users = users
    }

    public func saveAuthToken(_ token: String) {
        self.authToken = token
    }

    public func getAuthToken() -> String? {
        return authToken
    }

    public func isTokenExpired() -> Bool {
        return isTokenExpired
    }

    public func clearUsersFile() {
        users.removeAll()
    }
}