import Foundation
@testable import Placavision

/// Mock Repository for testing that returns predefined responses
final class MockRepository: Repository {
    var loginResponse: Result<[String: Any], Error> = .failure(NSError(domain: "", code: -1))
    var registerResponse: Result<Data, Error> = .failure(NSError(domain: "", code: -1))
    var updateUserResponse: Result<Data, Error> = .failure(NSError(domain: "", code: -1))
    var userResponse: Result<[String: Any], Error> = .failure(NSError(domain: "", code: -1))
    var platesResponse: Result<Data, Error> = .failure(NSError(domain: "", code: -1))
    var videoFeedResponse: Result<[String: Any], Error> = .failure(NSError(domain: "", code: -1))
    var gpsResponse: Result<GpsResponse, Error> = .failure(NSError(domain: "", code: -1))
    var recoveryResponse: Result<Data, Error> = .failure(NSError(domain: "", code: -1))

    override public func login(email: String, password: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        completion(loginResponse)
    }

    override public func register(user: User, completion: @escaping (Result<Data, Error>) -> Void) {
        completion(registerResponse)
    }

    override public func updateUser(authToken: String, user: User, completion: @escaping (Result<Data, Error>) -> Void) {
        completion(updateUserResponse)
    }

    override public func getUser(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        completion(userResponse)
    }

    override public func getPlates(completion: @escaping (Result<Data, Error>) -> Void) {
        completion(platesResponse)
    }

    override public func getVideoFeed(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        completion(videoFeedResponse)
    }

    override public func getGpsLocation(completion: @escaping (Result<GpsResponse, Error>) -> Void) {
        completion(gpsResponse)
    }
    
    override public func requestPasswordRecovery(email: String, completion: @escaping (Result<Data, Error>) -> Void) {
        completion(recoveryResponse)
    }
}