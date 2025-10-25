import Foundation

public final class ReporteDePlacaService {
    private let repository = Repository()

    public init() {}

    /// Valida los campos del formulario antes de enviar el reporte.
    public func validateInputs(
        plate: String,
        model: String,
        brand: String,
        year: String,
        typeIncidence: String,
        description: String,
        phone: String
    ) -> Result<Void, ValidationError> {
        guard !plate.isEmpty, !model.isEmpty, !brand.isEmpty,
              !year.isEmpty, !typeIncidence.isEmpty,
              !description.isEmpty, !phone.isEmpty else {
            return .failure(.missingFields)
        }

        guard let yearInt = Int(year), year.count == 4 else {
            return .failure(.invalidYear)
        }

        guard phone.count >= 7 else {
            return .failure(.invalidPhone)
        }

        return .success(())
    }

    /// Envía el reporte al backend.
    public func submitReport(
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
            modelo: model,
            marca: brand,
            anio: Int(year) ?? 0,
            tipo_incidencia: type,
            descripcion: description,
            telefono_contacto: phone,
            estado: "activo",
            fecha_reporte: ISO8601DateFormatter().string(from: Date())
        )

        repository.addPlate(report: report) { result in
            switch result {
            case .success:
                completion(.success("Placa \(plate) reportada correctamente"))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public enum ValidationError: Error {
        case missingFields
        case invalidYear
        case invalidPhone
    }
}
