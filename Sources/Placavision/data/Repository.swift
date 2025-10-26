import Foundation

public final class Repository {
    private let fileHelper = FileHelper()

    public init() {}

    private func configureNetworkDefaults() {
        // Provide default headers for APIClient so all requests include X-API-Key and Authorization
        APIClient.defaultHeadersProvider = { [weak self] in
            guard let self = self else { return ["X-API-Key": ServerConfig.apiKey] }
            let token = self.fileHelper.getAuthToken() ?? ""
            let authHeader = token.isEmpty ? "" : "Bearer \(token)"
            return ["X-API-Key": ServerConfig.apiKey, "Authorization": authHeader]
        }
    }

    public func getAuthToken() -> String {
        guard let token = fileHelper.getAuthToken() else { return "" }
        return "Bearer \(token)"
    }

    public func login(email: String, password: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        // Ensure APIClient default headers are configured
        configureNetworkDefaults()
        APIService.login(email: email, password: password, completion: completion)
    }

    public func register(user: User, completion: @escaping (Result<Data, Error>) -> Void) {
        configureNetworkDefaults()
        APIService.register(user: user, completion: completion)
    }

    public func recoverPassword(email: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        configureNetworkDefaults()
        APIService.recoverPassword(authToken: getAuthToken(), email: email, completion: completion)
    }

    public func updateUser(user: User, completion: @escaping (Result<Data, Error>) -> Void) {
        configureNetworkDefaults()
        APIService.updateUser(authToken: getAuthToken(), user: user, completion: completion)
    }

    public func deleteUser(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        configureNetworkDefaults()
        APIService.deleteUser(authToken: getAuthToken(), completion: completion)
    }

    public func addPlate(report: Report, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        configureNetworkDefaults()
        APIService.addPlate(authToken: getAuthToken(), report: report, completion: completion)
    }

    public func getPlates(completion: @escaping (Result<Data, Error>) -> Void) {
        configureNetworkDefaults()
        APIService.getPlates(authToken: getAuthToken(), completion: completion)
    }

    public func getVideoFeed(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        configureNetworkDefaults()
        APIService.getVideoFeed(authToken: getAuthToken(), completion: completion)
    }

    public func getUser(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        configureNetworkDefaults()
        APIService.getUser(authToken: getAuthToken(), completion: completion)
    }

    public func updatePlate(plate: String, reportData: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        configureNetworkDefaults()
        APIService.updatePlate(authToken: getAuthToken(), plate: plate, reportData: reportData, completion: completion)
    }

    public func updatePlateState(plate: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        configureNetworkDefaults()
        APIService.updatePlateState(authToken: getAuthToken(), plate: plate, completion: completion)
    }

    public func getGpsLocation(completion: @escaping (Result<GpsResponse, Error>) -> Void) {
        configureNetworkDefaults()
        APIService.getGpsLocation(authToken: getAuthToken(), completion: completion)
    }
}
