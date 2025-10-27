import XCTest
@testable import Placavision

final class RegisterServiceTests: XCTestCase {
    var registerService: RegisterService!
    var mockRepo: MockRepository!
    var mockFileHelper: MockFileHelper!
    
    override func setUp() {
        super.setUp()
        mockRepo = MockRepository()
        mockFileHelper = MockFileHelper()
        registerService = RegisterService(repository: mockRepo, fileHelper: mockFileHelper)
    }
    
    override func tearDown() {
        registerService = nil
        mockRepo = nil
        mockFileHelper = nil
        super.tearDown()
    }
    
    func testRegister_success() {
        let exp = expectation(description: "registration succeeds")
        
        let successResponse = "Registration successful".data(using: .utf8)!
        mockRepo.registerResponse = .success(successResponse)
        
        let validUser = User(
            correo: "test@example.com",
            contrasena: "StrongPass1!",
            nombre_usuario: "testuser",
            identificador_nacional: "12345",
            telefono: "12345678",
            role: "user"
        )
        
        registerService.register(user: validUser) { result in
            switch result {
            case .success:
                // Verify user was saved locally
                let savedUser = self.mockFileHelper.findUserByEmail("test@example.com")
                XCTAssertNotNil(savedUser)
                XCTAssertEqual(savedUser?.correo, validUser.correo)
                XCTAssertEqual(savedUser?.nombre_usuario, validUser.nombre_usuario)
                exp.fulfill()
            case .failure(let error):
                XCTFail("Registration should succeed, got error: \(error)")
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testRegister_invalidEmailFails() {
        let exp = expectation(description: "registration fails with invalid email")
        
        let invalidUser = User(
            correo: "invalid-email",
            contrasena: "StrongPass1!",
            nombre_usuario: "user",
            identificador_nacional: nil,
            telefono: nil,
            role: nil
        )
        
        registerService.register(user: invalidUser) { result in
            switch result {
            case .success:
                XCTFail("Registration should fail for invalid email")
            case .failure(let error):
                if let regErr = error as? RegisterService.RegisterError,
                   case .invalidEmail = regErr {
                    exp.fulfill()
                } else {
                    XCTFail("Expected invalidEmail error, got \(error)")
                }
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testRegister_weakPasswordFails() {
        let exp = expectation(description: "registration fails with weak password")
        
        let userWithWeakPassword = User(
            correo: "test@example.com",
            contrasena: "123",  // Too weak
            nombre_usuario: "user",
            identificador_nacional: nil,
            telefono: nil,
            role: nil
        )
        
        registerService.register(user: userWithWeakPassword) { result in
            switch result {
            case .success:
                XCTFail("Registration should fail for weak password")
            case .failure(let error):
                if let regErr = error as? RegisterService.RegisterError,
                   case .weakPassword = regErr {
                    exp.fulfill()
                } else {
                    XCTFail("Expected weakPassword error, got \(error)")
                }
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testRegister_invalidUsernameFails() {
        let exp = expectation(description: "registration fails with invalid username")
        
        let userWithInvalidUsername = User(
            correo: "test@example.com",
            contrasena: "StrongPass1!",
            nombre_usuario: "",  // Empty username
            identificador_nacional: nil,
            telefono: nil,
            role: nil
        )
        
        registerService.register(user: userWithInvalidUsername) { result in
            switch result {
            case .success:
                XCTFail("Registration should fail for invalid username")
            case .failure(let error):
                if let regErr = error as? RegisterService.RegisterError,
                   case .invalidUsername = regErr {
                    exp.fulfill()
                } else {
                    XCTFail("Expected invalidUsername error, got \(error)")
                }
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testRegister_serverError() {
        let exp = expectation(description: "registration fails with server error")
        
        let mockError = NSError(domain: "Register", code: 500, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        mockRepo.registerResponse = .failure(mockError)
        
        let validUser = User(
            correo: "test@example.com",
            contrasena: "StrongPass1!",
            nombre_usuario: "testuser",
            identificador_nacional: "12345",
            telefono: "12345678",
            role: "user"
        )
        
        registerService.register(user: validUser) { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                if let nsError = error as NSError?,
                   nsError.domain == "Register" && nsError.code == 500 {
                    exp.fulfill()
                } else {
                    XCTFail("Expected server error but got \(error)")
                }
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testPasswordStrengthValidation() {
        // Test various password strengths
        let weakPasswords = ["123", "password", "abcdef"]
        let strongPasswords = ["StrongPass1!", "Complex123#", "P@ssw0rd123"]
        
        for password in weakPasswords {
            let user = User(
                correo: "test@example.com",
                contrasena: password,
                nombre_usuario: "testuser"
            )
            
            let exp = expectation(description: "weak password check")
            registerService.register(user: user) { result in
                if case .success = result {
                    XCTFail("Expected weak password '\(password)' to fail")
                }
                exp.fulfill()
            }
            wait(for: [exp], timeout: 1.0)
        }
        
        for password in strongPasswords {
            let user = User(
                correo: "test@example.com",
                contrasena: password,
                nombre_usuario: "testuser"
            )
            
            // Set up success response for strong passwords
            mockRepo.registerResponse = .success("Success".data(using: .utf8)!)
            
            let exp = expectation(description: "strong password check")
            registerService.register(user: user) { result in
                if case .failure(let error) = result,
                   let regErr = error as? RegisterService.RegisterError,
                   case .weakPassword = regErr {
                    XCTFail("Expected strong password '\(password)' to pass strength check")
                }
                exp.fulfill()
            }
            wait(for: [exp], timeout: 1.0)
        }
    }
}
