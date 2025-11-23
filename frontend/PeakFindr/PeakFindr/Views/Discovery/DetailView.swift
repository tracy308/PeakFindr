
import SwiftUI

struct DetailView: View {
    @EnvironmentObject var authVM: AuthViewModel
    var location: LocationResponse?
    var showCheckIn: Bool = false

    @State private var detail: LocationDetailResponse?
    @State private var reviews: [ReviewWithPhotos] = []
    @State private var isSaved = false
    @State private var showingReviewSheet = false
    @State private var checkInMessage: String? = nil

    var body: some View {
        ScrollView {
            if let loc = location {
                VStack(alignment: .leading, spacing: 12) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 260)
                        .overlay(Text(loc.name).font(.title2).bold())

                    VStack(alignment: .leading, spacing: 8) {
                        Text(loc.name).font(.title2).bold()
                        Text(loc.area ?? "Hong Kong").foregroundColor(.secondary)
                        if let desc = loc.description { Text(desc).foregroundColor(.secondary) }
                    }
                    .padding(.horizontal)

                    HStack(spacing: 12) {
                        Button {
                            Task { await toggleSave(loc) }
                        } label: {
                            Label(isSaved ? "Saved" : "Save", systemImage: isSaved ? "heart.fill" : "heart")
                                .frame(maxWidth: .infinity).padding()
                                .background(isSaved ? Color.green : Color(red: 170/255, green: 64/255, blue: 57/255))
                                .foregroundColor(.white).cornerRadius(10)
                        }

                        Button {
                            showingReviewSheet = true
                        } label: {
                            Label("Write Review", systemImage: "square.and.pencil")
                                .frame(maxWidth: .infinity).padding()
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3)))
                        }
                    }
                    .padding(.horizontal)

                    if showCheckIn {
                        Button {
                            Task { await checkIn(loc) }
                        } label: {
                            Label("Check In (+points)", systemImage: "checkmark.seal.fill")
                                .frame(maxWidth: .infinity).padding()
                                .background(Color(red: 170/255, green: 64/255, blue: 57/255))
                                .foregroundColor(.white).cornerRadius(10)
                        }
                        .padding(.horizontal)

                        if let msg = checkInMessage {
                            Text(msg)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                    }

                    Button {
                        Navigator.openInMaps(urlString: loc.maps_url)
                    } label: {
                        Label("Navigate", systemImage: "location.fill")
                            .frame(maxWidth: .infinity).padding()
                            .background(Color(red: 170/255, green: 64/255, blue: 57/255))
                            .foregroundColor(.white).cornerRadius(10)
                    }
                    .padding(.horizontal)

                    if !reviews.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reviews").font(.headline).padding(.top, 8)
                            ForEach(reviews) { item in
                                let r = item.review
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Rating: \(r.rating)/5").bold()
                                    Text(r.comment)
                                    Text(r.created_at).font(.caption).foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                                .shadow(radius: 0.5)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            } else {
                Text("No location selected").padding()
            }
        }
        .navigationTitle(location?.name ?? "Details")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadDetailAndReviews() }
        .sheet(isPresented: $showingReviewSheet) {
            if let loc = location {
                WriteReviewView(locationId: loc.id) { rating, comment in
                    Task { await submitReview(locationId: loc.id, rating: rating, comment: comment) }
                }
            }
        }
    }

    private func loadDetailAndReviews() async {
        guard let loc = location, let uid = authVM.userId else { return }
        detail = try? await LocationService.shared.getLocationDetail(locationId: loc.id)
        reviews = (try? await ReviewService.shared.reviewsForLocation(userId: uid, locationId: loc.id)) ?? []
        let savedRows = (try? await InteractionService.shared.getSaved(userId: uid)) ?? []
        isSaved = savedRows.contains(where: { $0.location_id == loc.id })
    }

    private func toggleSave(_ loc: LocationResponse) async {
        guard let uid = authVM.userId else { return }
        if isSaved {
            _ = try? await InteractionService.shared.unsave(locationId: loc.id, userId: uid)
            isSaved = false
        } else {
            _ = try? await InteractionService.shared.save(locationId: loc.id, userId: uid)
            isSaved = true
        }
    }

    private func submitReview(locationId: String, rating: Int, comment: String) async {
        guard let uid = authVM.userId else { return }
        _ = try? await ReviewService.shared.createReview(userId: uid, locationId: locationId, rating: rating, comment: comment)
        _ = try? await InteractionService.shared.recordVisit(locationId: locationId, userId: uid)
        await loadDetailAndReviews()
    }

    private func checkIn(_ loc: LocationResponse) async {
        guard let uid = authVM.userId else { return }
        let res = try? await InteractionService.shared.recordVisit(locationId: loc.id, userId: uid)
        checkInMessage = res?.message ?? "Checked in!"
    }
}
