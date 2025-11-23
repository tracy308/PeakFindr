
import Foundation
import UIKit

struct Navigator {
    static func openInMaps(query: String) {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query

        if let url = URL(string: "http://maps.apple.com/?q=\(encoded)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url); return
        }
        if let url = URL(string: "comgooglemaps://?q=\(encoded)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url); return
        }
        if let url = URL(string: "https://www.google.com/maps/search/?api=1&query=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }
}
