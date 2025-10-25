import Foundation

public final class CasosReportadosService {
    private let repository = Repository()

    public init() {}

    /// Carga los reportes de placas desde el backend.
    public func loadPlates(completion: @escaping (Result<[Report], Error>) -> Void) {
        repository.getPlates { result in
            switch result {
            case .success(let data):
                do {
                    let rawJson = String(data: data, encoding: .utf8) ?? ""
                    let decoded = try JSONDecoder().decode(PlatesResponse.self, from: Data(rawJson.utf8))
                    completion(.success(decoded.plates))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Elimina (marca como inactiva) una placa reportada.
    public func deletePlate(_ plate: String, completion: @escaping (Result<Void, Error>) -> Void) {
        repository.updatePlateState(plate: plate) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Formatea una línea de texto con etiqueta y valor.
    public func formatBold(label: String, value: String) -> String {
        return "\(label): \(value)"
    }

    /// Estructura de respuesta esperada desde el backend.
    public struct PlatesResponse: Codable {
        public let plates: [Report]
    }
}
