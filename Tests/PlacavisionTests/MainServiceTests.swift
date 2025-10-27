import XCTest
@testable import Placavision

final class MainServiceTests: XCTestCase {
    var mainService: MainService!
    var mockRepo: MockRepository!
    var mockFileHelper: MockFileHelper!
    
    override func setUp() {
        super.setUp()
        mockRepo = MockRepository()
        mockFileHelper = MockFileHelper()
        mainService = MainService(repository: mockRepo, fileHelper: mockFileHelper)
    }
    
    override func tearDown() {
        mainService = nil
        mockRepo = nil
        mockFileHelper = nil
        super.tearDown()
    }
    
    func testCheckInitialState_defaultsToLogin() {
        // Test with no user and no token
        mockFileHelper.clearCurrentUser()
        mockFileHelper.clearUsersFile()
        
        XCTAssertEqual(mainService.checkInitialState(), MainService.MainTarget.login)
    }
    
    func testCheckInitialState_withValidUser() {
        // Set up a valid user
        let testUser = User(correo: "test@example.com", nombre_usuario: "testuser")
        mockFileHelper.saveUser(testUser)
        mockFileHelper.setCurrentUser(testUser.correo)
        mockFileHelper.saveAuthToken("validtoken")
        
        XCTAssertEqual(mainService.checkInitialState(), MainService.MainTarget.home)
    }
    
    func testCheckInitialState_withExpiredToken() {
        // Set up a user but with an expired token
        let testUser = User(correo: "test@example.com", nombre_usuario: "testuser")
        mockFileHelper.saveUser(testUser)
        mockFileHelper.setCurrentUser(testUser.correo)
        // Mock expired token behavior
        mockFileHelper.isTokenExpired = true
        
        XCTAssertEqual(mainService.checkInitialState(), MainService.MainTarget.login)
    }
    
    func testLogout_clearsCurrentUser() {
        // Set up initial state
        let testUser = User(correo: "test@example.com", nombre_usuario: "testuser")
        mockFileHelper.saveUser(testUser)
        mockFileHelper.setCurrentUser(testUser.correo)
        mockFileHelper.saveAuthToken("testtoken")
        
        let exp = expectation(description: "logout succeeds")
        
        mainService.logout { result in
            switch result {
            case .success(let message):
                XCTAssertTrue(message.contains("Sesión"))
                
                // Verify user and token are cleared
                XCTAssertNil(self.mockFileHelper.getCurrentUser())
                XCTAssertNil(self.mockFileHelper.getAuthToken())
                
                exp.fulfill()
            case .failure:
                XCTFail("Logout should succeed")
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testLogout_alreadyLoggedOut() {
        // Start with no user
        mockFileHelper.clearCurrentUser()
        mockFileHelper.clearUsersFile()
        
        let exp = expectation(description: "logout with no user")
        
        mainService.logout { result in
            switch result {
            case .success(let message):
                XCTAssertTrue(message.contains("Sesión"))
                exp.fulfill()
            case .failure:
                XCTFail("Logout should succeed even when no user is logged in")
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testGetCurrentUser() {
        // Set up a user
        let testUser = User(correo: "test@example.com", nombre_usuario: "testuser")
        mockFileHelper.saveUser(testUser)
        mockFileHelper.setCurrentUser(testUser.correo)
        
        let currentUser = mainService.getCurrentUser()
        XCTAssertNotNil(currentUser)
        XCTAssertEqual(currentUser?.correo, "test@example.com")
        XCTAssertEqual(currentUser?.nombre_usuario, "testuser")
    }
    
    func testGetCurrentUser_noUser() {
        mockFileHelper.clearCurrentUser()
        
        let currentUser = mainService.getCurrentUser()
        XCTAssertNil(currentUser)
    }
    
    func testIsTokenValid() {
        // Test with valid token
        mockFileHelper.saveAuthToken("validtoken")
        mockFileHelper.isTokenExpired = false
        XCTAssertTrue(mainService.isTokenValid())
        
        // Test with expired token
        mockFileHelper.isTokenExpired = true
        XCTAssertFalse(mainService.isTokenValid())
        
        // Test with no token
        mockFileHelper.saveAuthToken(nil)
        XCTAssertFalse(mainService.isTokenValid())
    }
    
    func testReloadUserData_success() {
        let exp = expectation(description: "reload user data succeeds")
        
        // Mock successful user response
        let userData: [String: Any] = [
            "correo": "updated@example.com",
            "nombre_usuario": "updateduser"
        ]
        mockRepo.userResponse = .success(userData)
        
        mainService.reloadUserData { result in
            switch result {
            case .success:
                // Verify user data was updated
                let currentUser = self.mockFileHelper.getCurrentUser()
                XCTAssertEqual(currentUser?.correo, "updated@example.com")
                XCTAssertEqual(currentUser?.nombre_usuario, "updateduser")
                exp.fulfill()
            case .failure(let error):
                XCTFail("Expected success but got error: \(error)")
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testReloadUserData_failure() {
        let exp = expectation(description: "reload user data fails")
        
        let mockError = NSError(domain: "User", code: 500, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        mockRepo.userResponse = .failure(mockError)
        
        mainService.reloadUserData { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                if let nsError = error as NSError?,
                   nsError.domain == "User" && nsError.code == 500 {
                    exp.fulfill()
                } else {
                    XCTFail("Expected server error but got \(error)")
                }
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
}
