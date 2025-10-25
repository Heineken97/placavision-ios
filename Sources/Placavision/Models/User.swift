public struct User: Codable {
    public let correo: String
    public let contrasena: String
    public let nombre_usuario: String?
    public let identificador_nacional: String?
    public let telefono: String?
    public let role: String?

    public init(correo: String, contrasena: String, nombre_usuario: String? = nil,
                identificador_nacional: String? = nil, telefono: String? = nil, role: String? = nil) {
        self.correo = correo
        self.contrasena = contrasena
        self.nombre_usuario = nombre_usuario
        self.identificador_nacional = identificador_nacional
        self.telefono = telefono
        self.role = role
    }
}
