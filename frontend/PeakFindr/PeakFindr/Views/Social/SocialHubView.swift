
import SwiftUI

extension Notification.Name {
    static let savedLocationsUpdated = Notification.Name("savedLocationsUpdated")
}

struct SocialHubView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var discoveryVM: DiscoveryViewModel

    @State private var savedLocations: [LocationResponse] = []
    @State private var loading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Text("Chat rooms").font(.headline)
                .padding(.horizontal).padding(.top, 16)

            if loading {
                ProgressView().padding()
            } else if savedLocations.isEmpty {
                Text("Save a location to unlock its chat.")
                    .foregroundColor(.secondary)
                    .padding(.horizontal).padding(.top, 8)
            } else {
                List {
                    ForEach(savedLocations) { loc in
                        NavigationLink {
                            ChatRoomView(location: loc)
                        } label: {
                            HStack {
                                Image(systemName: "bubble.left")
                                Text(loc.name)
                                Spacer()
                            }.padding(.vertical, 8)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle("Social Hub")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadRooms() }
        .onAppear { Task { await loadRooms() } }
        .onReceive(NotificationCenter.default.publisher(for: .savedLocationsUpdated)) { _ in
            Task { await loadRooms() }
        }
    }

    private var header: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 217/255, green: 85/255, blue: 122/255),
                    Color(red: 182/255, green: 74/255, blue: 174/255)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .frame(height: 170)
            .mask(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
            )

            VStack(spacing: 8) {
                Image(systemName: "person.2.fill")
                    .font(.largeTitle)
                    .foregroundColor(.white)

                Text("Social Hub")
                    .font(.title2).bold()
                    .foregroundColor(.white)

                Text("Connect with explorers and plan adventures together")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
        .padding(.horizontal)
    }

    @MainActor
    private func loadRooms() async {
        guard let uid = authVM.userId else { return }
        loading = true
        let savedRows = (try? await InteractionService.shared.getSaved(userId: uid)) ?? []

        var map = Dictionary(uniqueKeysWithValues: discoveryVM.locations.map { ($0.id, $0.location) })
        if map.isEmpty {
            let all = (try? await LocationService.shared.listLocations()) ?? []
            map = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
        }

        var resolvedLocations: [LocationResponse] = []
        for row in savedRows {
            if let location = map[row.location_id] {
                resolvedLocations.append(location)
                continue
            }

            if let detail = try? await LocationService.shared.getLocationDetail(locationId: row.location_id) {
                resolvedLocations.append(detail.location)
            }
        }

        savedLocations = resolvedLocations
        loading = false
    }
}
