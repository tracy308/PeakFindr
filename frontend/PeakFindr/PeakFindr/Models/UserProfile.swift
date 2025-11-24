
import Foundation

struct UserProfile {
    var name: String
    var email: String
    var level: Int
    var points: Int
    var visitsCount: Int
    var reviewsCount: Int
    var streakDays: Int
    var recentVisits: [VisitRecord]

    static func empty() -> UserProfile {
        UserProfile(
            name: "",
            email: "",
            level: 1,
            points: 0,
            visitsCount: 0,
            reviewsCount: 0,
            streakDays: 0,
            recentVisits: []
        )
    }
}
