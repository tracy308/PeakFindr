
import Foundation
import UIKit

struct Navigator {
    static func openInMaps(for location: LocationResponse) {
        if let mapsURLString = location.maps_url, let url = URL(string: mapsURLString) {
            UIApplication.shared.open(url)
            return
        }

        var queryParts: [String] = [location.name]
        let region = location.area?.isEmpty == false ? location.area! : "Hong Kong"
        queryParts.append(region)

        let query = queryParts.joined(separator: ", ")
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)

        guard let query, let url = URL(string: "http://maps.apple.com/?q=\(query)") else { return }
        UIApplication.shared.open(url)
    }
}
