import XCTest
@testable import Placavision

final class RecoveryServiceTests: XCTestCase {
    func testValidateEmail_emptyFails() {
        let svc = RecoveryService()
        switch svc.validateEmail("") {
        case .success:
            XCTFail("Empty email should fail")
        case .failure(let err):
            if case RecoveryService.ValidationError.emptyEmail = err { }
            else { XCTFail("Expected emptyEmail, got \(err)") }
        }
    }

    func testValidateEmail_invalidFormatFails() {
        let svc = RecoveryService()
        switch svc.validateEmail("invalid-email") {
        case .success:
            XCTFail("Invalid email should fail")
        case .failure(let err):
            if case RecoveryService.ValidationError.invalidEmail = err { }
            else { XCTFail("Expected invalidEmail, got \(err)") }
        }
    }

    func testValidateEmail_validSucceeds() {
        let svc = RecoveryService()
        switch svc.validateEmail("user@example.com") {
        case .success:
            // expected
            break
        case .failure(let err):
            XCTFail("Expected success but got \(err)")
        }
    }
}
