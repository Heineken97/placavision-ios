import XCTest
@testable import Placavision

final class VideoFeedServiceTests: XCTestCase {
    func testHandleSSLError_trustedHosts() {
        let service = VideoFeedService()
        XCTAssertTrue(service.handleSSLError(for: "https://172.20.10.3/video"))
        XCTAssertTrue(service.handleSSLError(for: "http://localhost:8080/stream"))
        XCTAssertTrue(service.handleSSLError(for: "https://127.0.0.1:8000"))
        XCTAssertFalse(service.handleSSLError(for: "https://example.com/stream"))
    }

    func testInitialState_and_notifyConnected() {
        let service = VideoFeedService()
        XCTAssertEqual(service.currentState, VideoFeedService.ConnectionState.disconnected)
        service.notifyStreamConnected()
        XCTAssertEqual(service.currentState, VideoFeedService.ConnectionState.connected)
    }
}
