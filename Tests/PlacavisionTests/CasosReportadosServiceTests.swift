import XCTest
@testable import Placavision

final class CasosReportadosServiceTests: XCTestCase {
    func testFormatBold_and_searchEmpty() {
        let svc = CasosReportadosService()
        let formatted = svc.formatBold(label: "Placa", value: "ABC123")
        XCTAssertEqual(formatted, "Placa: ABC123")
        // Empty search returns cachedReports which is initially empty
        let results = svc.searchReports(query: "")
        XCTAssertTrue(results.isEmpty)
    }

    func testFilterAndSort_onEmpty() {
        let svc = CasosReportadosService()
        XCTAssertTrue(svc.filterByState("activo").isEmpty)
        XCTAssertTrue(svc.sortByDate().isEmpty)
    }
}
