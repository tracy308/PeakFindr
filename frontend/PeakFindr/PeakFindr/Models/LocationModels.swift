
import Foundation

struct LocationResponse: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let description: String?
    let maps_url: String?
    let price_level: Int?
    let area: String?
    let created_at: String

    var mainImageURL: URL? {
        URL(string: "\(APIClient.shared.baseURL)/locations/\(id)/image")
    }
}

struct LocationDetailResponse: Codable, Identifiable, Equatable {
    var id: String { location.id }
    let location: LocationResponse
    let images: [LocationImage]
    let tags: [Tag]
}

struct LocationImage: Codable, Identifiable, Equatable {
    let id: Int
    let location_id: String
    let file_path: String
    let created_at: String
}

struct Tag: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
}
