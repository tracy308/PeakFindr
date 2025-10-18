//
//  SocialHub.swift
//  playground
//
//  Created by Wong Nixon on 18/10/2025.
//

import SwiftUI

struct ChatCreation {
    let id: String
    let category: String
    let userEmail: String
    let createdDate: Date
}

struct Category {
    let id: String
    let name: String
    let icon: CategoryIcon
    let gradient: [Color]
    
    enum CategoryIcon {
        case system(String)
        case emoji(String)
    }
}

let categories: [Category] = [
    Category(id: "general", name: "General Chat", icon: .system("message"), gradient: [Color.gray, Color.gray.opacity(0.7)]),
    Category(id: "food", name: "Food Adventures", icon: .emoji("🍜"), gradient: [Color.orange, Color.red]),
    Category(id: "sightseeing", name: "Sightseeing", icon: .emoji("📸"), gradient: [Color.blue, Color.indigo]),
    Category(id: "hiking", name: "Hiking Trails", icon: .emoji("⛰️"), gradient: [Color.green, Color.green.opacity(0.7)]),
    Category(id: "culture", name: "Cultural Spots", icon: .emoji("🎭"), gradient: [Color.purple, Color.pink]),
    Category(id: "temples", name: "Temples", icon: .emoji("🏯"), gradient: [Color.yellow, Color.orange]),
    Category(id: "hidden_gems", name: "Hidden Gems", icon: .emoji("💎"), gradient: [Color.red, Color.pink])
]

struct SocialHubView: View {
    @State private var messages: [ChatCreation] = [
        // Dummy data for demonstration
        ChatCreation(id: "1", category: "general", userEmail: "user1@example.com", createdDate: Date()),
        ChatCreation(id: "2", category: "food", userEmail: "user2@example.com", createdDate: Date().addingTimeInterval(-3600)),
        ChatCreation(id: "3", category: "hiking", userEmail: "user3@example.com", createdDate: Date().addingTimeInterval(-80000)),
        ChatCreation(id: "4", category: "general", userEmail: "user2@example.com", createdDate: Date().addingTimeInterval(-10000)),
        // Add more as needed
    ]
    
    func getCategoryStats(categoryId: String) -> (totalMessages: Int, uniqueUsers: Int, recentCount: Int) {
        let categoryMessages = messages.filter { $0.category == categoryId }
        let uniqueUsers = Set(categoryMessages.map { $0.userEmail }).count
        let recentCount = categoryMessages.filter {
            let dayAgo = Date().addingTimeInterval(-24 * 60 * 60)
            return $0.createdDate > dayAgo
        }.count
        return (categoryMessages.count, uniqueUsers, recentCount)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Hero Section
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.purple, Color.pink]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(height: 160)
                    .edgesIgnoringSafeArea(.top)
                VStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.pink.opacity(0.7))
                    Text("Social Hub")
                        .font(.largeTitle).bold()
                        .foregroundColor(.white)
                    Text("Connect with explorers and plan adventures together")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            }
            
            ScrollView {
                VStack(spacing: 24) {
                    // Category Rooms Header
                    HStack {
                        Text("Chat Rooms")
                            .font(.title2).bold()
                            .foregroundColor(.gray)
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.caption)
                            Text("\(messages.count) Total Messages")
                                .font(.caption)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Category Rooms Grid
                    VStack(spacing: 16) {
                        ForEach(categories, id: \.id) { category in
                            let stats = getCategoryStats(categoryId: category.id)
                            NavigationLink(destination: ChatRoomView(category: category)) {
                                VStack(spacing: 0) {
                                    LinearGradient(gradient: Gradient(colors: category.gradient), startPoint: .leading, endPoint: .trailing)
                                        .frame(height: 6)
                                    VStack(spacing: 12) {
                                        HStack {
                                            // Icon
                                            if case .system(let iconName) = category.icon {
                                                ZStack {
                                                    LinearGradient(gradient: Gradient(colors: category.gradient), startPoint: .topLeading, endPoint: .bottomTrailing)
                                                        .frame(width: 48, height: 48)
                                                        .cornerRadius(12)
                                                    Image(systemName: iconName)
                                                        .font(.system(size: 24))
                                                        .foregroundColor(.white)
                                                }
                                            } else if case .emoji(let emoji) = category.icon {
                                                Text(emoji)
                                                    .font(.system(size: 36))
                                                    .frame(width: 48, height: 48)
                                            }
                                            VStack(alignment: .leading) {
                                                Text(category.name)
                                                    .font(.headline)
                                                    .foregroundColor(.gray)
                                                Text("Join the conversation")
                                                    .font(.caption)
                                                    .foregroundColor(.gray.opacity(0.7))
                                            }
                                            Spacer()
                                            Text("\(stats.uniqueUsers) \(stats.uniqueUsers == 1 ? "member" : "members")")
                                                .font(.caption)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(Color.gray.opacity(0.1))
                                                .cornerRadius(12)
                                        }
                                        HStack(spacing: 16) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "message")
                                                    .font(.caption)
                                                Text("\(stats.totalMessages) messages")
                                                    .font(.caption)
                                            }
                                            if stats.recentCount > 0 {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "sparkles")
                                                        .font(.caption)
                                                        .foregroundColor(.green)
                                                    Text("\(stats.recentCount) in last 24h")
                                                        .font(.caption)
                                                        .foregroundColor(.green)
                                                }
                                            }
                                        }
                                    }
                                    .padding()
                                }
                                .background(Color.white)
                                .cornerRadius(20)
                                .shadow(radius: 4)
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.top, 24)
            }
        }
        .background(Color.gray.opacity(0.08))
        
    }
}

// Dummy ChatRoomView for navigation
struct ChatRoomView: View {
    let category: Category
    var body: some View {
        Text("Chat Room: \(category.name)")
            .font(.largeTitle)
    }
}

#Preview {
    LayoutView {
        SocialHubView()
    }
}
