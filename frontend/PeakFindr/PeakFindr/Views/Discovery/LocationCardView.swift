
import SwiftUI

struct LocationCardView: View {
    let location: Location

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let uiImage = UIImage(named: location.imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(12)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                    .cornerRadius(12)
                    .overlay(Text(location.name).font(.headline))
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(location.name)
                        .font(.headline)
                    Spacer()
                    RatingBadge(rating: location.rating)
                }

                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                    Text(location.region)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    TagView(text: location.category.title)
                }

                Text(location.summary)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(3)

                if let duration = location.duration {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text(duration)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        NotificationCenter.default.post(name: .skipLocation, object: location)
                    } label: {
                        Label("Skip", systemImage: "xmark")
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.15)))
                    }

                    Button {
                        NotificationCenter.default.post(name: .saveLocation, object: location)
                    } label: {
                        Label("Save", systemImage: "heart")
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(Color(red: 170/255, green: 64/255, blue: 57/255))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
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

struct TagView: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(999)
    }
}

struct RatingBadge: View {
    let rating: Double
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
            Text(String(format: "%.1f", rating))
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}
