import Foundation

public struct PlatesResponse: Codable {
    public let plates: [Report]
    
    private enum CodingKeys: String, CodingKey {
        case plates = "data"
    }
    
    public init(plates: [Report]) {
        self.plates = plates
    }
}