import Foundation

public struct APIService {
    public static func login(email: String, password: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let body = ["email": email, "password": password]
        APIClient.post(endpoint: APIConfig.loginURL, body: body, completion: completion)
    }

    public static func register(user: User, completion: @escaping (Result<Data, Error>) -> Void) {
        APIClient.postRaw(endpoint: APIConfig.registerURL, body: user, headers: ["x-api-key": ServerConfig.apiKey], completion: completion)
    }

    public static func getUser(authToken: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        APIClient.get(endpoint: APIConfig.userURL, headers: ["Authorization": authToken], completion: completion)
    }

    public static func updateUser(authToken: String, user: User, completion: @escaping (Result<Data, Error>) -> Void) {
        APIClient.putRaw(endpoint: APIConfig.userURL, body: user, headers: ["Authorization": authToken], completion: completion)
    }

    public static func deleteUser(authToken: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        APIClient.delete(endpoint: APIConfig.userURL, headers: ["Authorization": authToken], completion: completion)
    }

    public static func recoverPassword(authToken: String, email: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let body = ["email": email]
        APIClient.post(endpoint: "\(APIConfig.userURL)/recover", body: body, headers: ["Authorization": authToken], completion: completion)
    }

    public static func getPlates(authToken: String, completion: @escaping (Result<Data, Error>) -> Void) {
        APIClient.getRaw(endpoint: APIConfig.platesURL, headers: ["Authorization": authToken], completion: completion)
    }

    public static func addPlate(authToken: String, report: Report, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        APIClient.post(endpoint: APIConfig.platesURL, body: report, headers: ["Authorization": authToken], completion: completion)
    }

    public static func updatePlate(authToken: String, plate: String, reportData: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        APIClient.put(endpoint: "\(APIConfig.platesURL)/\(plate)", body: ["data": reportData], headers: ["Authorization": authToken], completion: completion)
    }

    public static func updatePlateState(authToken: String, plate: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        APIClient.put(endpoint: "\(APIConfig.platesURL)/\(plate)/estado", body: [:], headers: ["Authorization": authToken], completion: completion)
    }

    public static func getVideoFeed(authToken: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        APIClient.get(endpoint: APIConfig.videoFeedURL, headers: ["Authorization": authToken], completion: completion)
    }

    public static func getGpsLocation(authToken: String, completion: @escaping (Result<GpsResponse, Error>) -> Void) {
        APIClient.getDecodable(endpoint: APIConfig.gpsURL, headers: ["Authorization": authToken], completion: completion)
    }
}
