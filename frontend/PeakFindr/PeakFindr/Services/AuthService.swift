
import Foundation

final class AuthService {
    static let shared = AuthService()
    private init() {}

    func register(email: String, username: String, password: String) async throws -> AuthResponse {
        let body = RegisterRequest(email: email, username: username, password: password)
        return try await APIClient.shared.request("/auth/register", method: "POST", body: body)
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        let body = LoginRequest(email: email, password: password)
        return try await APIClient.shared.request("/auth/login", method: "POST", body: body)
    }

    func me(userId: String) async throws -> MeResponse {
        return try await APIClient.shared.request("/auth/me", userId: userId)
    }
}
