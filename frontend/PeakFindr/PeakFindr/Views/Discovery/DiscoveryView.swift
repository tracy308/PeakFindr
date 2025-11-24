import SwiftUI

struct DiscoveryView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var discoveryVM: DiscoveryViewModel

    @State private var navigateToDetail = false
    @State private var activeLocation: LocationResponse?

    enum Category: String, CaseIterable {
        case all = "All"
        case food = "Food"
        case sights = "Sights"
        case hiking = "Hiking"
    }

    @State private var selectedCategory: Category = .all

    var body: some View {
        VStack(spacing: 0) {
            header
            filterBar

            if discoveryVM.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if let err = discoveryVM.error {
                Spacer()
                Text(err).foregroundColor(.red)
                Spacer()
            } else if filteredLocations.isEmpty {
                Spacer()
                VStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text("No locations in this category yet.")
                        .font(.headline)
                    Text("Try another filter.")
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                SwipeCardStack(
                    locations: filteredLocations,
                    onSkip: { loc in
                        withAnimation(.spring()) {
                            discoveryVM.removeTop(loc)
                        }
                    },
                    onSave: { loc in
                        withAnimation(.spring()) {
                            Task { await likeAndSave(loc) }
                            discoveryVM.removeTop(loc)
                        }
                    },
                    onTapTop: { loc in
                        activeLocation = loc
                        navigateToDetail = true
                    }
                )
                .padding(.horizontal)
                .padding(.top, 8)
                Spacer()
            }

            NavigationLink(
                destination: DetailView(location: activeLocation),
                isActive: $navigateToDetail
            ) { EmptyView() }
        }
        .navigationTitle("Today's Discovery")
        .navigationBarTitleDisplayMode(.inline)
        .task { await discoveryVM.loadLocations() }
    }

    private var header: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 176/255, green: 62/255, blue: 55/255),
                            Color(red: 195/255, green: 78/255, blue: 58/255),
                            Color(red: 214/255, green: 98/255, blue: 60/255)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 200)
                .padding(.horizontal)

            VStack(spacing: 8) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(.yellow)

                Text("Today's Discovery")
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Text("Swipe left to skip, right to save.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.95))
            }
        }
        .padding(.top, 6)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Category.allCases, id: \.self) { cat in
                    Text(cat.rawValue)
                        .font(.headline)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            Capsule().fill(selectedCategory == cat
                                           ? Color(red: 176/255, green: 62/255, blue: 55/255)
                                           : Color(.systemGray5))
                        )
                        .foregroundColor(selectedCategory == cat ? .white : .primary)
                        .onTapGesture { selectedCategory = cat }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }

    private var filteredLocations: [LocationResponse] {
        let all = discoveryVM.locations
        guard selectedCategory != .all else { return all }

        func contains(_ s: String?, _ keywords: [String]) -> Bool {
            guard let s = s?.lowercased() else { return false }
            return keywords.contains(where: { s.contains($0) })
        }

        return all.filter { loc in
            let name = loc.name.lowercased()
            let desc = loc.description?.lowercased()

            switch selectedCategory {
            case .food:
                return contains(desc, ["restaurant","cafe","food","eat","dine"]) ||
                       ["restaurant","cafe","food","eat","dine"].contains(where: name.contains)
            case .hiking:
                return contains(desc, ["trail","hike","peak","mount","mountain","walk"]) ||
                       ["trail","hike","peak","mount","mountain","walk"].contains(where: name.contains)
            case .sights:
                return contains(desc, ["view","scenic","park","museum","temple","beach","garden","lookout"]) ||
                       ["view","scenic","park","museum","temple","beach","garden","lookout"].contains(where: name.contains)
            case .all:
                return true
            }
        }
    }

    private func likeAndSave(_ loc: LocationResponse) async {
        guard let id = authVM.userId else { return }
        _ = try? await InteractionService.shared.like(locationId: loc.id, userId: id)
        _ = try? await InteractionService.shared.save(locationId: loc.id, userId: id)
    }
}
