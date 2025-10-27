import XCTest
@testable import Placavision

final class RegisterServiceTests: XCTestCase {
    func testRegister_invalidEmailFails() {
        let svc = RegisterService()
        let invalidUser = User(correo: "invalid-email", contrasena: "StrongPass1!", nombre_usuario: "u", identificador_nacional: nil, telefono: nil, role: nil)
        let exp = expectation(description: "register")
        svc.register(user: invalidUser) { result in
            switch result {
            case .success:
                XCTFail("Registration should fail for invalid email")
            case .failure(let error):
                if let regErr = error as? RegisterService.RegisterError {
                    if case .invalidEmail = regErr {
                        // expected
                    } else {
                        XCTFail("Expected invalidEmail, got \(regErr)")
                    }
                } else {
                    XCTFail("Expected RegisterError, got \(error)")
                }
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    func testPasswordStrength_helper() {
        let svc = RegisterService()
        // Use reflection to call private method getPasswordStrength is not ideal; instead verify public behavior via weak password
        let weakUser = User(correo: "u@example.com", contrasena: "123", nombre_usuario: "u", identificador_nacional: nil, telefono: nil, role: nil)
        let exp = expectation(description: "weak")
        svc.register(user: weakUser) { result in
            switch result {
            case .success:
                XCTFail("Registration should fail for weak password")
            case .failure:
                // any failure is acceptable here
                break
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
}
