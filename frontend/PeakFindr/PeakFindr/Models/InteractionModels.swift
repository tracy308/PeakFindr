
import Foundation

struct InteractionMessage: Codable {
    let message: String
    let visit_id: String?
}

struct LikeRecord: Codable, Identifiable {
    let id: Int?
    let user_id: String
    let location_id: String
    let created_at: String
}

struct VisitRecord: Codable, Identifiable, Equatable {
    let id: Int
    let user_id: String
    let location_id: String
    let created_at: String
}
