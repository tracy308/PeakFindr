
import Foundation

/// Auth layer for your FastAPI backend.
///
/// Endpoints:
/// - POST /auth/register { email, username, password } -> { user_id, token }
/// - POST /auth/login { email, password } -> { user_id, token }
/// - GET /auth/me (currently debug echo) -> { user_id }
final class AuthService {
    static let shared = AuthService()
    private init() {}

    func register(email: String, username: String, password: String) async throws -> AuthResponse {
        if APIClient.shared.useMockServer {
            try await Task.sleep(nanoseconds: 400_000_000)
            return AuthResponse(user_id: UUID().uuidString, token: "mock.jwt.token")
        }
        let body = RegisterRequest(email: email, username: username, password: password)
        return try await APIClient.shared.request("/auth/register", method: "POST", body: body)
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        if APIClient.shared.useMockServer {
            try await Task.sleep(nanoseconds: 400_000_000)
            return AuthResponse(user_id: UUID().uuidString, token: "mock.jwt.token")
        }
        let body = LoginRequest(email: email, password: password)
        return try await APIClient.shared.request("/auth/login", method: "POST", body: body)
    }

    func me(token: String) async throws -> MeResponse {
        if APIClient.shared.useMockServer {
            try await Task.sleep(nanoseconds: 200_000_000)
            return MeResponse(user_id: "mock-user")
        }
        return try await APIClient.shared.request("/auth/me", token: token)
    }
}
