
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

    func getLocationDetail(locationId: String) async throws -> LocationDetailResponse {
        return try await APIClient.shared.request("/locations/\(locationId)")
    }
}
