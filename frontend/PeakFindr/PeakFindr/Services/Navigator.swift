
import Foundation
import UIKit

struct Navigator {
    static func openInMaps(for location: LocationResponse) {
        if let mapsURL = location.maps_url,
           let encoded = mapsURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: encoded) {
            UIApplication.shared.open(url)
            return
        }

        var queryParts: [String] = [location.name]
        if let area = location.area, !area.isEmpty {
            queryParts.append(area)
        }
        queryParts.append("Hong Kong")

        let query = queryParts.joined(separator: ", ")
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)

        guard let query, let url = URL(string: "http://maps.apple.com/?q=\(query)") else { return }
        UIApplication.shared.open(url)
    }
}
