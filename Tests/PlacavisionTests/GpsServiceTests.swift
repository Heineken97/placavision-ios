import XCTest
@testable import Placavision

final class GpsServiceTests: XCTestCase {
    func testStartPolling_emitsSearchingImmediately() {
        let svc = GpsService()
        let exp = expectation(description: "searching called")
        // The first callback should be .searching synchronously
        svc.startPolling { status in
            if case GpsService.GpsStatus.searching = status {
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 1.0)
        svc.cancelPolling()
    }
}
