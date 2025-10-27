import XCTest
@testable import Placavision

final class VideoFeedServiceTests: XCTestCase {
    var videoFeedService: VideoFeedService!
    
    override func setUp() {
        super.setUp()
        videoFeedService = VideoFeedService()
    }
    
    override func tearDown() {
        videoFeedService = nil
        super.tearDown()
    }
    
    func testHandleSSLError_trustedHosts() {
        XCTAssertTrue(videoFeedService.handleSSLError(for: "https://172.20.10.3/video"))
        XCTAssertTrue(videoFeedService.handleSSLError(for: "http://localhost:8080/stream"))
        XCTAssertTrue(videoFeedService.handleSSLError(for: "https://127.0.0.1:8000"))
        XCTAssertFalse(videoFeedService.handleSSLError(for: "https://example.com/stream"))
    }

    func testInitialState_and_notifyConnected() {
        XCTAssertEqual(videoFeedService.currentState, VideoFeedService.ConnectionState.disconnected)
        videoFeedService.notifyStreamConnected()
        XCTAssertEqual(videoFeedService.currentState, VideoFeedService.ConnectionState.connected)
    }
}
