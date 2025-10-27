import Foundation

public struct GpsResponse: Codable {
    public let status: String
    public let timestamp: String
    public let data: GpsData?

    // Convenience initializer used by tests
    public init(latitude: Double, longitude: Double) {
        self.status = "ok"
        self.timestamp = ISO8601DateFormatter().string(from: Date())
        self.data = GpsData(fix_status: nil, latitude: latitude, longitude: longitude, altitude: nil, accuracy: 0.0, raw: nil)
    }
}

public struct GpsData: Codable {
    public let fix_status: String?
    public let latitude: Double?
    public let longitude: Double?
    public let altitude: Double?
    public let accuracy: Double?
    public let raw: String?
}
