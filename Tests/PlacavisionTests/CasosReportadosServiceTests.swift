import XCTest
@testable import Placavision

final class CasosReportadosServiceTests: XCTestCase {
    var casosService: CasosReportadosService!
    var mockRepo: MockRepository!
    var mockFileHelper: MockFileHelper!
    
    override func setUp() {
        super.setUp()
        mockRepo = MockRepository()
        mockFileHelper = MockFileHelper()
        casosService = CasosReportadosService(repository: mockRepo, fileHelper: mockFileHelper)
        
        // Set up test data
        let testReports = [
            Report(
                placa: "ABC123",
                estado: "activo",
                fecha: "2023-12-01",
                ubicacion: "Test Location 1",
                descripcion: "Test Description 1"
            ),
            Report(
                placa: "XYZ789",
                estado: "inactivo",
                fecha: "2023-12-02",
                ubicacion: "Test Location 2",
                descripcion: "Test Description 2"
            )
        ]
        casosService.updateCachedReports(testReports)
    }
    
    override func tearDown() {
        casosService = nil
        mockRepo = nil
        mockFileHelper = nil
        super.tearDown()
    }
    
    func testFormatBold() {
        let formatted = casosService.formatBold(label: "Placa", value: "ABC123")
        XCTAssertEqual(formatted, "Placa: ABC123")
    }
    
    func testSearchReports_emptyQuery() {
        let results = casosService.searchReports(query: "")
        XCTAssertEqual(results.count, 2) // Should return all cached reports
    }
    
    func testSearchReports_withMatchingPlate() {
        let results = casosService.searchReports(query: "ABC")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.placa, "ABC123")
    }
    
    func testSearchReports_withMatchingLocation() {
        let results = casosService.searchReports(query: "Location 1")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.ubicacion, "Test Location 1")
    }
    
    func testSearchReports_noMatches() {
        let results = casosService.searchReports(query: "NONEXISTENT")
        XCTAssertTrue(results.isEmpty)
    }
    
    func testFilterByState_active() {
        let activeReports = casosService.filterByState("activo")
        XCTAssertEqual(activeReports.count, 1)
        XCTAssertEqual(activeReports.first?.estado, "activo")
    }
    
    func testFilterByState_inactive() {
        let inactiveReports = casosService.filterByState("inactivo")
        XCTAssertEqual(inactiveReports.count, 1)
        XCTAssertEqual(inactiveReports.first?.estado, "inactivo")
    }
    
    func testFilterByState_nonexistent() {
        let nonexistentReports = casosService.filterByState("nonexistent")
        XCTAssertTrue(nonexistentReports.isEmpty)
    }
    
    func testSortByDate() {
        let sortedReports = casosService.sortByDate()
        XCTAssertEqual(sortedReports.count, 2)
        XCTAssertEqual(sortedReports[0].fecha, "2023-12-02") // Most recent first
        XCTAssertEqual(sortedReports[1].fecha, "2023-12-01")
    }
    
    func testFetchReports_success() {
        let exp = expectation(description: "fetch reports succeeds")
        
        let mockReportsData = """
        [
            {
                "placa": "TEST123",
                "estado": "activo",
                "fecha": "2023-12-03",
                "ubicacion": "New Location",
                "descripcion": "New Report"
            }
        ]
        """.data(using: .utf8)!
        
        mockRepo.platesResponse = .success(mockReportsData)
        
        casosService.fetchReports { result in
            switch result {
            case .success(let reports):
                XCTAssertEqual(reports.count, 1)
                XCTAssertEqual(reports.first?.placa, "TEST123")
                
                // Verify cache was updated
                let cached = self.casosService.searchReports(query: "")
                XCTAssertEqual(cached.count, 1)
                XCTAssertEqual(cached.first?.placa, "TEST123")
                
                exp.fulfill()
            case .failure(let error):
                XCTFail("Expected success but got error: \(error)")
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testFetchReports_serverError() {
        let exp = expectation(description: "fetch reports fails")
        
        let mockError = NSError(domain: "Reports", code: 500, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        mockRepo.platesResponse = .failure(mockError)
        
        casosService.fetchReports { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                if let nsError = error as NSError?,
                   nsError.domain == "Reports" && nsError.code == 500 {
                    exp.fulfill()
                } else {
                    XCTFail("Expected server error but got \(error)")
                }
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testUpdateCachedReports() {
        let newReports = [
            Report(
                placa: "NEW123",
                estado: "activo",
                fecha: "2023-12-03",
                ubicacion: "New Location",
                descripcion: "New Description"
            )
        ]
        
        casosService.updateCachedReports(newReports)
        
        let cached = casosService.searchReports(query: "")
        XCTAssertEqual(cached.count, 1)
        XCTAssertEqual(cached.first?.placa, "NEW123")
    }
}
