import Foundation
internal import Combine

@MainActor
final class DiscoveryViewModel: ObservableObject {
    @Published var locations: [LocationResponse] = []
    @Published var isLoading = false
    @Published var error: String? = nil

    func loadLocations() async {
        isLoading = true
        error = nil
        do {
            locations = try await LocationService.shared.listLocations()
        } catch let err {
            error = err.localizedDescription
        }
        isLoading = false
    }

    func removeTop(_ loc: LocationResponse) {
        if let idx = locations.firstIndex(of: loc) { locations.remove(at: idx) }
    }
}
