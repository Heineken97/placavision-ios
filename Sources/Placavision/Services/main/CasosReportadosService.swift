import Foundation

public final class CasosReportadosService {
    private let repository = Repository()
    private var currentPage = 1
    private let pageSize = 20
    private var hasMorePages = true
    private var isLoading = false
    private var cachedReports: [Report] = []
    private let queue = DispatchQueue(label: "com.placavision.reports", qos: .userInitiated)

    public init() {}

    /// Carga los reportes de placas desde el backend con paginación.
    public func loadPlates(refresh: Bool = false, completion: @escaping (Result<PlatesPage, Error>) -> Void) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            if refresh {
                self.resetPagination()
            }
            
            guard !self.isLoading && self.hasMorePages else {
                DispatchQueue.main.async {
                    completion(.success(PlatesPage(
                        reports: self.cachedReports,
                        hasMore: self.hasMorePages,
                        total: self.cachedReports.count
                    )))
                }
                return
            }
            
            self.isLoading = true
            
            self.repository.getPlates { result in
                defer { self.isLoading = false }
                
                switch result {
                case .success(let data):
                    do {
                        let rawJson = String(data: data, encoding: .utf8) ?? ""
                        let decoded = try JSONDecoder().decode(PlatesResponse.self, from: Data(rawJson.utf8))
                        
                        self.processNewPage(decoded.plates, refresh: refresh)
                        
                        DispatchQueue.main.async {
                            completion(.success(PlatesPage(
                                reports: self.cachedReports,
                                hasMore: self.hasMorePages,
                                total: self.cachedReports.count
                            )))
                        }
                    } catch {
                        DispatchQueue.main.async {
                            completion(.failure(ServiceError.decodingFailed))
                        }
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    private func processNewPage(_ reports: [Report], refresh: Bool) {
        if refresh {
            cachedReports = reports
        } else {
            cachedReports.append(contentsOf: reports)
        }
        
        hasMorePages = reports.count >= pageSize
        currentPage += 1
    }
    
    private func resetPagination() {
        currentPage = 1
        hasMorePages = true
        cachedReports.removeAll()
    }

    /// Elimina (marca como inactiva) una placa reportada.
    public func deletePlate(_ plate: String, completion: @escaping (Result<Void, Error>) -> Void) {
        repository.updatePlateState(plate: plate) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                // Update cache
                self.cachedReports.removeAll { $0.placa_reportada == plate }
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Busca reportes por placa, tipo o fecha
    public func searchReports(query: String) -> [Report] {
        let searchQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !searchQuery.isEmpty else { return cachedReports }
        
        return cachedReports.filter { report in
            report.placa_reportada.lowercased().contains(searchQuery) ||
            report.tipo_incidencia.lowercased().contains(searchQuery) ||
            report.fecha_reporte.lowercased().contains(searchQuery)
        }
    }
    
    /// Filtra reportes por estado
    public func filterByState(_ estado: String) -> [Report] {
        return cachedReports.filter { $0.estado == estado }
    }
    
    /// Ordena reportes por fecha
    public func sortByDate(ascending: Bool = false) -> [Report] {
        return cachedReports.sorted { a, b in
            if ascending {
                return a.fecha_reporte < b.fecha_reporte
            } else {
                return a.fecha_reporte > b.fecha_reporte
            }
        }
    }

    /// Formatea una línea de texto con etiqueta y valor.
    public func formatBold(label: String, value: String) -> String {
        return "\(label): \(value)"
    }
    
    public struct PlatesPage {
        public let reports: [Report]
        public let hasMore: Bool
        public let total: Int
    }

    /// Estructura de respuesta esperada desde el backend.
    public struct PlatesResponse: Codable {
        public let plates: [Report]
    }
    
    public enum ServiceError: LocalizedError {
        case decodingFailed
        case networkError
        case serverError
        
        public var errorDescription: String? {
            switch self {
            case .decodingFailed:
                return "Error al procesar los datos"
            case .networkError:
                return "Error de conexión"
            case .serverError:
                return "Error del servidor"
            }
        }
    }
}
