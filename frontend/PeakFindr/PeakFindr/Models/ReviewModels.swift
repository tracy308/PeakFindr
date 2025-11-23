
import Foundation

struct ReviewCreateRequest: Codable {
    let location_id: String
    let rating: Int
    let comment: String
}

struct ReviewUpdateRequest: Codable {
    let rating: Int?
    let comment: String?
}

struct ReviewResponse: Codable, Identifiable, Equatable {
    let id: String
    let user_id: String
    let location_id: String
    let rating: Int
    let comment: String
    let created_at: String
}

struct ReviewWithPhotos: Codable, Identifiable, Equatable {
    var id: String { review.id }

    let review: ReviewResponse
    let photos: [ReviewPhoto]
}

struct ReviewPhoto: Codable, Identifiable, Equatable {
    let id: Int
    let review_id: String
    let file_path: String
    let created_at: String
}
