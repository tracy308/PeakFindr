
import Foundation

struct Location: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let region: String
    let category: LocationCategory
    var summary: String
    let duration: String?
    let openingHours: String?
    var rating: Double
    var reviews: [Review]
    var imageName: String

    static func sampleData() -> [Location] {
        return [
            Location(
                id: UUID(),
                name: "The Peak",
                region: "HK Island",
                category: .sights,
                summary: "The Peak, officially known as Victoria Peak, is the highest point on Hong Kong Island, standing about 552 meters (1,811 feet) above sea level.",
                duration: "30 - 45 minutes",
                openingHours: "8:00 AM – 6:00 PM",
                rating: 4.7,
                reviews: [
                    Review(id: UUID(), author: "Alex Wong", text: "Quite good", rating: 4.7, date: Date(timeIntervalSinceNow: -60 * 60 * 24 * 30))
                ],
                imageName: "peak_sample"
            ),
            Location(
                id: UUID(),
                name: "Dragon's Back",
                region: "Shek O",
                category: .hiking,
                summary: "One of Hong Kong's most famous hikes with sweeping coastal views.",
                duration: "2 - 3 hours",
                openingHours: "Open 24 hours",
                rating: 4.6,
                reviews: [],
                imageName: "peak_sample"
            )
        ]
    }
}

enum LocationCategory: String, Codable, CaseIterable {
    case all
    case food
    case sights
    case hiking

    var title: String {
        switch self {
        case .all: return "All"
        case .food: return "Food"
        case .sights: return "Sights"
        case .hiking: return "Hiking"
        }
    }
}
