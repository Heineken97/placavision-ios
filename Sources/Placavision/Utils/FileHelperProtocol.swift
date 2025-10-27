import Foundation

public protocol FileHelperProtocol {
    func getCurrentUser() -> User?
    func setCurrentUser(_ email: String)
    func clearCurrentUser()
    func saveUser(_ user: User)
    func getUsers() -> [User]
    func findUserByEmail(_ email: String) -> User?
    func findUserByUsername(_ username: String) -> User?
    func saveUserList(_ users: [User])
    func saveAuthToken(_ token: String)
    func getAuthToken() -> String?
    func isTokenExpired() -> Bool
    func clearUsersFile()
}