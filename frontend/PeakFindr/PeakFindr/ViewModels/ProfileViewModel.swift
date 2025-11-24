import Foundation
internal import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile = .empty()
    @Published var error: String? = nil
    @Published var isLoading = false

    func refreshAll(userId: String? = nil, username: String? = nil, email: String? = nil) {
        guard let userId else { return }
        Task { await loadStats(userId: userId, username: username, email: email) }
    }

    private func loadStats(userId: String, username: String?, email: String?) async {
        isLoading = true
        error = nil
        do {
            let response = try await UserService.shared.profile(userId: userId)
            profile.name = response.name
            profile.email = response.email
            profile.level = response.level
            profile.points = response.points
            profile.visitsCount = response.visits.count
            profile.reviewsCount = response.reviews_count
            profile.streakDays = response.streak_days
            profile.recentVisits = response.visits.prefix(5).map { visit in
                VisitRecord(
                    id: visit.id,
                    user_id: userId,
                    location_id: visit.location_name,
                    created_at: visit.date,
                    location_name: visit.location_name,
                    points_earned: visit.points_earned
                )
            }
        } catch let err {
            error = err.localizedDescription
        }
        profile.name = username ?? profile.name
        profile.email = email ?? profile.email
        isLoading = false
    }
}
