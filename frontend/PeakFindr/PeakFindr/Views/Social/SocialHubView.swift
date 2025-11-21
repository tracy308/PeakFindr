
import SwiftUI

struct SocialHubView: View {
    @State private var selectedCategory: LocationCategory = .all

    private let rooms: [ChatRoom] = [.general]

    var filteredRooms: [ChatRoom] {
        switch selectedCategory {
        case .all:
            return rooms
        default:
            return rooms.filter { $0.category == selectedCategory || $0.category == .all }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            socialHeader

            Text("Chat rooms")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 16)

            categoryFilterBar

            List {
                ForEach(filteredRooms) { room in
                    NavigationLink {
                        ChatRoomView(room: room)
                    } label: {
                        HStack {
                            Image(systemName: "bubble.left")
                                .foregroundColor(.primary)
                            Text(room.name)
                                .font(.body)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .listStyle(.plain)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Social Hub")
                    .font(.headline)
            }
        }
    }

    private var socialHeader: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 217/255, green: 85/255, blue: 122/255),
                    Color(red: 182/255, green: 74/255, blue: 174/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 170)

            VStack(spacing: 8) {
                Image(systemName: "person.2.fill")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                Text("Social Hub")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                Text("Connect with explorers and plan adventures together")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
    }

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(LocationCategory.allCases, id: \.self) { category in
                    let isSelected = selectedCategory == category
                    Button {
                        selectedCategory = category
                    } label: {
                        Text(category.title)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(isSelected ? Color(red: 170/255, green: 64/255, blue: 57/255) : Color.white)
                            .foregroundColor(isSelected ? .white : .primary)
                            .cornerRadius(999)
                            .overlay(
                                RoundedRectangle(cornerRadius: 999)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}
