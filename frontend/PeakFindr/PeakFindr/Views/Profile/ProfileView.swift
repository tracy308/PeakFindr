
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var profileVM: ProfileViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection
                statsSection
                recentVisitsSection
            }
        }
        .background(Color(.systemGray6))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Profile")
                    .font(.headline)
            }
        }
    }

    private var headerSection: some View {
        let profile = profileVM.profile

        return ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [
                    Color(red: 193/255, green: 66/255, blue: 54/255),
                    Color(red: 212/255, green: 93/255, blue: 58/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 260)

            VStack(spacing: 12) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text(String(profile.name.prefix(1)))
                            .font(.title)
                            .foregroundColor(Color(red: 193/255, green: 66/255, blue: 54/255))
                    )

                Text(profile.name)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)

                Text(profile.email)
                    .foregroundColor(.white.opacity(0.9))

                HStack(spacing: 16) {
                    Capsule()
                        .stroke(Color.white.opacity(0.7), lineWidth: 1)
                        .frame(height: 34)
                        .overlay(
                            HStack {
                                Image(systemName: "rosette")
                                Text("Level \(profile.level)")
                            }
                            .foregroundColor(.white)
                        )

                    Capsule()
                        .stroke(Color.white.opacity(0.7), lineWidth: 1)
                        .frame(height: 34)
                        .overlay(
                            HStack {
                                Image(systemName: "star")
                                Text("\(profile.points) points")
                            }
                            .foregroundColor(.white)
                        )
                }
                .padding(.top, 4)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Progress to level \(profile.level + 1)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                        Spacer()
                        Text("\(profile.points % 100)/100")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                    }

                    ProgressView(value: profileVM.progressToNextLevel)
                        .tint(.white)
                }
                .padding(.horizontal, 32)
                .padding(.top, 4)

                Button {
                    // log out placeholder
                } label: {
                    Text("Log out")
                        .font(.body)
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
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .padding(.top, 40)
        }
    }

    private var statsSection: some View {
        let profile = profileVM.profile

        return HStack(spacing: 12) {
            StatCardView(
                iconName: "mappin.and.ellipse",
                title: "Visited",
                value: profile.visits.count
            )
            StatCardView(
                iconName: "star.fill",
                title: "Reviews",
                value: profile.reviewsCount
            )
            StatCardView(
                iconName: "chart.line.uptrend.xyaxis",
                title: "Streak",
                value: profile.streakDays
            )
        }
        .padding(.horizontal)
        .padding(.top, 16)
    }

    private var recentVisitsSection: some View {
        let visits = profileVM.profile.visits

        return VStack(alignment: .leading, spacing: 8) {
            Text("Recent Visits")
                .font(.headline)

            if visits.isEmpty {
                Text("No visits yet. Start exploring!")
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            } else {
                VStack(spacing: 12) {
                    ForEach(visits) { visit in
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(visit.locationName)
                                    .bold()
                                Text(visit.date, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("+\(visit.pointsEarned) points")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.12))
                                .foregroundColor(.green)
                                .cornerRadius(999)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(14)
                        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
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
            Text("\(value)")
                .font(.title2)
                .bold()
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
