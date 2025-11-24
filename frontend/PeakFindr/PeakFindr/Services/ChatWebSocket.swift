import Foundation

final class LocationChatWebSocket: ObservableObject {
    private var task: URLSessionWebSocketTask?
    private let decoder = JSONDecoder()

    var onMessage: ((ChatMessageResponse) -> Void)?

    func connect(locationId: String) {
        disconnect()
        guard let url = APIClient.shared.webSocketURL(path: "/chat/\(locationId)/ws") else { return }
        task = URLSession.shared.webSocketTask(with: url)
        task?.resume()
        listen()
    }

    func send(text: String, userId: String) {
        guard let task else { return }
        let payload: [String: String] = ["text": text, "user_id": userId]
        guard let data = try? JSONSerialization.data(withJSONObject: payload) else { return }
        task.send(.data(data)) { error in
            if let error { print("WebSocket send error: \(error)") }
        }
    }

    private func listen() {
        task?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                print("WebSocket receive error: \(error)")
            case .success(let message):
                switch message {
                case .data(let data):
                    if let decoded = try? decoder.decode(ChatMessageResponse.self, from: data) {
                        DispatchQueue.main.async { self.onMessage?(decoded) }
                    }
                case .string(let text):
                    if let data = text.data(using: .utf8),
                       let decoded = try? decoder.decode(ChatMessageResponse.self, from: data) {
                        DispatchQueue.main.async { self.onMessage?(decoded) }
                    }
                @unknown default:
                    break
                }
            }
            self.listen()
        }
    }

    func disconnect() {
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
    }
}
