import Foundation

/// Configuration for API endpoints.
public struct APIConfig {
    /// Base URL for all API endpoints.
    public static let baseURL = ServerConfig.baseURL
    
    /// Authentication endpoint.
    public static let loginURL = "auth"
    
    /// User registration and management endpoint.
    public static let registerURL = "user"
    
    /// User profile endpoint.
    public static let userURL = "user"
    
    /// License plate reports endpoint.
    public static let platesURL = "reports"
    
    /// Video feed streaming endpoint.
    public static let videoFeedURL = "video_feed"
    
    /// System status endpoint.
    public static let statusURL = "status"
    
    /// GPS location endpoint.
    public static let gpsURL = "gps"
}