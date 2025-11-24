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
            let visits = try await InteractionService.shared.getVisits(userId: userId)
            profile.visitsCount = visits.count
            profile.recentVisits = Array(visits.prefix(5))
        } catch let err {
            error = err.localizedDescription
        }
        profile.name = username ?? profile.name
        profile.email = email ?? profile.email
        isLoading = false
    }
}
