import Foundation

struct BotTurn: Codable {
    let role: String
    let content: String
}

struct ChatBotReply: Codable {
    let reply: String
    let location_id: String
}

struct BotMessage: Identifiable, Equatable {
    enum Role {
        case user
        case bot
    }

    let id = UUID()
    let role: Role
    let text: String
}
