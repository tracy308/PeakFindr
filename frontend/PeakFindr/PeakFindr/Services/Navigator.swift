
import Foundation
import UIKit

struct Navigator {
    static func openInMaps(query: String) {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query

        // Prefer Apple Maps
        if let url = URL(string: "http://maps.apple.com/?q=\(encoded)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            return
        }

        // Try Google Maps if installed
        if let url = URL(string: "comgooglemaps://?q=\(encoded)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            return
        }

        // Fallback to web Google Maps
        if let url = URL(string: "https://www.google.com/maps/search/?api=1&query=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }
}
