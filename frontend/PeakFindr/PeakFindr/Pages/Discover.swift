//
//  Discover.swift
//  playground
//
//  Created by Wong Nixon on 18/10/2025.
//

import SwiftUI


struct DiscoverLocation: Identifiable {
    let id: Int
    let name: String
    // Add other properties as needed
}

struct DiscoverView: View {
    @State private var currentIndex = 0
    @State private var selectedCategory = "all"
    @State private var locations: [DiscoverLocation] = []
    @State private var visits: [Int] = [] // Store visited location ids
    @State private var isLoading = true

    var body: some View {
        VStack {
            // Hero Section
            VStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 48))
                    .foregroundColor(.yellow)
                Text("Today's Discovery")
                    .font(.largeTitle).bold()
                Text("Swipe through hidden gems and create your adventure")
                    .foregroundColor(.red)
            }
            .padding()
            .background(LinearGradient(gradient: Gradient(colors: [.red, .pink]),
                                       startPoint: .top, endPoint: .bottom))

            // Category Filter
            Picker("Category", selection: $selectedCategory) {
                Text("All").tag("all")
                // Add more categories here
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.top, -16)

            // Main Content
            if isLoading {
                ProgressView("Loading treasures...")
                    .frame(maxWidth: .infinity, maxHeight: 500)
                    .background(Color.white)
                    .cornerRadius(30)
                    .shadow(radius: 10)
                    .padding()
            } else if locations.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "mappin")
                        .font(.system(size: 64))
                        .foregroundColor(.gray)
                    Text("No locations found")
                        .font(.title3)
                        .foregroundColor(.gray)
                    Text("Try a different category")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: 300)
                .background(Color.white)
                .cornerRadius(30)
                .shadow(radius: 10)
                .padding()
            } else if currentIndex >= locations.count {
                VStack(spacing: 16) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.yellow)
                    Text("You've seen them all!")
                        .font(.title).bold()
                    Text("Check back tomorrow for new discoveries")
                        .foregroundColor(.gray)
                    Button(action: {
                        currentIndex = 0
                    }) {
                        Text("Start Over")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: 300)
                .background(Color.white)
                .cornerRadius(30)
                .shadow(radius: 10)
                .padding()
            } else {
                // Show current DiscoverLocationCard
                DiscoverLocationCard(
                    location: locations[currentIndex],
                    isVisited: visits.contains(locations[currentIndex].id),
                    onLike: { handleLike(location: locations[currentIndex]) },
                    onSkip: { handleSkip() }
                )
                .animation(.easeInOut, value: currentIndex)
                .padding()
            }

            // Progress indicator
            if !locations.isEmpty && currentIndex < locations.count {
                VStack(spacing: 4) {
                    Text("\(currentIndex + 1) of \(locations.count) locations")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    ProgressView(value: Double(currentIndex + 1), total: Double(locations.count))
                        .progressViewStyle(LinearProgressViewStyle(tint: .red))
                        .frame(maxWidth: 200)
                }
                .padding(.bottom, 20)
            }
        }
        .background(Color.gray.opacity(0.1))
        .onAppear {
            loadLocations()
            loadVisits()
        }
    }

    // MARK: - Actions

    func loadLocations() {
        isLoading = true
        // Replace this with actual async API call, e.g., using async/await or Combine
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Sample data
            locations = [
                DiscoverLocation(id: 1, name: "Location One"),
                DiscoverLocation(id: 2, name: "Location Two"),
                DiscoverLocation(id: 3, name: "Location Three"),
            ]
            isLoading = false
            currentIndex = 0
        }
    }

    func loadVisits() {
        // Load already visited location IDs for user
        visits = [] // Replace with actual data fetching
    }

    func handleLike(location: DiscoverLocation) {
        // Store visit data on backend and update visits locally
        visits.append(location.id)
        nextLocation()
        // Update user stats as needed
    }

    func handleSkip() {
        nextLocation()
    }

    private func nextLocation() {
        if currentIndex < locations.count - 1 {
            currentIndex += 1
        }
    }
}

// Simple DiscoverLocationCard View for demo (customize as needed)
struct DiscoverLocationCard: View {
    let location: DiscoverLocation
    let isVisited: Bool
    let onLike: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text(location.name)
                .font(.title2)
                .bold()
            HStack(spacing: 40) {
                Button(action: onSkip) {
                    Image(systemName: "xmark.circle")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                }
                Button(action: onLike) {
                    Image(systemName: "heart.fill")
                        .font(.largeTitle)
                        .foregroundColor(isVisited ? .red : .pink)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: 250)
        .background(Color.white)
        .cornerRadius(30)
        .shadow(radius: 10)
    }
}

#Preview {
    LayoutView {
        DiscoverView()
    }
}

