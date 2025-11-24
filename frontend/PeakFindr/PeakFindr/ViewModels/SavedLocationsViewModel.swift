
import Foundation
internal import Combine

@MainActor
final class SavedLocationsViewModel: ObservableObject {
    @Published var savedLocations: [LocationResponse] = []
    @Published var isLoading = false
    @Published var error: String? = nil

    func loadSaved(userId: String) async {
        isLoading = true
        error = nil
        do {
            let savedRows = try await InteractionService.shared.getSaved(userId: userId)
            let allLocations = try await LocationService.shared.listLocations()
            let map = Dictionary(uniqueKeysWithValues: allLocations.map { ($0.id, $0) })
            savedLocations = savedRows.compactMap { map[$0.location_id] }
        } catch let err {
            error = err.localizedDescription
            savedLocations = []
        }
        isLoading = false
    }
}
