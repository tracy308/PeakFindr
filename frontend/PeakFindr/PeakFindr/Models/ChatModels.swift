
import Foundation

struct ChatMessageRequest: Codable {
    let message: String
}

struct ChatMessageResponse: Codable, Identifiable, Equatable {
    let id: Int
    let location_id: String
    let user_id: String?
    let message: String
    let created_at: String
    let username: String?
}
