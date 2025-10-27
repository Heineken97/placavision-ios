import XCTest
@testable import Placavision

final class ReporteDePlacaServiceTests: XCTestCase {
    var reportService: ReporteDePlacaService!
    var mockRepo: MockRepository!
    var mockFileHelper: MockFileHelper!
    
    override func setUp() {
        super.setUp()
        mockRepo = MockRepository()
        mockFileHelper = MockFileHelper()
        reportService = ReporteDePlacaService(repository: mockRepo, fileHelper: mockFileHelper)
    }
    
    override func tearDown() {
        reportService = nil
        mockRepo = nil
        mockFileHelper = nil
        super.tearDown()
    }
    
    func testProcessReport_success() {
        let exp = expectation(description: "report process succeeds")
        
        let successResponse = "Report submitted".data(using: .utf8)!
        mockRepo.submitReportResponse = .success(successResponse)
        
        reportService.processReport(
            plate: "ABC123",
            model: "Sedan",
            brand: "Toyota",
            year: "2020",
            type: "robbery",
            description: "Vehicle was seen at Main Street",
            phone: "12345678"
        ) { result in
            switch result {
            case .success:
                exp.fulfill()
            case .failure(let error):
                XCTFail("Expected success but got error: \(error)")
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testProcessReport_invalidPlate() {
        let exp = expectation(description: "report fails with invalid plate")
        
        reportService.processReport(
            plate: "123",  // Too short
            model: "Sedan",
            brand: "Toyota",
            year: "2020",
            type: "robbery",
            description: "Vehicle description",
            phone: "12345678"
        ) { result in
            switch result {
            case .success:
                XCTFail("Process should fail for invalid plate")
            case .failure(let error):
                if let validationError = error as? ReporteDePlacaService.ValidationError,
                   case .invalidPlate = validationError {
                    exp.fulfill()
                } else {
                    XCTFail("Expected invalidPlate error but got \(error)")
                }
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testProcessReport_invalidDescription() {
        let exp = expectation(description: "report fails with invalid description")
        
        reportService.processReport(
            plate: "ABC123",
            model: "Sedan",
            brand: "Toyota",
            year: "2020",
            type: "robbery",
            description: "Too short",  // Description too short
            phone: "12345678"
        ) { result in
            switch result {
            case .success:
                XCTFail("Process should fail for short description")
            case .failure(let error):
                if let validationError = error as? ReporteDePlacaService.ValidationError,
                   case .invalidDescription = validationError {
                    exp.fulfill()
                } else {
                    XCTFail("Expected invalidDescription error but got \(error)")
                }
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testProcessReport_invalidPhone() {
        let exp = expectation(description: "report fails with invalid phone")
        
        reportService.processReport(
            plate: "ABC123",
            model: "Sedan",
            brand: "Toyota",
            year: "2020",
            type: "robbery",
            description: "Valid description of the vehicle",
            phone: "123"  // Too short
        ) { result in
            switch result {
            case .success:
                XCTFail("Process should fail for invalid phone")
            case .failure(let error):
                if let validationError = error as? ReporteDePlacaService.ValidationError,
                   case .invalidPhone = validationError {
                    exp.fulfill()
                } else {
                    XCTFail("Expected invalidPhone error but got \(error)")
                }
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testProcessReport_serverError() {
        let exp = expectation(description: "report fails with server error")
        
        let mockError = NSError(domain: "Report", code: 500, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        mockRepo.submitReportResponse = .failure(mockError)
        
        reportService.processReport(
            plate: "ABC123",
            model: "Sedan",
            brand: "Toyota",
            year: "2020",
            type: "robbery",
            description: "Valid description of the vehicle",
            phone: "12345678"
        ) { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                if let nsError = error as NSError?,
                   nsError.domain == "Report" && nsError.code == 500 {
                    exp.fulfill()
                } else {
                    XCTFail("Expected server error but got \(error)")
                }
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testValidateInput_allValid() {
        // Test with valid inputs
        let result = reportService.validateInputs(
            plate: "ABC123",
            model: "Sedan",
            brand: "Toyota",
            year: "2020",
            type: "robbery",
            description: "Valid description of the vehicle",
            phone: "12345678"
        )
        
        if case .failure(let error) = result {
            XCTFail("Expected validation to succeed but got error: \(error)")
        }
    }
    
    func testValidateInputs_allRequired() {
        // Test empty plate
        XCTAssertThrowsError(try reportService.validateInputs(
            plate: "",
            model: "Sedan",
            brand: "Toyota",
            year: "2020",
            type: "robbery",
            description: "Description",
            phone: "12345678"
        ).get()) { error in
            XCTAssertTrue(error is ReporteDePlacaService.ValidationError)
        }
        
        // Test empty model
        XCTAssertThrowsError(try reportService.validateInputs(
            plate: "ABC123",
            model: "",
            brand: "Toyota",
            year: "2020",
            type: "robbery",
            description: "Description",
            phone: "12345678"
        ).get()) { error in
            XCTAssertTrue(error is ReporteDePlacaService.ValidationError)
        }
        
        // Test empty brand
        XCTAssertThrowsError(try reportService.validateInputs(
            plate: "ABC123",
            model: "Sedan",
            brand: "",
            year: "2020",
            type: "robbery",
            description: "Description",
            phone: "12345678"
        ).get()) { error in
            XCTAssertTrue(error is ReporteDePlacaService.ValidationError)
        }
    }
}
