import Foundation

/// GPS polling service implemented without using Swift concurrency APIs
/// to keep compatibility with older deployment targets.
public final class GpsService {
    private let repository = Repository()
    private var timer: DispatchSourceTimer?
    private var locationObtained = false
    private let queue = DispatchQueue(label: "com.placavision.gps", qos: .background)
    private var retryCount = 0
    private let maxRetries = 10  // 50 seconds max (5s * 10)
    private var lastValidLocation: LocationData?
    private var precisionThreshold = 10.0  // meters
    
    public init() {}

    /// Inicia el ciclo de sondeo GPS hasta obtener una ubicación válida.
    public func startPolling(update: @escaping (GpsStatus) -> Void) {
        // Reset state
        timer?.cancel()
        timer = nil
        locationObtained = false
        retryCount = 0
        lastValidLocation = nil
        update(.searching)

        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now(), repeating: .seconds(5), leeway: .milliseconds(200))
        t.setEventHandler { [weak self] in
            guard let self = self else { return }
            
            if self.retryCount >= self.maxRetries {
                self.timer?.cancel()
                self.timer = nil
                DispatchQueue.main.async {
                    if let last = self.lastValidLocation {
                        update(.location(lat: last.lat, lon: last.lon, alt: last.alt))
                        update(.success)
                    } else {
                        update(.error("No se pudo obtener ubicación después de \(self.maxRetries) intentos"))
                    }
                }
                return
            }
            
            self.fetchLocation { success, status in
                self.retryCount += 1
                
                if success {
                    // Update last valid location
                    self.lastValidLocation = LocationData(
                        lat: status.lat,
                        lon: status.lon,
                        alt: status.alt,
                        accuracy: status.accuracy
                    )
                    
                    // Check if location meets precision requirements
                    if status.accuracy <= self.precisionThreshold {
                        self.locationObtained = true
                        self.timer?.cancel()
                        self.timer = nil
                        DispatchQueue.main.async {
                            update(.location(lat: status.lat, lon: status.lon, alt: status.alt))
                            update(.success)
                        }
                    } else {
                        DispatchQueue.main.async {
                            update(.waiting)
                            update(.location(lat: status.lat, lon: status.lon, alt: status.alt))
                        }
                    }
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

    private func fetchLocation(completion: @escaping (Bool, (lat: Double, lon: Double, alt: Double, accuracy: Double, fallback: GpsStatus)) -> Void) {
        repository.getGpsLocation { result in
            switch result {
            case .success(let gpsResponse):
                if let data = gpsResponse.data,
                   let lat = data.latitude,
                   let lon = data.longitude,
                   let accuracy = data.accuracy,
                   lat != 0.0, lon != 0.0 {
                    
                    let alt = data.altitude ?? 0.0
                    
                    // Validate coordinates are within Costa Rica bounds
                    if !self.isValidCoordinate(lat: lat, lon: lon) {
                        completion(false, (0, 0, 0, 0, .error("Ubicación fuera de Costa Rica")))
                        return
                    }
                    
                    completion(true, (lat, lon, alt, accuracy, .waiting))
                } else {
                    completion(false, (0, 0, 0, 0, .waiting))
                }
            case .failure(let error):
                completion(false, (0, 0, 0, 0, .error("Error: \(error.localizedDescription)")))
            }
        }
    }
    
    private func isValidCoordinate(lat: Double, lon: Double) -> Bool {
        // Costa Rica approximate bounds
        let minLat = 8.0
        let maxLat = 11.5
        let minLon = -86.0
        let maxLon = -82.5
        
        return (minLat...maxLat).contains(lat) && 
               (minLon...maxLon).contains(lon)
    }

    /// Estados posibles durante el sondeo GPS.
    public enum GpsStatus: Equatable {
        case searching
        case waiting
        case location(lat: Double, lon: Double, alt: Double)
        case success
        case error(String)
        
        public var description: String {
            switch self {
            case .searching:
                return "Buscando ubicación..."
            case .waiting:
                return "Esperando señal GPS..."
            case .location(let lat, let lon, _):
                return String(format: "Lat: %.6f, Lon: %.6f", lat, lon)
            case .success:
                return "Ubicación encontrada"
            case .error(let msg):
                return "Error: \(msg)"
            }
        }
    }
    
    private struct LocationData {
        let lat: Double
        let lon: Double
        let alt: Double
        let accuracy: Double
    }
}
