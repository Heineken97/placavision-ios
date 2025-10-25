import Foundation

/// GPS polling service implemented without using Swift concurrency APIs
/// to keep compatibility with older deployment targets.
public final class GpsService {
    private let repository = Repository()
    private var timer: DispatchSourceTimer?
    private var locationObtained = false
    private let queue = DispatchQueue(label: "com.placavision.gps", qos: .background)

    public init() {}

    /// Inicia el ciclo de sondeo GPS hasta obtener una ubicación válida.
    public func startPolling(update: @escaping (GpsStatus) -> Void) {
        // cancel existing
        timer?.cancel()
        timer = nil
        locationObtained = false
        update(.searching)

        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now(), repeating: .seconds(5), leeway: .milliseconds(200))
        t.setEventHandler { [weak self] in
            guard let self = self, !self.locationObtained else { return }
            self.fetchLocation { success, status in
                if success {
                    self.locationObtained = true
                    DispatchQueue.main.async {
                        update(.location(lat: status.lat, lon: status.lon, alt: status.alt))
                        update(.success)
                    }
                    self.timer?.cancel()
                    self.timer = nil
                } else {
                    DispatchQueue.main.async {
                        update(status.fallback)
                    }
                }
            }
        }
        timer = t
        t.resume()
    }

    /// Cancela el ciclo de sondeo.
    public func cancelPolling() {
        timer?.cancel()
        timer = nil
    }

    private func fetchLocation(completion: @escaping (Bool, (lat: Double, lon: Double, alt: Double, fallback: GpsStatus)) -> Void) {
        repository.getGpsLocation { result in
            switch result {
            case .success(let gpsResponse):
                if let data = gpsResponse.data,
                   let lat = data.latitude,
                   let lon = data.longitude,
                   lat != 0.0, lon != 0.0 {
                    completion(true, (lat, lon, data.altitude ?? 0.0, .waiting))
                } else {
                    completion(false, (0, 0, 0, .waiting))
                }
            case .failure(let error):
                completion(false, (0, 0, 0, .error("Error: \(error.localizedDescription)")))
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
