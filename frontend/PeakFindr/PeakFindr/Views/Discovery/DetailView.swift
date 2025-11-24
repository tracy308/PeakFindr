import SwiftUI

struct DetailView: View {
    @EnvironmentObject var authVM: AuthViewModel
    var location: LocationResponse?
    var showCheckIn: Bool = true

    @State private var detail: LocationDetailResponse?
    @State private var reviews: [ReviewWithPhotos] = []
    @State private var isSaved = false
    @State private var showingReviewSheet = false
    @State private var checkInMessage: String? = nil

    var body: some View {
        ScrollView {
            if let loc = location {
                VStack(alignment: .leading, spacing: 12) {

                    // Top image placeholder
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 260)
                        .overlay(
                            Text(loc.name)
                                .font(.title2)
                                .bold()
                        )

                    // Basic info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(loc.name)
                            .font(.title2)
                            .bold()

                        Text(loc.area ?? "Hong Kong")
                            .foregroundColor(.secondary)

                        if let desc = loc.description {
                            Text(desc)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)

                    // Save & Write Review buttons
                    HStack(spacing: 12) {
                        Button {
                            Task { await toggleSave(loc) }
                        } label: {
                            Label(isSaved ? "Saved" : "Save",
                                  systemImage: isSaved ? "heart.fill" : "heart")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    isSaved
                                    ? Color.green
                                    : Color(red: 170/255, green: 64/255, blue: 57/255)
                                )
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
                                        .stroke(Color.gray.opacity(0.3))
                                )
                        }
                    }
                    .padding(.horizontal)

                    HStack(spacing: 12) {
                        NavigationLink {
                            ChatRoomView(location: loc)
                        } label: {
                            Label("Chat", systemImage: "bubble.left.and.bubble.right.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }

                        NavigationLink {
                            ChatBotView(location: loc)
                        } label: {
                            Label("AI Guide", systemImage: "sparkles")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)

                    // Optional Check-in section
                    if showCheckIn {
                        Button {
                            Task { await checkIn(loc) }
                        } label: {
                            Label("Check In (+ 10 points)", systemImage: "checkmark.seal.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isSaved ? Color(red: 170/255, green: 64/255, blue: 57/255) : Color.gray.opacity(0.4))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(!isSaved)
                        .padding(.horizontal)

                        if let msg = checkInMessage {
                            Text(msg)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                    }

                    // Navigate button
                    Button {
                        Navigator.openInMaps(urlString: loc.maps_url)
                    } label: {
                        Label("Navigate", systemImage: "location.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 170/255, green: 64/255, blue: 57/255))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    // Reviews section
                    if !reviews.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reviews")
                                .font(.headline)
                                .padding(.top, 8)

                            ForEach(reviews) { item in
                                let r = item.review

                                VStack(alignment: .leading, spacing: 6) {
                                    // Stars for rating
                                    starRow(for: r.rating)

                                    if !r.comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        Text(r.comment)
                                    }

                                    Text(r.created_at)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                                .shadow(radius: 0.5)
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        // Optional empty state when there are no reviews
                        Text("No reviews yet. Be the first to write one!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }
                }
            } else {
                Text("No location selected")
                    .padding()
            }
        }
        .navigationTitle(location?.name ?? "Details")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadDetailAndReviews() }
        .sheet(isPresented: $showingReviewSheet) {
            if let loc = location {
                WriteReviewView(locationId: loc.id) { rating, comment in
                    Task {
                        await submitReview(locationId: loc.id,
                                           rating: rating,
                                           comment: comment)
                    }
                }
            }
        }
    }

    // MARK: - Data loading

    private func loadDetailAndReviews() async {
        guard let loc = location, let uid = authVM.userId else { return }

        detail = try? await LocationService.shared.getLocationDetail(locationId: loc.id)

        do {
            reviews = try await ReviewService.shared.reviewsForLocation(userId: uid, locationId: loc.id)
        } catch {
            print("Failed to load reviews: \(error)")
            reviews = []
        }

        let savedRows = (try? await InteractionService.shared
            .getSaved(userId: uid)) ?? []

        isSaved = savedRows.contains(where: { $0.location_id == loc.id })
    }

    // MARK: - Actions

    private func toggleSave(_ loc: LocationResponse) async {
        guard let uid = authVM.userId else { return }

        if isSaved {
            _ = try? await InteractionService.shared
                .unsave(locationId: loc.id, userId: uid)
            isSaved = false
        } else {
            _ = try? await InteractionService.shared
                .save(locationId: loc.id, userId: uid)
            isSaved = true
        }
    }

    private func submitReview(locationId: String, rating: Int, comment: String) async {
        guard let uid = authVM.userId else { return }

        _ = try? await ReviewService.shared
            .createReview(userId: uid,
                          locationId: locationId,
                          rating: rating,
                          comment: comment)

        _ = try? await InteractionService.shared
            .recordVisit(locationId: locationId, userId: uid)

        await loadDetailAndReviews()
    }

    private func checkIn(_ loc: LocationResponse) async {
        guard let uid = authVM.userId else { return }
        guard isSaved else {
            checkInMessage = "Save this location before checking in."
            return
        }

        do {
            let res = try await InteractionService.shared
                .recordVisit(locationId: loc.id, userId: uid)
            if let points = res.points_awarded, let level = res.level {
                checkInMessage = "Checked in! +\(points) points (Level \(level))"
            } else {
                checkInMessage = res.message
            }
            isSaved = false
        } catch {
            checkInMessage = "Check-in failed. Please try again."
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func starRow(for rating: Int) -> some View {
        let maroon = Color(red: 176/255, green: 62/255, blue: 55/255)

        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { idx in
                Image(systemName: idx <= rating ? "star.fill" : "star")
                    .font(.caption)
                    .foregroundColor(maroon)
            }
        }
    }
}
