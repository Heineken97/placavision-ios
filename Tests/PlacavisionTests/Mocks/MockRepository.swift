import Foundation
@testable import Placavision

/// Mock Repository for testing that returns predefined responses
final class MockRepository: RepositoryProtocol {
    var loginResponse: Result<[String: Any], Error> = .failure(NSError(domain: "", code: -1))
    var registerResponse: Result<Data, Error> = .failure(NSError(domain: "", code: -1))
    var updateUserResponse: Result<Data, Error> = .failure(NSError(domain: "", code: -1))
    var userResponse: Result<[String: Any], Error> = .failure(NSError(domain: "", code: -1))
    var platesResponse: Result<Data, Error> = .failure(NSError(domain: "", code: -1))
    var videoFeedResponse: Result<[String: Any], Error> = .failure(NSError(domain: "", code: -1))
    var gpsResponse: Result<GpsResponse, Error> = .failure(NSError(domain: "", code: -1))
    var recoveryResponse: Result<[String: Any], Error> = .failure(NSError(domain: "", code: -1))
    var submitReportResponse: Result<Data, Error> = .failure(NSError(domain: "", code: -1))

    public init() {}

    public func login(email: String, password: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        completion(loginResponse)
    }

    public func register(user: User, completion: @escaping (Result<Data, Error>) -> Void) {
        completion(registerResponse)
    }

    public func recoverPassword(email: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        completion(recoveryResponse)
    }

    public func updateUser(user: User, completion: @escaping (Result<Data, Error>) -> Void) {
        completion(updateUserResponse)
    }

    public func deleteUser(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        completion(userResponse)
    }

    public func addPlate(report: Report, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        // Map to submitReportResponse for older tests expecting a Data response
        switch submitReportResponse {
        case .success(let data):
            // Try to decode JSON to [String: Any] if possible, otherwise return empty dict
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                completion(.success(json))
            } else {
                completion(.success([:]))
            }
        case .failure(let err):
            completion(.failure(err))
        }
    }

    public func getPlates(completion: @escaping (Result<Data, Error>) -> Void) {
        completion(platesResponse)
    }

    public func updatePlate(plate: String, reportData: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        completion(userResponse)
    }

    public func updatePlateState(plate: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        completion(userResponse)
    }

    public func getVideoFeed(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        completion(videoFeedResponse)
    }

    public func getUser(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        completion(userResponse)
    }

    public func getGpsLocation(completion: @escaping (Result<GpsResponse, Error>) -> Void) {
        completion(gpsResponse)
    }
}