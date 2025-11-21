
import Foundation

struct Review: Identifiable, Codable, Equatable {
    let id: UUID
    let author: String
    let text: String
    let rating: Double
    let date: Date
}
