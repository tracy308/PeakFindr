
import SwiftUI

struct WriteReviewView: View {
    var locationId: String
    var onSave: (Int, String) -> Void

    @State private var comment = ""
    @State private var rating = 5
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Your review")) {
                    TextEditor(text: $comment)
                        .frame(height: 120)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rating")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        StarRatingView(rating: $rating)
                    }
                    .padding(.vertical, 4)
                }

            }
            .navigationTitle("Write Review")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        onSave(rating, comment)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct StarRatingView: View {
    @Binding var rating: Int
    let maxRating = 5

    // Your maroon theme color
    private let starColor = Color(red: 176/255, green: 62/255, blue: 55/255)

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 8) {
                ForEach(1...maxRating, id: \.self) { index in
                    Image(systemName: index <= rating ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundColor(starColor)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                rating = index
                            }
                        }
                }
            }
            .contentShape(Rectangle()) // makes drag work across the whole row
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let widthPerStar = geo.size.width / CGFloat(maxRating)
                        var newRating = Int((value.location.x / widthPerStar).rounded(.up))

                        // Clamp between 1 and maxRating
                        newRating = min(max(newRating, 1), maxRating)

                        if newRating != rating {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.9)) {
                                rating = newRating
                            }
                        }
                    }
            )
        }
        .frame(height: 44)
    }
}


