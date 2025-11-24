import SwiftUI

struct SavedLocationsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var savedVM: SavedLocationsViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {

                header

                if savedVM.isLoading {
                    ProgressView().padding(.top, 30)
                } else if let err = savedVM.error {
                    Text(err).foregroundColor(.red).padding(.top, 20)
                } else if savedVM.savedLocations.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 12) {
                        ForEach(savedVM.savedLocations) { loc in
                            NavigationLink(destination: DetailView(location: loc)) {
                                SavedLocationCard(loc: loc)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Saved")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let uid = authVM.userId {
                await savedVM.loadSaved(userId: uid)
            }
        }
    }

    private var header: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 248/255, green: 155/255, blue: 63/255), // orange
                            Color(red: 252/255, green: 198/255, blue: 67/255), // warm yellow
                            Color(red: 255/255, green: 224/255, blue: 111/255) // light yellow
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 140)

            VStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.white)

                Text("Saved Locations")
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Text("Your favorite picks, ready for your next trip.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.95))
            }
            .padding(.horizontal, 12)
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "heart")
                .font(.system(size: 36))
                .foregroundColor(.secondary)

            Text("No saved locations yet.")
                .font(.headline)

            Text("Swipe right on Discover to save a spot!")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 30)
    }
}

private struct SavedLocationCard: View {
    let loc: LocationResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 160)
                .cornerRadius(12)
                .overlay(
                    Text(loc.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                )

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(loc.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if let area = loc.area {
                        Label(area, systemImage: "mappin.and.ellipse")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if let desc = loc.description {
                        Text(desc)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                if let price = loc.price_level {
                    Text(String(repeating: "$", count: max(1, min(price, 5))))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
    }
}
