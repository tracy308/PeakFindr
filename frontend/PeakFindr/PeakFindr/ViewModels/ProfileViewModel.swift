
import Foundation
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile

    init(profile: UserProfile = .sample()) {
        self.profile = profile
        NotificationCenter.default.addObserver(forName: .reviewSubmitted, object: nil, queue: .main) { [weak self] note in
            guard let self, let location = note.object as? Location else { return }
            self.handleVisit(location: location)
        }
    }

    private func handleVisit(location: Location) {
        let visit = VisitRecord(id: UUID(), locationName: location.name, date: Date(), pointsEarned: 10)
        profile.visits.insert(visit, at: 0)
        profile.points += visit.pointsEarned
        profile.reviewsCount += 1
        profile.level = max(1, profile.points / 100 + 1)
    }

    var progressToNextLevel: Double {
        let base = max(0, (profile.level - 1) * 100)
        let into = max(0, profile.points - base)
        return min(1.0, Double(into) / 100.0)
    }
}
