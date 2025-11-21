
import SwiftUI

struct ChatRoomView: View {
    let room: ChatRoom
    @StateObject private var vm = ChatViewModel()
    @State private var messageText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(vm.messages) { message in
                            HStack {
                                if message.isUser { Spacer() }
                                Text(message.text)
                                    .padding(10)
                                    .background(message.isUser ? Color(red: 170/255, green: 64/255, blue: 57/255) : Color(.systemGray6))
                                    .foregroundColor(message.isUser ? .white : .primary)
                                    .cornerRadius(12)
                                if !message.isUser { Spacer() }
                            }
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: vm.messages.count) { _ in
                    if let lastID = vm.messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastID, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            HStack(spacing: 8) {
                TextField("Type a message", text: $messageText)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(999)

                Button {
                    vm.send(messageText)
                    messageText = ""
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
            .background(Color(.systemBackground))
        }
        .navigationTitle(room.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
