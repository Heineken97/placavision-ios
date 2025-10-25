import Foundation

public struct APIClient {
    public static func post(endpoint: String, body: [String: String], completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard let url = URL(string: "https://api.placavision.com\(endpoint)") else {
            completion(.failure(APIError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                completion(.failure(APIError.invalidResponse))
                return
            }

            completion(.success(json))
        }.resume()
    }

    public enum APIError: Error {
        case invalidURL
        case invalidResponse
    }
}
