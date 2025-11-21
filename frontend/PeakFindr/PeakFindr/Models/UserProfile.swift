
import Foundation

struct VisitRecord: Identifiable, Equatable {
    let id: UUID
    let locationName: String
    let date: Date
    let pointsEarned: Int
}

struct UserProfile {
    var name: String
    var email: String
    var level: Int
    var points: Int
    var visits: [VisitRecord]
    var reviewsCount: Int
    var streakDays: Int

    static func sample() -> UserProfile {
        UserProfile(
            name: "Alex Wong",
            email: "alexwong@gmail.com",
            level: 1,
            points: 10,
            visits: [
                VisitRecord(id: UUID(), locationName: "The Peak", date: Date(timeIntervalSinceNow: -60 * 60 * 24 * 5), pointsEarned: 10)
            ],
            reviewsCount: 1,
            streakDays: 1
        )
    }
}
