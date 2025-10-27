import Foundation

public enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case unauthorized
    case serverError(String)
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida"
        case .networkError(let error):
            return "Error de red: \(error.localizedDescription)"
        case .invalidResponse:
            return "Respuesta del servidor inválida"
        case .decodingError(let error):
            return "Error al procesar la respuesta: \(error.localizedDescription)"
        case .unauthorized:
            return "No autorizado"
        case .serverError(let message):
            return "Error del servidor: \(message)"
        case .unknown:
            return "Error desconocido"
        }
    }
}