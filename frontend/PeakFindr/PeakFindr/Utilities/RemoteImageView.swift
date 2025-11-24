import SwiftUI
import UIKit

struct RemoteImageView<Placeholder: View, Failure: View>: View {
    let url: URL?
    var contentMode: ContentMode = .fill
    @ViewBuilder var placeholder: () -> Placeholder
    @ViewBuilder var failure: () -> Failure

    @State private var uiImage: UIImage?
    @State private var isLoading = false
    @State private var didFail = false

    var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if isLoading {
                placeholder()
            } else if didFail || url == nil {
                failure()
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            await loadImage()
        }
    }

    @MainActor
    private func resetState() {
        uiImage = nil
        didFail = false
    }

    private func loadImage() async {
        await resetState()
        guard let url else {
            await MainActor.run { didFail = true }
            return
        }

        await MainActor.run { isLoading = true }

        defer {
            Task { @MainActor in isLoading = false }
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else {
                await MainActor.run { didFail = true }
                return
            }
            await MainActor.run { uiImage = image }
        } catch {
            await MainActor.run { didFail = true }
        }
    }
}
