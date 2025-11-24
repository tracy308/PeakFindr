import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    var onLogout: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                statsSection
                recentVisitsSection
            }
            .padding(.bottom, 20)
        }
        .background(Color(.systemGray6))
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            profileVM.refreshAll(userId: authVM.userId, username: authVM.username, email: authVM.email)
        }
    }

    private var headerSection: some View {
        let p = profileVM.profile
        let progress = min(Double(p.points % 100) / 100.0, 1.0)
        let nextLevel = p.level + 1
        return ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color(red: 193/255, green: 66/255, blue: 54/255),
                         Color(red: 212/255, green: 93/255, blue: 58/255)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .frame(height: 320)

            VStack(spacing: 12) {
                Circle()
                    .fill(Color.white).frame(width: 80, height: 80)
                    .overlay(Text(String((p.name.isEmpty ? authVM.username : p.name).prefix(1))).font(.title))

                Text(p.name.isEmpty ? authVM.username : p.name)
                    .font(.title2).bold().foregroundColor(.white)
                Text(p.email.isEmpty ? authVM.email : p.email)
                    .foregroundColor(.white.opacity(0.9))

                HStack(spacing: 12) {
                    badgeView(title: "Level", value: "\(p.level)", systemImage: "arrow.up.circle.fill")
                    badgeView(title: "Points", value: "\(p.points)", systemImage: "star.fill")
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Progress to level \(nextLevel)")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.footnote)
                        Spacer()
                        Text("\(p.points % 100)/100")
                            .foregroundColor(.white)
                            .font(.footnote).bold()
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.2))
                            Capsule()
                                .fill(Color.yellow)
                                .frame(width: CGFloat(progress) * geo.size.width)
                        }
                    }
                    .frame(height: 10)
                }
                .padding(.horizontal)

                Button { onLogout() } label: {
                    Text("Log out")
                        .padding(.horizontal, 32)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 999)
                                .stroke(Color.white.opacity(0.7), lineWidth: 1)
                        )
                        .cornerRadius(999)
                }
                .padding(.top, 4)
                .padding(.bottom, 12)
            }
            .padding(.top, 40)
        }
    }

    private func badgeView(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage).foregroundColor(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundColor(.white.opacity(0.8))
                Text(value).font(.headline).foregroundColor(.white)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Color.white.opacity(0.12))
        .cornerRadius(12)
    }

    private var statsSection: some View {
        let p = profileVM.profile
        return HStack(spacing: 12) {
            StatCardView(iconName: "mappin.and.ellipse", title: "Visited", value: p.visitsCount)
            StatCardView(iconName: "star.fill", title: "Reviews", value: p.reviewsCount)
            StatCardView(iconName: "flame.fill", title: "Streak", value: p.streakDays)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var recentVisitsSection: some View {
        let visits = profileVM.profile.recentVisits
        return VStack(alignment: .leading, spacing: 12) {
            Text("Recent Visits").font(.headline)

            if visits.isEmpty {
                Text("No visits yet. Start exploring!")
                    .foregroundColor(.secondary).padding(.top, 4)
            } else {
                VStack(spacing: 12) {
                    ForEach(visits) { visit in
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(visit.location_name ?? "Unknown location")
                                    .bold()
                                Text(visit.created_at)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if let pts = visit.points_earned {
                                Text("+\(pts) points")
                                    .font(.subheadline).foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(14)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                }
            }
        }
        .padding()
    }
}

struct StatCardView: View {
    let iconName: String
    let title: String
    let value: Int
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(Color(red: 170/255, green: 64/255, blue: 57/255))
            Text("\(value)").font(.title2).bold()
            Text(title).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
