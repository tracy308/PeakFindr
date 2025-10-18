//
//  Chat.swift
//  playground
//
//  Created by Wong Nixon on 19/10/2025.
//

import SwiftUI

struct ChatMessage: Identifiable {
    let id: String
    let userEmail: String
    let userName: String
    let message: String
    let imageUrl: String?
    let createdDate: Date
}

struct ChatView: View {
    @State private var messages: [ChatMessage] = [
        ChatMessage(id: "1", userEmail: "alex@example.com", userName: "Alex", message: "Hello!", imageUrl: nil, createdDate: Date()),
        ChatMessage(id: "2", userEmail: "bob@example.com", userName: "Bob", message: "Hi Alex!", imageUrl: nil, createdDate: Date().addingTimeInterval(-60))
    ]
    @State private var message: String = ""
    @State private var imageUrl: String = ""
    @State private var userEmail: String = "alex@example.com"
    @State private var userName: String = "Alex"
    @FocusState private var isInputFocused: Bool
    @Environment(\.openURL) private var openURL

    var category: String = "general"
    var categoryNames: [String: String] = [
        "general": "General Chat",
        "food": "Food Adventures",
        "sightseeing": "Sightseeing",
        "hiking": "Hiking Trails",
        "culture": "Cultural Spots",
        "temples": "Temples",
        "hidden_gems": "Hidden Gems"
    ]

    var uniqueUsers: Int {
        Set(messages.map { $0.userEmail }).count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    // Navigation logic to go back
                }) {
                    Image(systemName: "arrow.left")
                        .font(.title2)
                }
                VStack(alignment: .leading) {
                    Text(categoryNames[category] ?? category.capitalized)
                        .font(.headline)
                    HStack(spacing: 4) {
                        Image(systemName: "person.2")
                            .font(.caption)
                        Text("\(uniqueUsers) active")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
            }
            .padding()
            .background(Color.white)
            .overlay(Rectangle().frame(height: 1).foregroundColor(Color.gray.opacity(0.1)), alignment: .bottom)

            // Messages
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(messages.sorted(by: { $0.createdDate < $1.createdDate })) { msg in
                            ChatMessageBubble(
                                message: msg,
                                isOwnMessage: msg.userEmail == userEmail,
                                openURL: openURL
                            )
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal)
                    .background(LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.05), Color.white]), startPoint: .top, endPoint: .bottom))
                    .onChange(of: messages.count) {
                        if let last = messages.last {
                            withAnimation {
                                scrollProxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }

            // Input Area
            VStack(spacing: 8) {
                if !imageUrl.isEmpty {
                    HStack {
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Color.gray.opacity(0.2)
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        Button(action: { imageUrl = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.bottom, 4)
                }
                HStack(spacing: 8) {
                    Button(action: {
                        // Implement image picker logic here
                        // For demo, just set a sample image URL
                        imageUrl = "https://placekitten.com/200/200"
                    }) {
                        Image(systemName: "photo")
                            .font(.title2)
                    }
                    .buttonStyle(.bordered)
                    TextField("Type a message...", text: $message)
                        .textFieldStyle(.roundedBorder)
                        .focused($isInputFocused)
                        .onSubmit { sendMessage() }
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && imageUrl.isEmpty ? Color.gray : Color.red)
                            .clipShape(Circle())
                    }
                    .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && imageUrl.isEmpty)
                }
            }
            .padding()
            .background(Color.white)
            .overlay(Rectangle().frame(height: 1).foregroundColor(Color.gray.opacity(0.1)), alignment: .top)
        }
        .background(Color.gray.opacity(0.08))
    }

    func sendMessage() {
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !imageUrl.isEmpty else { return }
        let newMsg = ChatMessage(
            id: UUID().uuidString,
            userEmail: userEmail,
            userName: userName,
            message: message.trimmingCharacters(in: .whitespacesAndNewlines),
            imageUrl: imageUrl.isEmpty ? nil : imageUrl,
            createdDate: Date()
        )
        messages.append(newMsg)
        message = ""
        imageUrl = ""
        isInputFocused = true
    }
}

struct ChatMessageBubble: View {
    let message: ChatMessage
    let isOwnMessage: Bool
    let openURL: OpenURLAction

    var body: some View {
        HStack {
            if isOwnMessage { Spacer() }
            VStack(alignment: isOwnMessage ? .trailing : .leading, spacing: 2) {
                if !isOwnMessage {
                    Text(message.userName)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                VStack(alignment: .leading, spacing: 4) {
                    if !message.message.isEmpty {
                        Text(message.message)
                            .font(.body)
                            .foregroundColor(isOwnMessage ? .white : .black)
                    }
                    if let url = message.imageUrl, let imageURL = URL(string: url) {
                        Button(action: { openURL(imageURL) }) {
                            AsyncImage(url: imageURL) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Color.gray.opacity(0.2)
                            }
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(
                    Group {
                        if isOwnMessage {
                            LinearGradient(gradient: Gradient(colors: [Color.red, Color.pink]), startPoint: .leading, endPoint: .trailing)
                        } else {
                            Color.white
                        }
                    }
                )
                .padding(10)
                .cornerRadius(16)
                .shadow(color: isOwnMessage ? Color.red.opacity(0.1) : Color.gray.opacity(0.1), radius: 2)

                Text(message.createdDate, style: .time)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            if !isOwnMessage { Spacer() }
        }
        .id(message.id)
    }
}

#Preview {
    ChatView()
}
