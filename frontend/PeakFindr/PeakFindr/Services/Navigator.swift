
import Foundation
import UIKit

struct Navigator {
    static func openInMaps(urlString: String?) {
        guard let urlString, let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}
