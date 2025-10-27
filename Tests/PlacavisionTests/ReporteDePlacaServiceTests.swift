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
    
    func testProcessReport_invalidPlate() {
        let exp = expectation(description: "invalid plate")
        
        reportService.processReport(
            plate: "123",  // Too short
            model: "M",
            brand: "B",
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
                    // Expected error
                } else {
                    XCTFail("Expected invalidPlate error but got \(error)")
                }
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testProcessReport_invalidDescription() {
        let exp = expectation(description: "invalid description")
        
        reportService.processReport(
            plate: "ABC123",
            model: "M",
            brand: "B",
            year: "2020",
            type: "robbery",
            description: "Too short",  // Too short
            phone: "12345678"
        ) { result in
            switch result {
            case .success:
                XCTFail("Process should fail for short description")
            case .failure(let error):
                if let validationError = error as? ReporteDePlacaService.ValidationError,
                   case .invalidDescription = validationError {
                    // Expected error
                } else {
                    XCTFail("Expected invalidDescription error but got \(error)")
                }
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
}
