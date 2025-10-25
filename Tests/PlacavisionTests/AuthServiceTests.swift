import XCTest
@testable import Placavision

final class AuthServiceTests: XCTestCase {
    func testBackupCredentials() {
        XCTAssertTrue(AuthService.isValidBackupCredentials(email: "admin@placavision.com", password: "admin123"))
    }
}
