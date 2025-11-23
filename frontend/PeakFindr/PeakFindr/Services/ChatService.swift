
import Foundation

final class ChatService {
    static let shared = ChatService()
    private init() {}

    func getMessages(userId: String, locationId: String) async throws -> [ChatMessageResponse] {
        return try await APIClient.shared.request("/chat/\(locationId)", userId: userId)
    }

    func sendMessage(userId: String, locationId: String, message: String) async throws -> ChatMessageResponse {
        let body = ChatMessageRequest(message: message)
        return try await APIClient.shared.request("/chat/\(locationId)", method: "POST", body: body, userId: userId)
    }
}
