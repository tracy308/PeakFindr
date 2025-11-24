
import Foundation

struct InteractionMessage: Codable {
    let message: String
    let visit_id: String?
    let points_awarded: Int?
    let total_points: Int?
    let level: Int?
}

struct LikeRecord: Codable, Identifiable {
    let id: Int?
    let user_id: String
    let location_id: String
    let created_at: String
}

struct VisitRecord: Codable, Identifiable, Equatable {
    let id: Int
    let user_id: String?
    let location_id: String?
    let created_at: String
    let location_name: String?
    let points_earned: Int?
}
