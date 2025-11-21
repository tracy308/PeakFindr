
import Foundation

struct RegisterRequest: Codable {
    let email: String
    let username: String
    let password: String
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct AuthResponse: Codable {
    let user_id: String
    let token: String
}

/// Your backend /auth/me currently only echoes a user id, so keep this minimal.
struct MeResponse: Codable {
    let user_id: String
}
