import XCTest
@testable import Placavision

final class AuthServiceTests: XCTestCase {
    var authService: AuthService!
    var mockRepo: MockRepository!
    var mockFileHelper: MockFileHelper!

    override func setUp() {
        super.setUp()
        mockRepo = MockRepository()
        mockFileHelper = MockFileHelper()
        authService = AuthService(repository: mockRepo, fileHelper: mockFileHelper)
    }

    override func tearDown() {
        mockRepo = nil
        mockFileHelper = nil
        authService = nil
        super.tearDown()
    }

    func testLoginSuccess_withBackupCredentials() {
        let expectation = XCTestExpectation(description: "Login succeeds with backup credentials")

        // Use backup admin credentials defined in FileHelper
        let adminEmail = FileHelper.backupAdminEmail
        let adminPassword = FileHelper.backupAdminPassword

        authService.login(email: adminEmail, password: adminPassword) { result in
            switch result {
            case .success(let response):
                // AuthService returns an AuthResponse struct
                XCTAssertEqual(response.token, "backup_token")
                XCTAssertEqual(response.user.correo, adminEmail)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Login should succeed with backup credentials, got error: \(error)")
            }
        }

        wait(for: [expectation], timeout: 5.0)
    }

    func testLoginFailure_invalidCredentials() {
        let expectation = XCTestExpectation(description: "Login fails with invalid credentials")

        // Use an invalid email format to trigger validation failure
        authService.login(email: "invalid-email", password: "123") { result in
            switch result {
            case .success:
                XCTFail("Login should fail with invalid credentials")
            case .failure(let error):
                // Expect AuthError.invalidCredentials
                if let authError = error as? AuthService.AuthError {
                    if case .invalidCredentials = authError {
                        // expected
                    } else {
                        XCTFail("Expected AuthService.AuthError.invalidCredentials, got \(authError)")
                    }
                } else {
                    XCTFail("Expected AuthService.AuthError.invalidCredentials, got \(error)")
                }
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5.0)
    }

    func testTokenSavedAfterLogin() {
        let expectation = XCTestExpectation(description: "Token is saved after login")

        let adminEmail = FileHelper.backupAdminEmail
        let adminPassword = FileHelper.backupAdminPassword

        authService.login(email: adminEmail, password: adminPassword) { result in
            switch result {
            case .success(let response):
                let fileHelper = FileHelper()
                XCTAssertEqual(fileHelper.getAuthToken(), response.token)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Login failed: \(error)")
            }
        }

        wait(for: [expectation], timeout: 5.0)
    }
}
