
import Foundation
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = [
        ChatMessage(id: UUID(), text: "Welcome to Peakfindr Social!", isUser: false, timestamp: Date())
    ]

    func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        messages.append(ChatMessage(id: UUID(), text: trimmed, isUser: true, timestamp: Date()))
    }
}
