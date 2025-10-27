import Foundation

public final class APIClient {
    public enum APIError: Error, Equatable {
        case invalidURL
        case requestFailed(Error)
        case invalidResponse
        case decodingError
        case invalidStatusCode(Int)
        
        public static func == (lhs: APIError, rhs: APIError) -> Bool {
            switch (lhs, rhs) {
            case (.invalidURL, .invalidURL),
                 (.invalidResponse, .invalidResponse),
                 (.decodingError, .decodingError):
                return true
            case (.invalidStatusCode(let l), .invalidStatusCode(let r)):
                return l == r
            case (.requestFailed(let l), .requestFailed(let r)):
                return l.localizedDescription == r.localizedDescription
            default:
                return false
            }
        }
    }
    
    private struct AnyEncodable: Encodable {
        private let _encode: (Encoder) throws -> Void
        init<T: Encodable>(_ wrapped: T) {
            self._encode = wrapped.encode
        }
        init(_ wrapped: any Encodable) {
            self._encode = { encoder in
                try wrapped.encode(to: encoder)
            }
        }
        func encode(to encoder: Encoder) throws {
            try _encode(encoder)
        }
    }
    
    private class PinningDelegate: NSObject, URLSessionDelegate {
        static let shared = PinningDelegate()
        private let localCertData: Data?
        private let trustedHosts = ["172.20.10.3", "localhost", "127.0.0.1"]

        override init() {
            #if os(iOS) || os(macOS)
            if let url = Bundle.module.url(forResource: "cert", withExtension: "pem"),
               let pem = try? String(contentsOf: url, encoding: .utf8) {
                let base64 = pem
                    .replacingOccurrences(of: "-----BEGIN CERTIFICATE-----", with: "")
                    .replacingOccurrences(of: "-----END CERTIFICATE-----", with: "")
                    .replacingOccurrences(of: "\n", with: "")
                    .replacingOccurrences(of: "\r", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                self.localCertData = Data(base64Encoded: base64)
            } else {
                self.localCertData = nil
            }
            #else
            self.localCertData = nil
            #endif
            super.init()
        }

        func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            #if os(iOS) || os(macOS)
            guard let serverTrust = challenge.protectionSpace.serverTrust,
                  let serverCert = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
                completionHandler(.performDefaultHandling, nil)
                return
            }

            let serverCertData = SecCertificateCopyData(serverCert) as Data

            if let local = localCertData {
                if local == serverCertData {
                    completionHandler(.useCredential, URLCredential(trust: serverTrust))
                    return
                } else {
                    completionHandler(.cancelAuthenticationChallenge, nil)
                    return
                }
            }

            let host = challenge.protectionSpace.host
            if trustedHosts.contains(host) {
                completionHandler(.useCredential, URLCredential(trust: serverTrust))
                return
            }

            completionHandler(.performDefaultHandling, nil)
            #else
            completionHandler(.performDefaultHandling, nil)
            #endif
        }
    }

    private static let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        return URLSession(configuration: cfg, delegate: PinningDelegate.shared, delegateQueue: nil)
    }()

    public static var defaultHeadersProvider: (() -> [String: String]?)?

    private static func makeRequest(endpoint: String, method: String, headers: [String: String]?, bodyData: Data?) throws -> URLRequest {
        var url = URL(string: endpoint)
        if url == nil || url?.scheme == nil {
            if let full = URL(string: APIConfig.baseURL + endpoint) {
                url = full
            }
        }
        guard let url = url else { throw APIError.invalidURL }
        
        var req = URLRequest(url: url)
        req.httpMethod = method
        
        var merged = [String: String]()
        if let provider = defaultHeadersProvider, let defaults = provider() {
            merged.merge(defaults) { (_, new) in new }
        }
        if let headers = headers {
            merged.merge(headers) { (_, new) in new }
        }
        
        for (key, value) in merged {
            req.setValue(value, forHTTPHeaderField: key)
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
        let task = session.dataTask(with: request) { data, response, error in
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
        if let enc = body as? any Encodable {
            let any = AnyEncodable(enc)
            return try? JSONEncoder().encode(any)
        }
        return nil
    }

    // MARK: - Public API Methods
    
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

    public static func post(endpoint: String, body: Any?, headers: [String: String]? = nil, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        do {
            let data = encodeBody(body)
            let req = try makeRequest(endpoint: endpoint, method: "POST", headers: headers, bodyData: data)
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

    public static func getRaw(endpoint: String, headers: [String: String]? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        do {
            let req = try makeRequest(endpoint: endpoint, method: "GET", headers: headers, bodyData: nil)
            perform(request: req, completion: completion)
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