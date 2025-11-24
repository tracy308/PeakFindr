import Foundation

final class ChatBotService {
    static let shared = ChatBotService()
    private init() {}

    func askBot(locationId: String, message: String, history: [BotTurn], userId: String) async throws -> ChatBotReply {
        let request = ChatBotRequest(message: message, history: history)
        return try await APIClient.shared.request("/chatbot/\(locationId)", method: "POST", body: request, userId: userId)
    }
}

struct ChatBotRequest: Codable {
    let message: String
    let history: [BotTurn]
}
