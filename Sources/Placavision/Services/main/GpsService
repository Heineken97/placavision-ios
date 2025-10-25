import Foundation

public final class GpsService {
    private let repository = Repository()
    private var pollingTask: Task<Void, Never>?
    private var locationObtained = false

    public init() {}

    /// Inicia el ciclo de sondeo GPS hasta obtener una ubicación válida.
    public func startPolling(update: @escaping (GpsStatus) -> Void) {
        pollingTask?.cancel()
        locationObtained = false
        update(.searching)

        pollingTask = Task {
            while !Task.isCancelled && !locationObtained {
                let success = await fetchLocation(update: update)
                if success {
                    locationObtained = true
                    update(.success)
                    break
                }
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 segundos
            }
        }
    }

    /// Cancela el ciclo de sondeo.
    public func cancelPolling() {
        pollingTask?.cancel()
    }

    /// Llama al backend para obtener la ubicación GPS.
    private func fetchLocation(update: @escaping (GpsStatus) -> Void) async -> Bool {
        return await withCheckedContinuation { continuation in
            repository.getGpsLocation { result in
                switch result {
                case .success(let gpsResponse):
                    if let data = gpsResponse.data,
                       let lat = data.latitude,
                       let lon = data.longitude,
                       lat != 0.0, lon != 0.0 {
                        update(.location(lat: lat, lon: lon, alt: data.altitude ?? 0.0))
                        continuation.resume(returning: true)
                    } else {
                        update(.waiting)
                        continuation.resume(returning: false)
                    }
                case .failure(let error):
                    update(.error("Error: \(error.localizedDescription)"))
                    continuation.resume(returning: false)
                }
            }
        }
    }

    /// Estados posibles durante el sondeo GPS.
    public enum GpsStatus {
        case searching
        case waiting
        case location(lat: Double, lon: Double, alt: Double)
        case success
        case error(String)
    }
}
