
import Foundation

struct ChatRoom: Identifiable, Equatable {
    let id: UUID
    let name: String
    let category: LocationCategory

    static let general = ChatRoom(id: UUID(), name: "General Chat", category: .all)
}

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let text: String
    let isUser: Bool
    let timestamp: Date
}
