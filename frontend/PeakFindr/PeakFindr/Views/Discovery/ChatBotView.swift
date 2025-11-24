import SwiftUI

struct ChatBotView: View {
    @EnvironmentObject var authVM: AuthViewModel
    let location: LocationResponse

    @State private var messages: [BotMessage] = []
    @State private var text: String = ""
    @State private var isSending = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(messages) { msg in
                            HStack {
                                if msg.role == .bot { botBubble(msg.text) }
                                else { Spacer(); userBubble(msg.text) }
                            }
                            .id(msg.id)
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
                TextField("Ask about this place", text: $text)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(999)
                Button {
                    Task { await send() }
                } label: {
                    if isSending {
                        ProgressView().progressViewStyle(.circular)
                            .frame(width: 24, height: 24)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .frame(width: 24, height: 24)
                    }
                }
                .padding(10)
                .background(Color(red: 170/255, green: 64/255, blue: 57/255))
                .foregroundColor(.white)
                .clipShape(Circle())
                .disabled(isSending)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .navigationTitle("AI Guide")
        .navigationBarTitleDisplayMode(.inline)
        .task { seedGreeting() }
    }

    private func seedGreeting() {
        messages = [
            BotMessage(role: .bot, text: "Hi, I'm your tour guide for \(location.name). How can I help you?")
        ]
    }

    private func send() async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let uid = authVM.userId else { return }
        let userMessage = BotMessage(role: .user, text: trimmed)
        messages.append(userMessage)
        text = ""
        isSending = true
        do {
            let reply = try await ChatBotService.shared.askBot(
                locationId: location.id,
                message: trimmed,
                history: botHistory(),
                userId: uid
            )
            messages.append(BotMessage(role: .bot, text: reply.reply))
        } catch {
            messages.append(BotMessage(role: .bot, text: "Sorry, I couldn't reach the tour guide right now."))
        }
        isSending = false
    }

    private func botHistory() -> [BotTurn] {
        messages.map { msg in
            BotTurn(role: msg.role == .bot ? "assistant" : "user", content: msg.text)
        }
    }

    private func botBubble(_ text: String) -> some View {
        Text(text)
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func userBubble(_ text: String) -> some View {
        Text(text)
            .padding(12)
            .background(Color(red: 170/255, green: 64/255, blue: 57/255))
            .foregroundColor(.white)
            .cornerRadius(12)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }
}
