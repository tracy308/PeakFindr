import SwiftUI
import UIKit

struct LocalFileImage: View {
    let pathOrName: String

    var body: some View {
        Group {
            if let ui = UIImage(contentsOfFile: pathOrName) {
                Image(uiImage: ui).resizable().scaledToFill()
            } else if UIImage(named: pathOrName) != nil {
                Image(pathOrName).resizable().scaledToFill()
            } else {
                Rectangle().foregroundColor(.gray).overlay(Image(systemName: "photo").font(.largeTitle).foregroundColor(.white))
            }
        }
    }
}
