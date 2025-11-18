//
//  LocationDetails.swift
//  playground
//
//  Created by Wong Nixon on 18/10/2025.
//

import SwiftUI
import MapKit

struct LocationDetail: Identifiable {
    let id: String
    let name: String
    let imageUrl: String?
    let category: String
    let district: String?
    let description: String
    let averageRating: Double?
    let openingHours: String?
    let estimatedTime: String?
    let tips: String?
    let latitude: Double?
    let longitude: Double?
    let address: String?
}

struct Review: Identifiable {
    let id: String
    let user: String
    let locationName: String
    let rating: Double
    let comment: String
    let date: Date
}

struct LocationDetailsView: View {
    let location: LocationDetail
    @Environment(\.openURL) private var openURL
    @State private var showAddReview = false
    @State private var reviews: [Review] = [
        Review(id: "1", user: "Alice", locationName: "The Peak", rating: 5.0,  comment: "Amazing place!", date: Date()),
        Review(id: "2", user: "Bob", locationName: "The Peak", rating: 4.5, comment: "Great experience.", date: Date().addingTimeInterval(-86400))
    ]
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header Image
                ZStack(alignment: .topLeading) {
                    if let url = location.imageUrl, let imageUrl = URL(string: url) {
                        AsyncImage(url: imageUrl) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Color.gray.opacity(0.2)
                        }
                        .frame(height: 320)
                        .clipped()
                    } else {
                        VStack {
                            Spacer()
                            Image(systemName: "mappin")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 96, height: 96)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        .frame(height: 320)
                        .background(LinearGradient(gradient: Gradient(colors: [.gray.opacity(0.2), .gray.opacity(0.3)]), startPoint: .top, endPoint: .bottom))
                    }
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    .padding(.top, 24)
                    .padding(.leading, 16)
                }

                // Content Card
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(location.category.replacingOccurrences(of: "_", with: " "))
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(12)
                            Text(location.name)
                                .font(.largeTitle).bold()
                            if let district = location.district {
                                HStack(spacing: 6) {
                                    Image(systemName: "mappin")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(district)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        Spacer()
                        VStack(alignment: .center) {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.title2)
                                Text(location.averageRating != nil ? String(format: "%.1f", location.averageRating!) : "N/A")
                                    .font(.title2).bold()
                            }
                            Text("\(reviews.count) reviews")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }

                    Text(location.description)
                        .font(.body)
                        .foregroundColor(.gray)

                    // Quick Info
                    HStack(spacing: 16) {
                        if let hours = location.openingHours {
                            HStack(spacing: 8) {
                                Image(systemName: "clock")
                                    .foregroundColor(.red)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Hours")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(hours)
                                        .font(.subheadline)
                                }
                            }
                            .padding(10)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                        if let duration = location.estimatedTime {
                            HStack(spacing: 8) {
                                Image(systemName: "clock")
                                    .foregroundColor(.red)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Duration")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(duration)
                                        .font(.subheadline)
                                }
                            }
                            .padding(10)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }

                    // Tips
                    if let tips = location.tips {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("💡 Local Tips")
                                .font(.subheadline).bold()
                                .foregroundColor(.yellow)
                            Text(tips)
                                .font(.subheadline)
                                .foregroundColor(.yellow)
                        }
                        .padding()
                        .background(Color.yellow.opacity(0.15))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                        )
                    }

                    // Action Buttons
                    HStack(spacing: 16) {
                        Button(action: openInGoogleMaps) {
                            HStack {
                                Image(systemName: "location.north.line")
                                Text("Navigate")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)

                        Button(action: { showAddReview = true }) {
                            HStack {
                                Image(systemName: "text.bubble")
                                Text("Write Review")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(24)
                .shadow(radius: 10)
                .offset(y: -40)
                .padding(.horizontal)
                .padding(.bottom, 8)

                // Reviews Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Reviews & Experiences")
                        .font(.title2).bold()
                    if showAddReview {
                        AddReviewView(locationId: location.id, onClose: { showAddReview = false })
                    }
                    ReviewListView(reviews: reviews)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(24)
                .shadow(radius: 6)
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .background(Color.gray.opacity(0.08))
        .ignoresSafeArea(edges: .top)
    }

    func openInGoogleMaps() {
        if let lat = location.latitude, let lon = location.longitude {
            let urlString = "https://www.google.com/maps/dir/?api=1&destination=\(lat),\(lon)"
            if let url = URL(string: urlString) {
                openURL(url)
            }
        } else if let address = location.address {
            let query = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let url = URL(string: "https://www.google.com/maps/search/?api=1&query=\(query)") {
                openURL(url)
            }
        }
    }

}

// Dummy AddReviewView and ReviewListView for demo
struct AddReviewView: View {
    let locationId: String
    let onClose: () -> Void
    var body: some View {
        VStack {
            Text("Add Review for \(locationId)")
            Button("Close", action: onClose)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ReviewListView: View {
    let reviews: [Review]
    var body: some View {
        ForEach(reviews) { review in
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(review.user).bold()
                    Spacer()
                    Text(String(format: "%.1f", review.rating))
                        .foregroundColor(.yellow)
                }
                Text(review.comment)
                Text(review.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 8)
            Divider()
        }
    }
}

#Preview {
    LocationDetailsView(location: LocationDetail(
        id: "1",
        name: "Victoria Peak",
        imageUrl: nil,
        category: "sightseeing",
        district: "Central and Western",
        description: "A must-visit spot for panoramic views of Hong Kong.",
        averageRating: 4.7,
        openingHours: "07:00 - 23:00",
        estimatedTime: "2-3 hours",
        tips: "Go early to avoid crowds and bring a camera!",
        latitude: 22.2758,
        longitude: 114.1455,
        address: "Victoria Peak, Hong Kong"
    ))
}

