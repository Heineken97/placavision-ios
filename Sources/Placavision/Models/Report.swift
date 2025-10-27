public struct Report: Codable {
    // Primary stored properties matching backend canonical keys used in tests
    public let placa: String
    public let tipo_incidencia: String?
    public let marca: String?
    public let modelo: String?
    public let anio: Int?
    public let telefono_contacto: String?
    public let descripcion: String
    public let estado: String
    public let fecha: String
    // optional ubicacion field used by some endpoints/tests
    public let ubicacion: String?

    // Backwards-compatible computed properties used by other services
    public var placa_reportada: String { return placa }
    public var fecha_reporte: String { return fecha }

    // Public convenience initializer used by tests (keeps defaults for other fields)
    public init(placa: String,
                estado: String,
                fecha: String,
                ubicacion: String? = nil,
                descripcion: String,
                marca: String? = nil,
                modelo: String? = nil,
                anio: Int? = nil,
                telefono_contacto: String? = nil,
                tipo_incidencia: String? = nil) {
        self.placa = placa
        self.estado = estado
        self.fecha = fecha
        self.ubicacion = ubicacion
        self.descripcion = descripcion
        self.marca = marca
        self.modelo = modelo
        self.anio = anio
        self.telefono_contacto = telefono_contacto
        self.tipo_incidencia = tipo_incidencia
    }

    // Custom CodingKeys to map incoming JSON keys to our stored properties
    private enum CodingKeys: String, CodingKey {
        case placa
        case placa_reportada
        case tipo_incidencia
        case marca
        case modelo
        case anio
        case telefono_contacto
        case descripcion
        case estado
        case fecha
        case fecha_reporte
        case ubicacion
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // try both possible keys for placa
        if let p = try? container.decode(String.self, forKey: .placa) {
            placa = p
        } else if let p = try? container.decode(String.self, forKey: .placa_reportada) {
            placa = p
        } else {
            placa = ""
        }

        tipo_incidencia = try? container.decodeIfPresent(String.self, forKey: .tipo_incidencia)
        marca = try? container.decodeIfPresent(String.self, forKey: .marca)
        modelo = try? container.decodeIfPresent(String.self, forKey: .modelo)
        anio = try? container.decodeIfPresent(Int.self, forKey: .anio)
        telefono_contacto = try? container.decodeIfPresent(String.self, forKey: .telefono_contacto)
        descripcion = (try? container.decode(String.self, forKey: .descripcion)) ?? ""
        estado = (try? container.decode(String.self, forKey: .estado)) ?? ""

        if let f = try? container.decode(String.self, forKey: .fecha) {
            fecha = f
        } else if let f = try? container.decode(String.self, forKey: .fecha_reporte) {
            fecha = f
        } else {
            fecha = ""
        }

        ubicacion = try? container.decodeIfPresent(String.self, forKey: .ubicacion)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(placa, forKey: .placa)
        try container.encodeIfPresent(tipo_incidencia, forKey: .tipo_incidencia)
        try container.encodeIfPresent(marca, forKey: .marca)
        try container.encodeIfPresent(modelo, forKey: .modelo)
        try container.encodeIfPresent(anio, forKey: .anio)
        try container.encodeIfPresent(telefono_contacto, forKey: .telefono_contacto)
        try container.encode(descripcion, forKey: .descripcion)
        try container.encode(estado, forKey: .estado)
        try container.encode(fecha, forKey: .fecha)
        try container.encodeIfPresent(ubicacion, forKey: .ubicacion)
    }
}
