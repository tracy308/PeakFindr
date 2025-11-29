import SwiftUI

struct ChatRoomView: View {
    @EnvironmentObject var authVM: AuthViewModel
    let location: LocationResponse

    @State private var messages: [ChatMessageResponse] = []
    @State private var text: String = ""
    @StateObject private var socket = LocationChatWebSocket()

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(messages) { m in
                            let isUser = m.user_id == authVM.userId
                            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                                Text(m.username ?? "Explorer")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                HStack {
                                    if isUser { Spacer() }
                                    Text(m.message)
                                        .padding(10)
                                        .background(isUser ? Color(red: 170/255, green: 64/255, blue: 57/255) : Color(.systemGray6))
                                        .foregroundColor(isUser ? .white : .primary)
                                        .cornerRadius(12)
                                    if !isUser { Spacer() }
                                }
                            }
                            .id(m.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) {
                    if let last = messages.last?.id {
                        withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                    }
                }
            }

            Divider()

            HStack(spacing: 8) {
                TextField("Type a message", text: $text)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(999)
                Button {
                    Task { await send() }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .padding(10)
                        .background(Color(red: 170/255, green: 64/255, blue: 57/255))
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .navigationTitle(location.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadHistory()
            connectSocket()
        }
        .onDisappear { socket.disconnect() }
    }

    private func loadHistory() async {
        guard let uid = authVM.userId else { return }
        messages = (try? await ChatService.shared.getMessages(userId: uid, locationId: location.id)) ?? []
    }

    private func connectSocket() {
        guard let uid = authVM.userId else { return }
        socket.onMessage = { incoming in
            if !messages.contains(where: { $0.id == incoming.id }) {
                messages.append(incoming)
            }
        }
        socket.connect(locationId: location.id, userId: uid)
    }

    private func send() async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let uid = authVM.userId else { return }
        do {
            // Persist first so we always render the sent message even if the socket misses it
            let created = try await ChatService.shared.sendMessage(userId: uid, locationId: location.id, message: trimmed)
            if !messages.contains(where: { $0.id == created.id }) {
                messages.append(created)
            }
            socket.send(text: trimmed, userId: uid)
            text = ""
        } catch {
            print("Chat send error: \(error)")
        }
    }
}
