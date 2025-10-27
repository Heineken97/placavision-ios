import Foundation
@testable import Placavision

/// Mock FileHelper for testing that uses in-memory storage
final class MockFileHelper: FileHelper {
    private var users: [User] = []
    private var currentUserEmail: String?
    private var authToken: String?
    
    override public func getCurrentUser() -> User? {
        guard let email = currentUserEmail else { return nil }
        return findUserByEmail(email)
    }
    
    override public func setCurrentUser(_ email: String) {
        if findUserByEmail(email) != nil {
            currentUserEmail = email
        }
    }
    
    override public func clearCurrentUser() {
        currentUserEmail = nil
        users.removeAll()
    }
    
    override public func saveUser(_ user: User) {
        if let index = users.firstIndex(where: { $0.correo == user.correo }) {
            users[index] = user
        } else {
            users.append(user)
        }
    }
    
    override public func getUsers() -> [User] {
        return users
    }
    
    override public func findUserByEmail(_ email: String) -> User? {
        return users.first { $0.correo == email }
    }
    
    override public func findUserByUsername(_ username: String) -> User? {
        return users.first { $0.nombre_usuario == username }
    }
    
    override public func saveUserList(_ users: [User]) {
        self.users = users
    }
    
    override public func saveAuthToken(_ token: String) {
        self.authToken = token
    }
    
    override public func getAuthToken() -> String? {
        return authToken
    }
    
    override public func isTokenExpired() -> Bool {
        return false // For testing, assume token is always valid
    }
    
    override public func clearUsersFile() {
        users.removeAll()
    }
}