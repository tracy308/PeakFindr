
import Foundation

final class LocationService {
    static let shared = LocationService()
    private init() {}

    /// Location endpoints are public.
    func listLocations(area: String? = nil, priceLevel: Int? = nil) async throws -> [LocationResponse] {
        var q: [String] = []
        if let area { q.append("area=\(area.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? area)") }
        if let priceLevel { q.append("price_level=\(priceLevel)") }
        let qs = q.isEmpty ? "" : "?" + q.joined(separator: "&")
        return try await APIClient.shared.request("/locations/\(qs)")
    }

    /// Discovery endpoint - excludes saved locations (requires auth)
    func discoverLocations(userId: String, limit: Int = 50) async throws -> [LocationDetailResponse] {
        return try await APIClient.shared.request("/locations/discover?limit=\(limit)", userId: userId)
    }

    func getLocationDetail(locationId: String) async throws -> LocationDetailResponse {
        return try await APIClient.shared.request("/locations/\(locationId)")
    }
}
