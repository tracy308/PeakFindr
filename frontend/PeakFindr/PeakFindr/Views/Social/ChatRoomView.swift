
import SwiftUI

struct ChatRoomView: View {
    @EnvironmentObject var authVM: AuthViewModel
    let location: LocationResponse

    @State private var messages: [ChatMessageResponse] = []
    @State private var text: String = ""
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(messages) { m in
                            let isUser = m.user_id == authVM.userId
                            HStack {
                                if isUser { Spacer() }
                                Text(m.message)
                                    .padding(10)
                                    .background(isUser ? Color(red: 170/255, green: 64/255, blue: 57/255) : Color(.systemGray6))
                                    .foregroundColor(isUser ? .white : .primary)
                                    .cornerRadius(12)
                                if !isUser { Spacer() }
                            }
                            .id(m.id)
                        }
                    }.padding()
                }
                .onChange(of: messages.count) { _ in
                    if let last = messages.last?.id {
                        withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                    }
                }
            }

            Divider()

            HStack(spacing: 8) {
                TextField("Type a message", text: $text)
                    .padding(10).background(Color(.systemGray6)).cornerRadius(999)
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
            .padding(.horizontal).padding(.vertical, 8)
        }
        .navigationTitle(location.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await refresh(); startPolling() }
        .onDisappear { stopPolling() }
    }

    private func refresh() async {
        guard let uid = authVM.userId else { return }
        messages = (try? await ChatService.shared.getMessages(userId: uid, locationId: location.id)) ?? []
    }

    private func send() async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let uid = authVM.userId else { return }
        _ = try? await ChatService.shared.sendMessage(userId: uid, locationId: location.id, message: trimmed)
        text = ""
        await refresh()
    }

    private func startPolling() {
        stopPolling()
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            Task { await refresh() }
        }
    }

    private func stopPolling() {
        timer?.invalidate()
        timer = nil
    }
}
