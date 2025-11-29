import Foundation
internal import Combine

@MainActor
final class DiscoveryViewModel: ObservableObject {
    @Published var locations: [LocationDetailResponse] = []
    @Published var isLoading = false
    @Published var error: String? = nil

    /// Load locations for discovery - excludes saved locations when userId is provided
    func loadLocations(userId: String? = nil) async {
        isLoading = true
        error = nil
        do {
            if let userId = userId {
                // Authenticated: use discover endpoint that excludes saved locations
                locations = try await LocationService.shared.discoverLocations(userId: userId)
            } else {
                // Fallback: list all locations (public)
                let list = try await LocationService.shared.listLocations()
                locations = list.map { LocationDetailResponse(location: $0, images: [], tags: []) }
            }
        } catch let err {
            error = err.localizedDescription
        }
        isLoading = false
    }

    func removeTop(_ loc: LocationDetailResponse) {
        if let idx = locations.firstIndex(of: loc) { locations.remove(at: idx) }
    }
}
