import Foundation

public final class VideoFeedService {
    private let repository = Repository()

    public init() {}

    /// Obtiene la URL del stream de video desde el backend.
    public func loadStreamURL(completion: @escaping (Result<URL, Error>) -> Void) {
        repository.getVideoFeed { result in
            switch result {
            case .success(let json):
                if let urlString = json["video_url"] as? String,
                   let url = URL(string: urlString) {
                    completion(.success(url))
                } else {
                    completion(.success(URL(string: "https://172.20.10.3:8000/api/video_feed")!))
                }
            case .failure:
                completion(.success(URL(string: "https://172.20.10.3:8000/api/video_feed")!))
            }
        }
    }

    /// Confirma conexión exitosa al stream.
    public func notifyStreamConnected() {
        print("✅ Conectado al video")
    }

    /// Maneja errores SSL conocidos.
    public func handleSSLError(for url: String) -> Bool {
        return url.contains("172.20.10.3")
    }
}
