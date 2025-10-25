import Foundation

public final class Repository {
    private let fileHelper = FileHelper()
    private let apiService = APIService()

    public init() {}

    public func getAuthToken() -> String {
        guard let token = fileHelper.getAuthToken() else { return "" }
        return "Bearer \(token)"
    }

    public func login(email: String, password: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let credentials = ["email": email, "password": password]
        apiService.login(email: email, password: password, completion: completion)
    }

    public func register(user: User, completion: @escaping (Result<Data, Error>) -> Void) {
        apiService.register(user: user, completion: completion)
    }

    public func recoverPassword(email: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        apiService.recoverPassword(authToken: getAuthToken(), email: email, completion: completion)
    }

    public func updateUser(user: User, completion: @escaping (Result<Data, Error>) -> Void) {
        apiService.updateUser(authToken: getAuthToken(), user: user, completion: completion)
    }

    public func deleteUser(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        apiService.deleteUser(authToken: getAuthToken(), completion: completion)
    }

    public func addPlate(report: Report, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        apiService.addPlate(authToken: getAuthToken(), report: report, completion: completion)
    }

    public func updatePlateState(plate: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        apiService.updatePlateState(authToken: getAuthToken(), plate: plate, completion: completion)
    }

    public func getGpsLocation(completion: @escaping (Result<GpsResponse, Error>) -> Void) {
        apiService.getGpsLocation(authToken: getAuthToken(), completion: completion)
    }
}
