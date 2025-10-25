import Foundation

public final class Repository {
    private let fileHelper = FileHelper()

    public init() {}

    public func getAuthToken() -> String {
        guard let token = fileHelper.getAuthToken() else { return "" }
        return "Bearer \(token)"
    }

    public func login(email: String, password: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
    APIService.login(email: email, password: password, completion: completion)
    }

    public func register(user: User, completion: @escaping (Result<Data, Error>) -> Void) {
        APIService.register(user: user, completion: completion)
    }

    public func recoverPassword(email: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        APIService.recoverPassword(authToken: getAuthToken(), email: email, completion: completion)
    }

    public func updateUser(user: User, completion: @escaping (Result<Data, Error>) -> Void) {
        APIService.updateUser(authToken: getAuthToken(), user: user, completion: completion)
    }

    public func deleteUser(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        APIService.deleteUser(authToken: getAuthToken(), completion: completion)
    }

    public func addPlate(report: Report, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        APIService.addPlate(authToken: getAuthToken(), report: report, completion: completion)
    }

    public func getPlates(completion: @escaping (Result<Data, Error>) -> Void) {
        APIService.getPlates(authToken: getAuthToken(), completion: completion)
    }

    public func getVideoFeed(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        APIService.getVideoFeed(authToken: getAuthToken(), completion: completion)
    }

    public func updatePlateState(plate: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        APIService.updatePlateState(authToken: getAuthToken(), plate: plate, completion: completion)
    }

    public func getGpsLocation(completion: @escaping (Result<GpsResponse, Error>) -> Void) {
        APIService.getGpsLocation(authToken: getAuthToken(), completion: completion)
    }
}
