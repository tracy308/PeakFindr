
import Foundation

final class ReviewService {
    static let shared = ReviewService()
    private init() {}

    func createReview(userId: String, locationId: String, rating: Int, comment: String) async throws -> ReviewResponse {
        let body = ReviewCreateRequest(location_id: locationId, rating: rating, comment: comment)
        return try await APIClient.shared.request("/reviews/", method: "POST", body: body, userId: userId)
    }

    func reviewsForLocation(userId: String, locationId: String) async throws -> [ReviewWithPhotos] {
        return try await APIClient.shared.request("/reviews/location/\(locationId)", userId: userId)
    }

    func updateReview(userId: String, reviewId: String, rating: Int?, comment: String?) async throws -> ReviewResponse {
        let body = ReviewUpdateRequest(rating: rating, comment: comment)
        return try await APIClient.shared.request("/reviews/\(reviewId)", method: "PUT", body: body, userId: userId)
    }

    func deleteReview(userId: String, reviewId: String) async throws -> InteractionMessage {
        return try await APIClient.shared.request("/reviews/\(reviewId)", method: "DELETE", userId: userId)
    }
}
