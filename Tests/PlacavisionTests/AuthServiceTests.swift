import XCTest
@testable import Placavision

final class AuthServiceTests: XCTestCase {
    func testLoginSuccess() {
        let expectation = self.expectation(description: "Login")
        AuthService.login(email: "test@example.com", password: "1234") { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
}
