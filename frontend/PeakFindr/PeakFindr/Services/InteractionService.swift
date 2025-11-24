
import Foundation

final class InteractionService {
    static let shared = InteractionService()
    private init() {}

    func like(locationId: String, userId: String) async throws -> InteractionMessage {
        return try await APIClient.shared.request("/interactions/like/\(locationId)", method: "POST", userId: userId)
    }

    func unlike(locationId: String, userId: String) async throws -> InteractionMessage {
        return try await APIClient.shared.request("/interactions/like/\(locationId)", method: "DELETE", userId: userId)
    }

    func save(locationId: String, userId: String) async throws -> InteractionMessage {
        return try await APIClient.shared.request("/interactions/save/\(locationId)", method: "POST", userId: userId)
    }

    func unsave(locationId: String, userId: String) async throws -> InteractionMessage {
        return try await APIClient.shared.request("/interactions/save/\(locationId)", method: "DELETE", userId: userId)
    }

    func getSaved(userId: String) async throws -> [LikeRecord] {
        return try await APIClient.shared.request("/interactions/saved", userId: userId)
    }

    func recordVisit(locationId: String, userId: String, removeSaved: Bool = false) async throws -> InteractionMessage {
        let suffix = removeSaved ? "?remove_saved=true" : ""
        return try await APIClient.shared.request("/interactions/visit/\(locationId)\(suffix)", method: "POST", userId: userId)
    }

    func getVisits(userId: String) async throws -> [VisitRecord] {
        return try await APIClient.shared.request("/interactions/visits", userId: userId)
    }
}
