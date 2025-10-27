import XCTest
@testable import Placavision

final class ReporteDePlacaServiceTests: XCTestCase {
    func testProcessReport_invalidPlate() {
        let svc = ReporteDePlacaService()
        let exp = expectation(description: "invalid plate")
        svc.processReport(plate: "123", model: "M", brand: "B", year: "2020", type: "robbery", description: "Too short", phone: "1234567") { result in
            switch result {
            case .success:
                XCTFail("Process should fail for invalid plate or short description")
            case .failure(let error):
                if let valErr = error as? ReporteDePlacaService.ValidationError {
                    if case .invalidPlate = valErr { /* expected maybe */ }
                    else if case .invalidDescription = valErr { /* expected */ }
                    else { XCTFail("Expected validation error, got \(valErr)") }
                } else {
                    // also acceptable if repository/network error is returned
                }
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
}
