public struct GpsResponse: Codable {
    public let status: String
    public let timestamp: String
    public let data: GpsData?
}

public struct GpsData: Codable {
    public let fix_status: String?
    public let latitude: Double?
    public let longitude: Double?
    public let altitude: Double?
    public let raw: String?
}
