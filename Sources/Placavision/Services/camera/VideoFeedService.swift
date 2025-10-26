import Foundation

public final class VideoFeedService {
    private let repository = Repository()
    private var connectionState: ConnectionState = .disconnected
    private let queue = DispatchQueue(label: "com.placavision.videofeed", qos: .userInitiated)
    private var retryCount = 0
    private let maxRetries = 3
    private var lastError: VideoError?

    public init() {}

    /// Obtiene la URL del stream de video desde el backend.
    public func loadStreamURL(completion: @escaping (Result<StreamResponse, Error>) -> Void) {
        connectionState = .connecting
        retryCount = 0
        attemptConnection(completion)
    }

    private func attemptConnection(_ completion: @escaping (Result<StreamResponse, Error>) -> Void) {
        guard retryCount < maxRetries else {
            connectionState = .failed(lastError ?? .maxRetriesExceeded)
            completion(.failure(lastError ?? .maxRetriesExceeded))
            return
        }

        repository.getVideoFeed { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let json):
                if let urlString = json["video_url"] as? String,
                   let url = URL(string: urlString) {
                    self.validateStream(url) { streamResult in
                        switch streamResult {
                        case .success:
                            self.connectionState = .connected
                            let response = StreamResponse(
                                url: url,
                                state: self.connectionState,
                                quality: .auto
                            )
                            completion(.success(response))
                        case .failure(let error):
                            self.handleStreamError(error, completion)
                        }
                    }
                } else {
                    self.handleStreamError(.invalidURL, completion)
                }
            case .failure(let error):
                self.handleStreamError(.networkError(error), completion)
            }
        }
    }

    private func validateStream(_ url: URL, completion: @escaping (Result<Void, VideoError>) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { _, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                completion(.success(()))
            case 401, 403:
                completion(.failure(.unauthorized))
            default:
                completion(.failure(.serverError(httpResponse.statusCode)))
            }
        }
        task.resume()
    }

    private func handleStreamError(_ error: VideoError, _ completion: @escaping (Result<StreamResponse, Error>) -> Void) {
        lastError = error
        retryCount += 1
        
        if error.isRecoverable && retryCount < maxRetries {
            connectionState = .reconnecting(retryCount)
            queue.asyncAfter(deadline: .now() + .seconds(2)) { [weak self] in
                self?.attemptConnection(completion)
            }
        } else {
            connectionState = .failed(error)
            completion(.failure(error))
        }
    }

    /// Confirma conexión exitosa al stream.
    public func notifyStreamConnected() {
        connectionState = .connected
    }

    /// Maneja errores SSL conocidos.
    public func handleSSLError(for url: String) -> Bool {
        // Lista de hosts confiables que pueden tener certificados autofirmados
        let trustedHosts = ["172.20.10.3", "localhost", "127.0.0.1"]
        return trustedHosts.contains { url.contains($0) }
    }

    /// Estado actual de la conexión
    public var currentState: ConnectionState {
        connectionState
    }

    public enum ConnectionState: Equatable {
        case disconnected
        case connecting
        case connected
        case reconnecting(Int)
        case failed(VideoError)
    }

    public enum StreamQuality {
        case low    // 360p
        case medium // 720p
        case high   // 1080p
        case auto   // Adaptativo
    }

    public struct StreamResponse {
        public let url: URL
        public let state: ConnectionState
        public let quality: StreamQuality
    }

    public enum VideoError: LocalizedError {
        case invalidURL
        case unauthorized
        case serverError(Int)
        case networkError(Error)
        case invalidResponse
        case maxRetriesExceeded
        case sslError
        
        public var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "URL del stream inválida"
            case .unauthorized:
                return "No autorizado para acceder al stream"
            case .serverError(let code):
                return "Error del servidor: \(code)"
            case .networkError:
                return "Error de conexión"
            case .invalidResponse:
                return "Respuesta inválida del servidor"
            case .maxRetriesExceeded:
                return "Número máximo de intentos excedido"
            case .sslError:
                return "Error de certificado SSL"
            }
        }
        
        var isRecoverable: Bool {
            switch self {
            case .networkError, .serverError:
                return true
            case .invalidURL, .unauthorized, .invalidResponse, .maxRetriesExceeded, .sslError:
                return false
            }
        }
    }
}
