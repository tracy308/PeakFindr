
import Foundation
import Combine

@MainActor
class DiscoveryViewModel: ObservableObject {
    @Published var locations: [Location] = []
    @Published var saved: [Location] = []
    @Published var categoryFilter: LocationCategory = .all

    init() {
        loadSample()
        NotificationCenter.default.addObserver(forName: .saveLocation, object: nil, queue: .main) { [weak self] note in
            guard let loc = note.object as? Location else { return }
            self?.save(location: loc)
        }
        NotificationCenter.default.addObserver(forName: .skipLocation, object: nil, queue: .main) { [weak self] note in
            guard let loc = note.object as? Location else { return }
            self?.skip(location: loc)
        }
    }

    var filteredLocations: [Location] {
        switch categoryFilter {
        case .all:
            return locations
        default:
            return locations.filter { $0.category == categoryFilter }
        }
    }

    func loadSample() { locations = Location.sampleData() }

    func skip(location: Location) {
        if let idx = locations.firstIndex(of: location) { locations.remove(at: idx) }
    }

    func save(location: Location) {
        if !saved.contains(location) { saved.append(location) }
    }

    func addReview(_ review: Review, to location: Location) {
        if let idx = locations.firstIndex(of: location) {
            locations[idx].reviews.append(review)
            let sum = locations[idx].reviews.reduce(0.0) { $0 + $1.rating }
            locations[idx].rating = sum / Double(max(1, locations[idx].reviews.count))
            NotificationCenter.default.post(name: .reviewSubmitted, object: locations[idx])
        }
        if let sidx = saved.firstIndex(of: location) {
            saved[sidx].reviews.append(review)
            let sum = saved[sidx].reviews.reduce(0.0) { $0 + $1.rating }
            saved[sidx].rating = sum / Double(max(1, saved[sidx].reviews.count))
        }
    }
}

extension Notification.Name {
    static let skipLocation = Notification.Name("Peakfindr.skipLocation")
    static let saveLocation = Notification.Name("Peakfindr.saveLocation")
    static let reviewSubmitted = Notification.Name("Peakfindr.reviewSubmitted")
}
