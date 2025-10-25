import Foundation

public final class EditProfileService {
    private let repository = Repository()
    private let fileHelper = FileHelper()

    public init() {}

    /// Obtiene el usuario actual desde almacenamiento local.
    public func getCurrentUser() -> User? {
        let user = fileHelper.getCurrentUser()
        return user.correo.isEmpty ? nil : user
    }

    /// Valida los campos del formulario antes de actualizar el perfil.
    public func validateInputs(
        email: String,
        username: String,
        phone: String,
        nationalId: String,
        newPassword: String?
    ) -> Result<Void, ValidationError> {
        guard !email.isEmpty, email.contains("@") else {
            return .failure(.invalidEmail)
        }

        guard username.count >= 3 else {
            return .failure(.invalidUsername)
        }

        guard phone.count >= 8 else {
            return .failure(.invalidPhone)
        }

        guard nationalId.count >= 5 else {
            return .failure(.invalidNationalId)
        }

        if let password = newPassword, !password.isEmpty, password.count < 6 {
            return .failure(.weakPassword)
        }

        return .success(())
    }

    /// Actualiza el perfil del usuario en el backend y localmente.
    public func updateProfile(
        email: String,
        username: String,
        phone: String,
        nationalId: String,
        newPassword: String?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let currentUser = getCurrentUser() else {
            completion(.failure(ProfileError.userNotFound))
            return
        }

        let updatedUser = User(
            correo: email,
            contrasena: newPassword?.isEmpty == false ? newPassword! : currentUser.contrasena ?? "",
            nombre_usuario: username,
            telefono: phone,
            identificador_nacional: nationalId,
            role: currentUser.role ?? "ios_device"
        )

        repository.updateUser(user: updatedUser) { result in
            switch result {
            case .success:
                self.fileHelper.saveUser(updatedUser)
                self.fileHelper.setCurrentUser(updatedUser.correo)
                completion(.success("Perfil actualizado correctamente"))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Elimina el perfil del usuario en el backend y limpia los datos locales.
    public func deleteProfile(completion: @escaping (Result<Void, Error>) -> Void) {
        repository.deleteUser { result in
            switch result {
            case .success:
                self.fileHelper.clearCurrentUser()
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public enum ValidationError: Error {
        case invalidEmail
        case invalidUsername
        case invalidPhone
        case invalidNationalId
        case weakPassword
    }

    public enum ProfileError: Error {
        case userNotFound
    }
}
