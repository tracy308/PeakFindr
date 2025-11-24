
import SwiftUI

struct LocationCardView: View {
    let location: LocationResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 200)
                .cornerRadius(12)
                .overlay(Text(location.name).font(.headline))

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
