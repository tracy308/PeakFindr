//
//  Profile.swift
//  playground
//
//  Created by Wong Nixon on 18/10/2025.
//

import SwiftUI

struct User {
    let fullName: String
    let email: String
    let level: Int
    let points: Int
    let currentStreak: Int
}

struct Visit: Identifiable {
    let id: String
    let locationName: String
    let visitDate: Date
}

struct ProfileView: View {
    @State private var user: User? = nil
    @State private var visits: [Visit] = []
    @State private var reviews: [Review] = []
    @State private var isLoading = true

    func loadProfileData() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.user = User(
                fullName: "Alex Wong",
                email: "alex.wong@example.com",
                level: 3,
                points: 250,
                currentStreak: 5
            )
            self.visits = [
                Visit(id: "1", locationName: "Victoria Peak", visitDate: Date()),
                Visit(id: "2", locationName: "Tsim Sha Tsui Promenade", visitDate: Date().addingTimeInterval(-86400)),
            ]
            self.reviews = [
                Review(id: "1", user: "Alex Wong", locationName: "Victoria Peak", rating: 5.0, comment: "Amazing view!", date: Date()),
                Review(id: "2", user: "Alex Wong", locationName: "Tsim Sha Tsui Promenade", rating: 4.5, comment: "Great for photos.", date: Date().addingTimeInterval(-86400)),
            ]
            self.isLoading = false
        }
    }

    func handleLogout() {
        user = nil
    }

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if let user = user {
                ScrollView {
                    VStack(spacing: 0) {
                        ProfileHeader(user: user, handleLogout: handleLogout)
                        StatsCards(visits: visits, reviews: reviews, user: user)
                        RecentVisits(visits: visits)
                    }
                }
                .background(Color.gray.opacity(0.08))
                .ignoresSafeArea(edges: .top)
            } else {
                LoginPrompt()
            }
        }
        .onAppear { loadProfileData() }
    }
}

private struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .red))
                .scaleEffect(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.08))
    }
}

private struct LoginPrompt: View {
    var body: some View {
        VStack {
            Text("Please log in to view your profile")
                .foregroundColor(.gray)
                .padding(.bottom, 16)
            Button(action: {
                // Implement login redirect
            }) {
                Text("Log In")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.08))
    }
}

private struct ProfileHeader: View {
    let user: User
    let handleLogout: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.red, .orange]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 260)
            .edgesIgnoringSafeArea(.top)
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 96, height: 96)
                        .shadow(radius: 8)
                    Text(String(user.fullName.prefix(1)).uppercased())
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.red)
                }
                Text(user.fullName)
                    .font(.title).bold()
                    .foregroundColor(.white)
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                HStack(spacing: 16) {
                    HStack {
                        Image(systemName: "rosette")
                            .foregroundColor(.white)
                        Text("Level \(user.level)")
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(12)
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("\(user.points) Points")
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(12)
                }
                LevelProgress(level: user.level, points: user.points)
                Button(action: handleLogout) {
                    HStack {
                        Image(systemName: "arrow.right.square")
                        Text("Log Out")
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.top, 8)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 40)
        }
    }
}

private struct LevelProgress: View {
    let level: Int
    let points: Int

    var body: some View {
        let pointsForNextLevel = level * 100
        let progress = Double(points % 100) / Double(pointsForNextLevel)
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Progress to Level \(level + 1)")
                    .font(.caption)
                    .foregroundColor(.white)
                Spacer()
                Text("\(points % 100)/\(pointsForNextLevel)")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 10)
                Capsule()
                    .fill(Color.white)
                    .frame(width: CGFloat(progress) * 200, height: 10)
                    .animation(.easeInOut, value: progress)
            }
            .frame(width: 200)
        }
    }
}

private struct StatsCards: View {
    let visits: [Visit]
    let reviews: [Review]
    let user: User

    var body: some View {
        HStack(spacing: 16) {
            StatCard(icon: "mappin", color: .red, value: visits.count, label: "Places Visited")
            StatCard(icon: "star.fill", color: .yellow, value: reviews.count, label: "Reviews")
            StatCard(icon: "chart.line.uptrend.xyaxis", color: .green, value: user.currentStreak, label: "Day Streak")
        }
        .padding(.horizontal)
        .offset(y: -40)
    }
}

private struct RecentVisits: View {
    let visits: [Visit]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Visits")
                .font(.title2).bold()
                .padding(.top, 8)
            if visits.isEmpty {
                VStack {
                    Image(systemName: "mappin")
                        .resizable()
                        .frame(width: 64, height: 64)
                        .foregroundColor(.gray)
                    Text("No visits yet")
                        .foregroundColor(.gray)
                    Button(action: {
                        // Implement navigation to Discover
                    }) {
                        Text("Start Exploring")
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ForEach(visits.prefix(10)) { visit in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(visit.locationName)
                                .font(.headline)
                            Text("Visited on \(visit.visitDate, formatter: dateFormatter)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Text("+10 pts")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.1))
                            .foregroundColor(.green)
                            .cornerRadius(12)
                    }
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 32)
    }
}

struct StatCard: View {
    let icon: String
    let color: Color
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
            Text("\(value)")
                .font(.title).bold()
                .foregroundColor(.black)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 4)
    }
}

let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

#Preview {
    LayoutView {
      ProfileView()
  }
}
