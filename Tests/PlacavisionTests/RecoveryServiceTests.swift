import XCTest
@testable import Placavision

final class RecoveryServiceTests: XCTestCase {
    var recoveryService: RecoveryService!
    var mockRepo: MockRepository!
    
    override func setUp() {
        super.setUp()
        mockRepo = MockRepository()
        recoveryService = RecoveryService(repository: mockRepo)
    }
    
    override func tearDown() {
        recoveryService = nil
        mockRepo = nil
        super.tearDown()
    }
    
    func testValidateEmail_emptyFails() {
        switch recoveryService.validateEmail("") {
        case .success:
            XCTFail("Empty email should fail")
        case .failure(let err):
            if case RecoveryService.ValidationError.emptyEmail = err { }
            else { XCTFail("Expected emptyEmail, got \(err)") }
        }
    }

    func testValidateEmail_invalidFormatFails() {
        switch recoveryService.validateEmail("invalid-email") {
        case .success:
            XCTFail("Invalid email should fail")
        case .failure(let err):
            if case RecoveryService.ValidationError.invalidEmail = err { }
            else { XCTFail("Expected invalidEmail, got \(err)") }
        }
    }

    func testValidateEmail_validSucceeds() {
        switch recoveryService.validateEmail("user@example.com") {
        case .success:
            // expected
            break
        case .failure(let err):
            XCTFail("Expected success but got \(err)")
        }
    }
    
    func testRequestRecovery_withValidEmail() {
        let exp = expectation(description: "recovery request completes")
    let successResponse: [String: Any] = ["temp_password": "temporary123"]
    mockRepo.recoveryResponse = .success(successResponse)

    recoveryService.recoverPassword(email: "user@example.com") { result in
            switch result {
            case .success:
                exp.fulfill()
            case .failure(let error):
                XCTFail("Expected success but got error: \(error)")
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testRequestRecovery_withInvalidEmail() {
        let exp = expectation(description: "recovery request fails validation")
        
    recoveryService.recoverPassword(email: "invalid-email") { result in
            switch result {
            case .success:
                XCTFail("Expected validation failure")
            case .failure(let error):
                if let validationError = error as? RecoveryService.ValidationError,
                   case .invalidEmail = validationError {
                    exp.fulfill()
                } else {
                    XCTFail("Expected invalidEmail error but got \(error)")
                }
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testRequestRecovery_whenServerFails() {
        let exp = expectation(description: "recovery request fails")
        let mockError = NSError(domain: "Recovery", code: 500, userInfo: [NSLocalizedDescriptionKey: "Server error"])
    mockRepo.recoveryResponse = .failure(mockError)

    recoveryService.recoverPassword(email: "user@example.com") { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                if let nsError = error as NSError?,
                   nsError.domain == "Recovery" && nsError.code == 500 {
                    exp.fulfill()
                } else {
                    XCTFail("Expected server error but got \(error)")
                }
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
}
