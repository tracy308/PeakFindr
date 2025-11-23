
import SwiftUI

struct DiscoveryView: View {
    @EnvironmentObject var discoveryVM: DiscoveryViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    @State private var navigateToDetail = false
    @State private var activeLocation: Location?

    var body: some View {
        VStack(spacing: 0) {
            discoveryHeader
            categoryFilterBar

            Spacer(minLength: 8)

            ZStack {
                if discoveryVM.filteredLocations.isEmpty {
                    VStack(spacing: 12) {
                        Text("You're all caught up!")
                            .font(.headline)
                        Button("Reload Samples") {
                            discoveryVM.loadSample()
                        }
                    }
                } else {
                    SwipeCardStack(
                        locations: discoveryVM.filteredLocations,
                        onSkip: { loc in discoveryVM.skip(location: loc) },
                        onShowDetail: { loc in
                            activeLocation = loc
                            navigateToDetail = true
                        }
                    )
                    .padding(.horizontal)
                }
            }
            .frame(maxHeight: .infinity)

            NavigationLink(
                destination: DetailView(location: activeLocation)
                    .environmentObject(discoveryVM)
                    .environmentObject(profileVM),
                isActive: $navigateToDetail
            ) {
                EmptyView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Today's Discovery")
                    .font(.headline)
            }
        }
    }

    private var discoveryHeader: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 170/255, green: 64/255, blue: 57/255))
                .frame(height: 160)
                .padding(.horizontal)

            VStack(spacing: 8) {
                Image(systemName: "wand.and.stars")
                    .font(.largeTitle)
                    .foregroundColor(.yellow)
                Text("Today's Discovery")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                Text("Swipe through hidden gems and create your adventure")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
        .padding(.top)
    }

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(LocationCategory.allCases, id: \.self) { category in
                    let isSelected = discoveryVM.categoryFilter == category
                    Button {
                        discoveryVM.categoryFilter = category
                    } label: {
                        Text(category.title)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(isSelected ? Color(red: 170/255, green: 64/255, blue: 57/255) : Color.white)
                            .foregroundColor(isSelected ? .white : .primary)
                            .cornerRadius(999)
                            .overlay(
                                RoundedRectangle(cornerRadius: 999)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
}
