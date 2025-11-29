import Foundation
internal import Combine

@MainActor
final class DiscoveryViewModel: ObservableObject {
    @Published var locations: [LocationResponse] = []
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
                locations = try await LocationService.shared.listLocations()
            }
        } catch let err {
            error = err.localizedDescription
        }
        isLoading = false
    }

    func removeTop(_ loc: LocationResponse) {
        if let idx = locations.firstIndex(of: loc) { locations.remove(at: idx) }
    }
}
