import Foundation

final class UserService {
    static let shared = UserService()
    private init() {}

    func profile(userId: String) async throws -> UserProfileResponse {
        return try await APIClient.shared.request("/users/me", userId: userId)
    }
}

struct UserProfileResponse: Codable {
    let id: String
    let name: String
    let email: String
    let level: Int
    let points: Int
    let visits: [ProfileVisit]
    let reviews_count: Int
    let streak_days: Int
}

struct ProfileVisit: Codable, Identifiable, Equatable {
    let id: Int
    let location_name: String
    let date: String
    let points_earned: Int
}
