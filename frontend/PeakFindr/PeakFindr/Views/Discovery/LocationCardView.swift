
import SwiftUI

struct LocationCardView: View {
    let location: LocationResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .bottomLeading) {
                RemoteImageView(
                    url: location.mainImageURL,
                    placeholder: {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.gray.opacity(0.1))
                    },
                    failure: {
                        Color.gray.opacity(0.2)
                    }
                )
                .aspectRatio(contentMode: .fill)
                LinearGradient(
                    colors: [.clear, .black.opacity(0.55)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 10) {
                    Spacer()
                    Spacer()
                    Text(location.name)
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(location.area ?? "Hong Kong")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                    Spacer()
                }
            }
            .frame(width: 350, height: 200)
            .cornerRadius(12)
            .clipped()

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(location.name).font(.headline)
                    Spacer()
                    if let price = location.price_level {
                        Text(String(repeating: "$", count: price))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                    Text(location.area ?? "Hong Kong")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }

                Text(location.description ?? "")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(3)

                HStack(spacing: 12) {
                    Text("Swipe left to skip")
                        .font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Text("Swipe right to save")
                        .font(.caption).foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 10)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
    }
}
