import Foundation

public enum APIClient {
    public enum APIError: Error {
        case invalidURL
        case requestFailed(Error)
        case invalidResponse
        case decodingError
        case invalidStatusCode(Int)
    }

    // AnyEncodable wrapper to encode Encodable existentials
    private struct AnyEncodable: Encodable {
        private let _encode: (Encoder) throws -> Void
        init<T: Encodable>(_ wrapped: T) {
            self._encode = wrapped.encode
        }
        // Existential overload for `any Encodable` values
        init(_ wrapped: any Encodable) {
            self._encode = { encoder in
                try wrapped.encode(to: encoder)
            }
        }
        func encode(to encoder: Encoder) throws {
            try _encode(encoder)
        }
    }

    private static func makeRequest(endpoint: String, method: String, headers: [String: String]?, bodyData: Data?) throws -> URLRequest {
        var url = URL(string: endpoint)
        // If endpoint is a relative path (no scheme), try to prepend APIConfig.baseURL
        if url == nil || url?.scheme == nil {
            if let full = URL(string: APIConfig.baseURL + endpoint) {
                url = full
            }
        }
        guard let url = url else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = method
        if let headers = headers {
            for (k, v) in headers { req.setValue(v, forHTTPHeaderField: k) }
        }
        if let data = bodyData {
            req.httpBody = data
            if req.value(forHTTPHeaderField: "Content-Type") == nil {
                req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        }
        return req
    }

    private static func perform(request: URLRequest, completion: @escaping (Result<Data, Error>) -> Void) {
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(APIError.requestFailed(error)))
                return
            }
            guard let http = response as? HTTPURLResponse, let data = data else {
                completion(.failure(APIError.invalidResponse))
                return
            }
            guard 200..<300 ~= http.statusCode else {
                completion(.failure(APIError.invalidStatusCode(http.statusCode)))
                return
            }
            completion(.success(data))
        }
        task.resume()
    }

    private static func encodeBody(_ body: Any?) -> Data? {
        guard let body = body else { return nil }
        if let data = body as? Data { return data }
        if JSONSerialization.isValidJSONObject(body) {
            return try? JSONSerialization.data(withJSONObject: body, options: [])
        }
        // Try to encode Encodable values using AnyEncodable (support existential)
        if let enc = body as? any Encodable {
            let any = AnyEncodable(enc)
            return try? JSONEncoder().encode(any)
        }
        return nil
    }

    // Raw variants returning Data for callers that expect raw Data
    public static func postRaw(endpoint: String, body: Any?, headers: [String: String]? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        do {
            let data = encodeBody(body)
            let req = try makeRequest(endpoint: endpoint, method: "POST", headers: headers, bodyData: data)
            perform(request: req, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    public static func putRaw(endpoint: String, body: Any?, headers: [String: String]? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        do {
            let data = encodeBody(body)
            let req = try makeRequest(endpoint: endpoint, method: "PUT", headers: headers, bodyData: data)
            perform(request: req, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    // MARK: - Public convenience methods

    public static func post(endpoint: String, body: Any?, headers: [String: String]? = nil, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        do {
            let data = encodeBody(body)
            let req = try makeRequest(endpoint: endpoint, method: "POST", headers: headers, bodyData: data)
            perform(request: req) { result in
                switch result {
                case .success(let data):
                    do {
                        if data.isEmpty {
                            completion(.success([:]))
                            return
                        }
                        let json = try JSONSerialization.jsonObject(with: data, options: [])
                        if let dict = json as? [String: Any] {
                            completion(.success(dict))
                        } else if let arr = json as? [Any] {
                            completion(.success(["data": arr]))
                        } else {
                            completion(.failure(APIError.decodingError))
                        }
                    } catch {
                        completion(.failure(APIError.decodingError))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }

    public static func get(endpoint: String, headers: [String: String]? = nil, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        do {
            let req = try makeRequest(endpoint: endpoint, method: "GET", headers: headers, bodyData: nil)
            perform(request: req) { result in
                switch result {
                case .success(let data):
                    do {
                        if data.isEmpty { completion(.success([:])); return }
                        let json = try JSONSerialization.jsonObject(with: data, options: [])
                        if let dict = json as? [String: Any] { completion(.success(dict)) }
                        else if let arr = json as? [Any] { completion(.success(["data": arr])) }
                        else { completion(.failure(APIError.decodingError)) }
                    } catch {
                        completion(.failure(APIError.decodingError))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }

    public static func put(endpoint: String, body: Any?, headers: [String: String]? = nil, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        do {
            let data = encodeBody(body)
            let req = try makeRequest(endpoint: endpoint, method: "PUT", headers: headers, bodyData: data)
            perform(request: req) { result in
                switch result {
                case .success(let data):
                    do {
                        if data.isEmpty { completion(.success([:])); return }
                        let json = try JSONSerialization.jsonObject(with: data, options: [])
                        if let dict = json as? [String: Any] { completion(.success(dict)) }
                        else { completion(.failure(APIError.decodingError)) }
                    } catch {
                        completion(.failure(APIError.decodingError))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }

    public static func delete(endpoint: String, headers: [String: String]? = nil, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        do {
            let req = try makeRequest(endpoint: endpoint, method: "DELETE", headers: headers, bodyData: nil)
            perform(request: req) { result in
                switch result {
                case .success(let data):
                    do {
                        if data.isEmpty { completion(.success([:])); return }
                        let json = try JSONSerialization.jsonObject(with: data, options: [])
                        if let dict = json as? [String: Any] { completion(.success(dict)) }
                        else { completion(.failure(APIError.decodingError)) }
                    } catch {
                        completion(.failure(APIError.decodingError))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }

    public static func getRaw(endpoint: String, headers: [String: String]? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        do {
            let req = try makeRequest(endpoint: endpoint, method: "GET", headers: headers, bodyData: nil)
            perform(request: req) { result in
                completion(result)
            }
        } catch {
            completion(.failure(error))
        }
    }

    public static func getDecodable<T: Decodable>(endpoint: String, headers: [String: String]? = nil, completion: @escaping (Result<T, Error>) -> Void) {
        do {
            let req = try makeRequest(endpoint: endpoint, method: "GET", headers: headers, bodyData: nil)
            perform(request: req) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoded = try JSONDecoder().decode(T.self, from: data)
                        completion(.success(decoded))
                    } catch {
                        completion(.failure(APIError.decodingError))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
}
