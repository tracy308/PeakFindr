
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
    let message: String
    let user_id: String
    let email: String
    let username: String
}

struct MeResponse: Codable {
    let message: String
    let user_id: String
}
