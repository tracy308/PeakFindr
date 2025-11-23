
import SwiftUI

struct DetailView: View {
    @EnvironmentObject var discoveryVM: DiscoveryViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    var location: Location?

    @State private var isSaved: Bool = false
    @State private var showingReviewSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let loc = location {
                    if let uiImage = UIImage(named: loc.imageName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 260)
                            .clipped()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(loc.name)
                            .font(.title2)
                            .bold()

                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                            Text(loc.region)
                                .foregroundColor(.secondary)
                            Spacer()
                        }

                        HStack(spacing: 6) {
                            Image(systemName: "star.fill").foregroundColor(.yellow)
                            Text(String(format: "%.1f", loc.rating)).bold()
                            Text("· \(loc.reviews.count) review\(loc.reviews.count == 1 ? "" : "s")")
                                .foregroundColor(.secondary)
                        }

                        Text(loc.summary)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal)

                    VStack(spacing: 10) {
                        infoRow(icon: "clock", title: "Duration", value: loc.duration ?? "—")
                        infoRow(icon: "calendar", title: "Opening hour", value: loc.openingHours ?? "—")

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Local Tips")
                                .font(.headline)
                            Text("Visit early morning to see locals performing traditional rituals. Donations are welcomed.")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    HStack(spacing: 12) {
                        Button {
                            if let loc = location {
                                discoveryVM.save(location: loc)
                                isSaved = true
                            }
                        } label: {
                            Label(isSaved ? "Saved" : "Save", systemImage: isSaved ? "heart.fill" : "heart")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isSaved ? Color.green.opacity(0.9) : Color(red: 170/255, green: 64/255, blue: 57/255))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }

                        Button {
                            showingReviewSheet = true
                        } label: {
                            Label("Write Review", systemImage: "square.and.pencil")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    Button {
                        if let loc = location {
                            Navigator.openInMaps(query: loc.name)
                        }
                    } label: {
                        Label("Navigate", systemImage: "location.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 170/255, green: 64/255, blue: 57/255))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)

                    if !loc.reviews.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reviews")
                                .font(.headline)
                                .padding(.top, 12)
                            ForEach(loc.reviews) { r in
                                HStack(alignment: .top, spacing: 12) {
                                    Circle()
                                        .fill(Color(red: 170/255, green: 64/255, blue: 57/255))
                                        .frame(width: 40, height: 40)
                                        .overlay(Text(String(r.author.prefix(1))).foregroundColor(.white))

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(r.author).bold()
                                        Text(r.text).foregroundColor(.secondary)
                                        Text(r.date, style: .date)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()
                                    Text(String(format: "%.1f", r.rating))
                                        .bold()
                                }
                                .padding(10)
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                                .shadow(radius: 0.5)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                } else {
                    Text("No location selected")
                        .padding()
                }
            }
        }
        .navigationTitle(location?.name ?? "Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingReviewSheet) {
            if let loc = location {
                WriteReviewView(location: loc) { review in
                    discoveryVM.addReview(review, to: loc)
                    showingReviewSheet = false
                }
            }
        }
        .onAppear {
            if let loc = location {
                isSaved = discoveryVM.saved.contains(where: { $0.id == loc.id })
            }
        }
    }

    @ViewBuilder
    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .bold()
            }
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}
