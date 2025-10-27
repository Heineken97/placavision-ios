import XCTest
@testable import Placavision

final class EditProfileServiceTests: XCTestCase {
    var editProfileService: EditProfileService!
    var mockRepo: MockRepository!
    var mockFileHelper: MockFileHelper!
    
    override func setUp() {
        super.setUp()
        mockRepo = MockRepository()
        mockFileHelper = MockFileHelper()
        editProfileService = EditProfileService(repository: mockRepo, fileHelper: mockFileHelper)
    }
    
    override func tearDown() {
        editProfileService = nil
        mockRepo = nil
        mockFileHelper = nil
        super.tearDown()
    }
    
    func testValidateInputs_withValidData() {
        let result = editProfileService.validateInputs(
            email: "user@example.com",
            username: "validuser",
            phone: "12345678",
            nationalId: "12345",
            newPassword: nil
        )
        
        switch result {
        case .success:
            break // Expected
        case .failure(let err):
            XCTFail("Validation should succeed, got \(err)")
        }
    }
    
    func testValidateInputs_withInvalidEmail() {
        let result = editProfileService.validateInputs(
            email: "bad-email",
            username: "validuser",
            phone: "12345678",
            nationalId: "12345",
            newPassword: nil
        )
        
        switch result {
        case .success:
            XCTFail("Invalid email should fail")
        case .failure(let error):
            guard case EditProfileService.ValidationError.invalidEmail = error else {
                XCTFail("Expected invalidEmail error but got \(error)")
                return
            }
        }
    }
    
    func testValidateInputs_withInvalidUsername() {
        let result = editProfileService.validateInputs(
            email: "user@example.com",
            username: "",  // Empty username
            phone: "12345678",
            nationalId: "12345",
            newPassword: nil
        )
        
        switch result {
        case .success:
            XCTFail("Empty username should fail")
        case .failure(let error):
            guard case EditProfileService.ValidationError.invalidUsername = error else {
                XCTFail("Expected invalidUsername error but got \(error)")
                return
            }
        }
    }
    
    func testValidateInputs_withInvalidPhone() {
        let result = editProfileService.validateInputs(
            email: "user@example.com",
            username: "validuser",
            phone: "123",  // Too short
            nationalId: "12345",
            newPassword: nil
        )
        
        switch result {
        case .success:
            XCTFail("Invalid phone number should fail")
        case .failure(let error):
            guard case EditProfileService.ValidationError.invalidPhone = error else {
                XCTFail("Expected invalidPhone error but got \(error)")
                return
            }
        }
    }
    
    func testGetCurrentUser_whenUserExists() {
        let testUser = User(correo: "test@example.com", nombre_usuario: "testuser")
        mockFileHelper.saveUser(testUser)
        mockFileHelper.setCurrentUser("test@example.com")
        
        let user = editProfileService.getCurrentUser()
        XCTAssertNotNil(user)
        XCTAssertEqual(user?.correo, "test@example.com")
        XCTAssertEqual(user?.nombre_usuario, "testuser")
    }
    
    func testGetCurrentUser_whenNoUserExists() {
        mockFileHelper.clearCurrentUser()
        
        let user = editProfileService.getCurrentUser()
        XCTAssertNil(user)
    }
    
    func testUpdateProfile_success() {
        let exp = expectation(description: "profile update succeeds")
        let successResponse = "Profile updated".data(using: .utf8)!
        mockRepo.updateUserResponse = .success(successResponse)
        
        let updatedUser = User(
            correo: "updated@example.com",
            nombre_usuario: "updateduser",
            telefono: "87654321",
            cedula: "54321"
        )
        
        editProfileService.updateProfile(
            email: updatedUser.correo,
            username: updatedUser.nombre_usuario ?? "",
            phone: updatedUser.telefono ?? "",
            nationalId: updatedUser.cedula ?? "",
            newPassword: nil
        ) { result in
            switch result {
            case .success:
                // Verify user was saved locally
                let savedUser = self.mockFileHelper.getCurrentUser()
                XCTAssertEqual(savedUser?.correo, updatedUser.correo)
                XCTAssertEqual(savedUser?.nombre_usuario, updatedUser.nombre_usuario)
                exp.fulfill()
            case .failure(let error):
                XCTFail("Update should succeed, got error: \(error)")
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testUpdateProfile_whenServerFails() {
        let exp = expectation(description: "profile update fails")
        let mockError = NSError(domain: "Profile", code: 500, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        mockRepo.updateUserResponse = .failure(mockError)
        
        editProfileService.updateProfile(
            email: "test@example.com",
            username: "testuser",
            phone: "12345678",
            nationalId: "12345",
            newPassword: nil
        ) { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                if let nsError = error as NSError?,
                   nsError.domain == "Profile" && nsError.code == 500 {
                    exp.fulfill()
                } else {
                    XCTFail("Expected server error but got \(error)")
                }
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
}
