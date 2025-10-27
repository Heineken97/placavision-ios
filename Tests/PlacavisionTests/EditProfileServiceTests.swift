import XCTest
@testable import Placavision

final class EditProfileServiceTests: XCTestCase {
    func testValidateInputs_basic() {
        let svc = EditProfileService()
        let valid = svc.validateInputs(email: "a@b.com", username: "user", phone: "12345678", nationalId: "12345", newPassword: nil)
        switch valid {
        case .success:
            break
        case .failure(let err):
            XCTFail("Validation should succeed, got \(err)")
        }

        let invalidEmail = svc.validateInputs(email: "bad", username: "user", phone: "12345678", nationalId: "12345", newPassword: nil)
        switch invalidEmail {
        case .success:
            XCTFail("Invalid email should fail")
        case .failure:
            break
        }
    }

    func testGetCurrentUser_returnsNilWhenNoUser() {
        let fh = FileHelper()
        fh.clearUsersFile()
        fh.clearCurrentUser()
        let svc = EditProfileService()
        let user = svc.getCurrentUser()
        XCTAssertNil(user)
    }
}
