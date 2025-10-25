import Foundation

/// Configuration for server endpoints and authentication.
public struct ServerConfig {
    /// IP address of the API server.
    public static let serverIP = "172.20.10.3"
    
    /// Port number for the API server.
    public static let serverPort = "8000"
    
    /// API key used for authentication.
    public static let apiKey = "placavision-api"
    
    /// Base URL for all API endpoints.
    public static let baseURL = "https://\(serverIP):\(serverPort)/api/"
}