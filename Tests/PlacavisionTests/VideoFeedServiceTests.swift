import XCTest
@testable import Placavision

final class VideoFeedServiceTests: XCTestCase {
    var videoFeedService: VideoFeedService!
    var mockRepo: MockRepository!
    var mockFileHelper: MockFileHelper!
    
    override func setUp() {
        super.setUp()
        mockRepo = MockRepository()
        mockFileHelper = MockFileHelper()
        videoFeedService = VideoFeedService(repository: mockRepo, fileHelper: mockFileHelper)
    }
    
    override func tearDown() {
        videoFeedService = nil
        mockRepo = nil
        mockFileHelper = nil
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
    
    func testFetchVideoFeed_success() {
        let exp = expectation(description: "video feed fetch succeeds")
        
        // Mock successful video feed response
        let mockFeedData: [String: Any] = [
            "url": "https://localhost:8080/stream",
            "status": "active"
        ]
        mockRepo.videoFeedResponse = .success(mockFeedData)
        
        videoFeedService.fetchVideoFeed { result in
            switch result {
            case .success(let url):
                XCTAssertEqual(url, "https://localhost:8080/stream")
                exp.fulfill()
            case .failure(let error):
                XCTFail("Expected success but got error: \(error)")
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testFetchVideoFeed_serverError() {
        let exp = expectation(description: "video feed fetch fails")
        
        let mockError = NSError(domain: "VideoFeed", code: 500, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        mockRepo.videoFeedResponse = .failure(mockError)
        
        videoFeedService.fetchVideoFeed { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                if let nsError = error as NSError?,
                   nsError.domain == "VideoFeed" && nsError.code == 500 {
                    exp.fulfill()
                } else {
                    XCTFail("Expected server error but got \(error)")
                }
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testFetchVideoFeed_invalidResponse() {
        let exp = expectation(description: "video feed fetch fails with invalid response")
        
        // Mock response without required URL field
        let mockFeedData: [String: Any] = [
            "status": "active"
        ]
        mockRepo.videoFeedResponse = .success(mockFeedData)
        
        videoFeedService.fetchVideoFeed { result in
            switch result {
            case .success:
                XCTFail("Expected failure with invalid response")
            case .failure(let error):
                if case VideoFeedService.FeedError.invalidResponse = error {
                    exp.fulfill()
                } else {
                    XCTFail("Expected invalidResponse error but got \(error)")
                }
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testConnectionStateTransitions() {
        // Test initial state
        XCTAssertEqual(videoFeedService.currentState, .disconnected)
        
        // Test connecting state
        videoFeedService.notifyStreamConnecting()
        XCTAssertEqual(videoFeedService.currentState, .connecting)
        
        // Test connected state
        videoFeedService.notifyStreamConnected()
        XCTAssertEqual(videoFeedService.currentState, .connected)
        
        // Test error state
        videoFeedService.notifyStreamError(NSError(domain: "Test", code: 0))
        XCTAssertEqual(videoFeedService.currentState, .error)
        
        // Test disconnected state
        videoFeedService.notifyStreamDisconnected()
        XCTAssertEqual(videoFeedService.currentState, .disconnected)
    }
    
    func testStateObservers() {
        let exp = expectation(description: "state change observed")
        exp.expectedFulfillmentCount = 2
        
        var stateChanges: [VideoFeedService.ConnectionState] = []
        
        // Add observer
        let token = videoFeedService.addStateObserver { state in
            stateChanges.append(state)
            exp.fulfill()
        }
        
        // Trigger state changes
        videoFeedService.notifyStreamConnecting()
        videoFeedService.notifyStreamConnected()
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(stateChanges, [.connecting, .connected])
        
        // Remove observer and verify no more updates
        videoFeedService.removeStateObserver(token)
        
        let noUpdateExp = expectation(description: "no more updates")
        noUpdateExp.isInverted = true
        
        videoFeedService.notifyStreamDisconnected()
        
        wait(for: [noUpdateExp], timeout: 0.5)
    }
}
