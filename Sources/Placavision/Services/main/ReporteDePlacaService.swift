import Foundation

public final class ReporteDePlacaService {
    private let repository: RepositoryProtocol
    private let fileHelper: FileHelperProtocol

    public init() {
        self.repository = Repository()
        self.fileHelper = FileHelper()
    }

    // DI initializer for tests
    public init(repository: RepositoryProtocol, fileHelper: FileHelperProtocol) {
        self.repository = repository
        self.fileHelper = fileHelper
    }

    /// Validates and processes a new plate report
    /// - Parameters:
    ///   - report: The report data to validate and submit
    ///   - completion: Called with ReportResponse or error
    public func processReport(
        plate: String,
        model: String,
        brand: String,
        year: String,
        type: String,
        description: String,
        phone: String,
        completion: @escaping (Result<ReportResponse, Error>) -> Void
    ) {
        // First validate all inputs
        let validationResult = validateInputs(
            plate: plate,
            model: model,
            brand: brand,
            year: year,
            typeIncidence: type,
            description: description,
            phone: phone
        )

        switch validationResult {
        case .success:
            submitReport(
                plate: plate,
                model: model,
                brand: brand,
                year: year,
                type: type,
                description: description,
                phone: phone
            ) { result in
                switch result {
                case .success(let message):
                    let response = ReportResponse(
                        status: .success,
                        message: message,
                        plate: plate.uppercased(),
                        reportDate: Date()
                    )
                    completion(.success(response))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        case .failure(let error):
            completion(.failure(error))
        }
    }

    /// Validates form inputs before submission
    private func validateInputs(
        plate: String,
        model: String,
        brand: String,
        year: String,
        typeIncidence: String,
        description: String,
        phone: String
    ) -> Result<Void, ValidationError> {
        // Check for empty fields
        guard !plate.isEmpty, !model.isEmpty, !brand.isEmpty,
              !year.isEmpty, !typeIncidence.isEmpty,
              !description.isEmpty, !phone.isEmpty else {
            return .failure(.missingFields)
        }

        // Validate plate format
        let platePattern = #"^[A-Z0-9]{6,7}$"#
        guard plate.uppercased().range(of: platePattern, options: .regularExpression) != nil else {
            return .failure(.invalidPlate)
        }

        // Validate year
        guard let yearInt = Int(year),
              yearInt >= 1900,
              yearInt <= Calendar.current.component(.year, from: Date()),
              year.count == 4 else {
            return .failure(.invalidYear)
        }

        // Validate phone
        let phonePattern = #"^\d{7,}$"#
        guard phone.range(of: phonePattern, options: .regularExpression) != nil else {
            return .failure(.invalidPhone)
        }

        // Validate description length
        guard (10...500).contains(description.count) else {
            return .failure(.invalidDescription)
        }

        return .success(())
    }

    /// Submits the validated report to the backend
    private func submitReport(
        plate: String,
        model: String,
        brand: String,
        year: String,
        type: String,
        description: String,
        phone: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let report = Report(
            placa_reportada: plate.uppercased(),
            tipo_incidencia: type,
            marca: brand,
            modelo: model,
            anio: Int(year) ?? 0,
            telefono_contacto: phone,
            descripcion: description,
            estado: "activo",
            fecha_reporte: ISO8601DateFormatter().string(from: Date())
        )

        // Check for duplicate reports first by fetching existing plates
        repository.getPlates { [weak self] result in
            switch result {
            case .success(let data):
                do {
                    let decoded = try JSONDecoder().decode(PlatesResponse.self, from: data)
                    let exists = decoded.plates.contains { $0.placa_reportada.uppercased() == plate.uppercased() && $0.estado == "activo" }
                    if exists {
                        completion(.failure(ValidationError.duplicateReport))
                        return
                    }
                } catch {
                    // If decoding fails, proceed to attempt submission (server will validate)
                }

                self?.repository.addPlate(report: report) { result in
                    switch result {
                    case .success:
                        completion(.success("Placa \(plate) reportada correctamente"))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure:
                // If we can't fetch existing plates, try to submit anyway
                self?.repository.addPlate(report: report) { result in
                    switch result {
                    case .success:
                        completion(.success("Placa \(plate) reportada correctamente"))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    public struct ReportResponse {
        public let status: Status
        public let message: String
        public let plate: String
        public let reportDate: Date

        public enum Status {
            case success
            case pending
            case failed
        }
    }

    public enum ValidationError: Error, LocalizedError {
        case missingFields
        case invalidPlate
        case invalidYear
        case invalidPhone
        case invalidDescription
        case duplicateReport
        case serverError

        public var errorDescription: String? {
            switch self {
            case .missingFields:
                return "Todos los campos son requeridos"
            case .invalidPlate:
                return "Formato de placa inválido"
            case .invalidYear:
                return "Año inválido"
            case .invalidPhone:
                return "Número de teléfono inválido"
            case .invalidDescription:
                return "La descripción debe tener entre 10 y 500 caracteres"
            case .duplicateReport:
                return "Esta placa ya ha sido reportada"
            case .serverError:
                return "Error al procesar el reporte"
            }
        }
    }
}
