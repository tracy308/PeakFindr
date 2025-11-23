
import Foundation

/// Shared API client that injects auth token if available.
/// Switch `useMockServer` to false when your FastAPI backend is ready.
final class APIClient {
    static let shared = APIClient()
    private init() {}

    /// Change this to your FastAPI base URL, e.g. http://127.0.0.1:8000
    var baseURL: String = "http://127.0.0.1:8000"

    /// When true, login/register use a mock response so the app is usable before backend is ready.
    var useMockServer: Bool = true

    func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        body: Encodable? = nil,
        token: String? = nil
    ) async throws -> T {
        guard let url = URL(string: baseURL + path) else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.addValue("application/json", forHTTPHeaderField: "Accept")
        if let token {
            req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            req.addValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONEncoder().encode(AnyEncodable(body))
        }

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Request failed"
            throw APIError.http(status: http.statusCode, message: msg)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init(_ wrapped: Encodable) { _encode = wrapped.encode }
    func encode(to encoder: Encoder) throws { try _encode(encoder) }
}

enum APIError: Error, LocalizedError {
    case http(status: Int, message: String)

    var errorDescription: String? {
        switch self {
        case let .http(status, message):
            return "HTTP \(status): \(message)"
        }
    }
}
