//
//  TourGuide.swift
//  playground
//
//  Created by Wong Nixon on 19/10/2025.
//

import SwiftUI

struct TourGuideMessage: Identifiable {
    let id = UUID()
    let role: Role
    let content: String

    enum Role {
        case assistant
        case user
    }
}

struct TourGuideView: View {
    @State private var messages: [TourGuideMessage] = [
        TourGuideMessage(role: .assistant, content: "Hello! I'm your Hong Kong virtual tour guide. Ask me anything about Hong Kong's history, culture, hidden spots, or get recommendations for places to visit!")
    ]
    @State private var input: String = ""
    @State private var isLoading: Bool = false
    @FocusState private var isInputFocused: Bool
    @Namespace private var bottomID

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(gradient: Gradient(colors: [Color.purple, Color.pink]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 48, height: 48)
                    Image(systemName: "sparkles")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading) {
                    Text("AI Tour Guide")
                        .font(.title2).bold()
                        .foregroundColor(.white)
                    Text("Your personal Hong Kong expert")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
            }
            .padding()
            .background(LinearGradient(gradient: Gradient(colors: [Color.purple, Color.pink]), startPoint: .leading, endPoint: .trailing))

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(messages) { msg in
                            TourGuideMessageBubble(message: msg)
                        }
                        if isLoading {
                            HStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(gradient: Gradient(colors: [Color.purple, Color.pink]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "brain.head.profile")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                }
                                HStack(spacing: 4) {
                                    ForEach(0..<3) { i in
                                        Circle()
                                            .fill(Color.purple)
                                            .frame(width: 8, height: 8)
                                            .opacity(0.7)
                                            .offset(y: i == 1 ? 2 : 0)
                                            .animation(.easeInOut(duration: 0.6).repeatForever().delay(Double(i) * 0.2), value: isLoading)
                                    }
                                }
                            }
                        }
                        Color.clear.frame(height: 1).id(bottomID)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal)
                }
                .background(LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.05), Color.white]), startPoint: .top, endPoint: .bottom))
                .onChange(of: messages.count) {
                    withAnimation { proxy.scrollTo(bottomID, anchor: .bottom) }
                }
                .onChange(of: isLoading) {
                    if isLoading {
                        withAnimation { proxy.scrollTo(bottomID, anchor: .bottom) }
                    }
                }
            }

            // Input Area
            HStack(spacing: 8) {
                TextField("Ask about Hong Kong...", text: $input)
                    .textFieldStyle(.roundedBorder)
                    .focused($isInputFocused)
                    .disabled(isLoading)
                    .onSubmit { handleSend() }
                Button(action: handleSend) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(LinearGradient(gradient: Gradient(colors: [Color.purple, Color.pink]), startPoint: .leading, endPoint: .trailing))
                        .clipShape(Circle())
                }
                .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }
            .padding()
            .background(Color.white)
            .overlay(Rectangle().frame(height: 1).foregroundColor(Color.gray.opacity(0.1)), alignment: .top)
        }
        .background(Color.gray.opacity(0.08))
    }

    func handleSend() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        messages.append(TourGuideMessage(role: .user, content: trimmed))
        input = ""
        isLoading = true
        isInputFocused = false

        // Simulate AI response with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let aiResponse = aiTourGuideResponse(for: trimmed)
            messages.append(TourGuideMessage(role: .assistant, content: aiResponse))
            isLoading = false
        }
    }

    // Replace this with your actual LLM/AI API call
    func aiTourGuideResponse(for prompt: String) -> String {
        // Simple canned responses for demo
        if prompt.lowercased().contains("food") {
            return "Hong Kong is famous for its dim sum, egg tarts, and street food! Try visiting [translate:添好运] (Tim Ho Wan) for Michelin-starred dim sum, or explore the [translate:庙街夜市] (Temple Street Night Market) for local snacks."
        } else if prompt.lowercased().contains("history") {
            return "Hong Kong's history is a blend of Chinese heritage and British colonial influence. Visit the Hong Kong Museum of History in Tsim Sha Tsui for a fascinating journey through time."
        } else if prompt.lowercased().contains("hidden") {
            return "For hidden gems, check out [translate:大澳渔村] (Tai O Fishing Village) for stilt houses and pink dolphins, or the [translate:嘉咸街壁画] (Graham Street Murals) in Central for street art."
        }
        return "That's a great question! Hong Kong has so much to offer. Let me know if you want recommendations for food, culture, history, or off-the-beaten-path adventures."
    }
}

struct TourGuideMessageBubble: View {
    let message: TourGuideMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == .assistant {
                ZStack {
                    Circle()
                        .fill(LinearGradient(gradient: Gradient(colors: [Color.purple, Color.pink]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 32, height: 32)
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
            }
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                if message.role == .assistant {
                    Text(.init(message.content))
                        .font(.body)
                        .foregroundColor(.black)
                        .padding(10)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.purple.opacity(0.08), radius: 2)
                } else {
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(LinearGradient(gradient: Gradient(colors: [Color.red, Color.pink]), startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(16)
                        .shadow(color: Color.red.opacity(0.08), radius: 2)
                }
            }
            if message.role == .user {
                ZStack {
                    Circle()
                        .fill(LinearGradient(gradient: Gradient(colors: [Color.red, Color.pink]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 32, height: 32)
                    Image(systemName: "person.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
        .padding(message.role == .user ? .leading : .trailing, 40)
        .padding(.horizontal, 4)
    }
}

#Preview {
    LayoutView {
        TourGuideView()
    }
}
