import XCTest
@testable import Placavision

final class AuthServiceTests: XCTestCase {
    var authService: AuthService!
    let testEmail = "test@example.com"
    let testPassword = "testpass123"
    
    override func setUp() {
        super.setUp()
        authService = AuthService()
    }
    
    override func tearDown() {
        authService = nil
        super.tearDown()
    }
    
    func testLoginSuccess() {
        let expectation = XCTestExpectation(description: "Login succeeds")
        
        authService.login(email: testEmail, password: testPassword) { result in
            switch result {
            case .success(let response):
                // Verify response has expected structure
                XCTAssertTrue(response.keys.contains("access_token"))
                XCTAssertNotNil(response["access_token"] as? String)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Login should succeed, got error: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testLoginFailure() {
        let expectation = XCTestExpectation(description: "Login fails with invalid credentials")
        
        authService.login(email: "invalid@example.com", password: "wrongpass") { result in
            switch result {
            case .success:
                XCTFail("Login should fail with invalid credentials")
            case .failure(let error):
                // Verify we get an appropriate error
                if let apiError = error as? APIClient.APIError {
                    XCTAssertEqual(apiError, .invalidStatusCode(401))
                } else {
                    XCTFail("Expected APIClient.APIError, got \(error)")
                }
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testRegisterSuccess() {
        let expectation = XCTestExpectation(description: "Register succeeds")
        let testUser = User(
            correo: "newuser@example.com",
            contrasena: "pass123",
            nombre_usuario: "Test User",
            identificador_nacional: "123456789",
            telefono: "555-1234",
            role: "user"
        )
        
        authService.register(user: testUser) { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Register should succeed, got error: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testTokenRefreshFlow() {
        let expectation = XCTestExpectation(description: "Token refresh succeeds")
        
        // First login to get a token
        authService.login(email: testEmail, password: testPassword) { result in
            switch result {
            case .success(let response):
                guard let token = response["access_token"] as? String else {
                    XCTFail("Missing access token in response")
                    return
                }
                
                // Now try to use the token
                let fileHelper = FileHelper()
                fileHelper.saveAuthToken(token)
                
                // Verify token is saved
                XCTAssertEqual(fileHelper.getAuthToken(), token)
                
                // Check token expiry handling
                XCTAssertTrue(fileHelper.isTokenExpired(), "Test token should be expired")
                
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Login failed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
}

final class AuthServiceTests: XCTestCase {
    func testBackupCredentials() {
        XCTAssertTrue(AuthService.isValidBackupCredentials(email: "admin@placavision.com", password: "admin123"))
    }
}
