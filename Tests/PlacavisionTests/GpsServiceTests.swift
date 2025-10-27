import XCTest
@testable import Placavision

final class GpsServiceTests: XCTestCase {
    var gpsService: GpsService!
    var mockRepo: MockRepository!
    
    override func setUp() {
        super.setUp()
        mockRepo = MockRepository()
        gpsService = GpsService(repository: mockRepo)
    }
    
    override func tearDown() {
        gpsService.cancelPolling()
        gpsService = nil
        mockRepo = nil
        super.tearDown()
    }

    func testStartPolling_emitsSearchingImmediately() {
        let exp = expectation(description: "searching called")
        // The first callback should be .searching synchronously
        gpsService.startPolling { status in
            if case GpsService.GpsStatus.searching = status {
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    func testLocationFound_withValidResponse() {
        let exp = expectation(description: "location found")
        
        // Set up mock response
        let mockResponse = GpsResponse(latitude: 40.7128, longitude: -74.0060)
        mockRepo.gpsResponse = .success(mockResponse)
        
        gpsService.startPolling { status in
            if case .found(let lat, let lon) = status {
                XCTAssertEqual(lat, 40.7128, accuracy: 0.0001)
                XCTAssertEqual(lon, -74.0060, accuracy: 0.0001)
                exp.fulfill()
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testLocationError_onRepositoryFailure() {
        let exp = expectation(description: "error received")
        
        // Set up mock error
        let mockError = NSError(domain: "GPS", code: 404, userInfo: [NSLocalizedDescriptionKey: "Location not found"])
        mockRepo.gpsResponse = .failure(mockError)
        
        gpsService.startPolling { status in
            if case .error = status {
                exp.fulfill()
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testCancelPolling_stopsUpdates() {
        let searchingExp = expectation(description: "searching starts")
        let timeoutExp = expectation(description: "no more updates after cancel")
        timeoutExp.isInverted = true
        
        var callCount = 0
        gpsService.startPolling { status in
            if case .searching = status {
                callCount += 1
                if callCount == 1 {
                    searchingExp.fulfill()
                    self.gpsService.cancelPolling()
                } else {
                    // Should not get here after cancelling
                    XCTFail("Received update after cancelling")
                }
            }
        }
        
        wait(for: [searchingExp, timeoutExp], timeout: 2.0)
    }
}
