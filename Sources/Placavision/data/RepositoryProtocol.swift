import Foundation

public protocol RepositoryProtocol {
    func login(email: String, password: String, completion: @escaping (Result<[String: Any], Error>) -> Void)
    func register(user: User, completion: @escaping (Result<Data, Error>) -> Void)
    func recoverPassword(email: String, completion: @escaping (Result<[String: Any], Error>) -> Void)
    func updateUser(user: User, completion: @escaping (Result<Data, Error>) -> Void)
    func deleteUser(completion: @escaping (Result<[String: Any], Error>) -> Void)
    func addPlate(report: Report, completion: @escaping (Result<[String: Any], Error>) -> Void)
    func getPlates(completion: @escaping (Result<Data, Error>) -> Void)
    func updatePlate(plate: String, reportData: String, completion: @escaping (Result<[String: Any], Error>) -> Void)
    func updatePlateState(plate: String, completion: @escaping (Result<[String: Any], Error>) -> Void)
    func getVideoFeed(completion: @escaping (Result<[String: Any], Error>) -> Void)
    func getUser(completion: @escaping (Result<[String: Any], Error>) -> Void)
    func getGpsLocation(completion: @escaping (Result<GpsResponse, Error>) -> Void)
}