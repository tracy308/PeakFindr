
import SwiftUI

struct WriteReviewView: View {
    var location: Location
    var onSave: (Review) -> Void

    @State private var author = ""
    @State private var text = ""
    @State private var rating = 5.0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Your review")) {
                    TextField("Name", text: $author)
                    TextEditor(text: $text)
                        .frame(height: 120)
                    Stepper("Rating: \(Int(rating))", value: $rating, in: 1...5)
                }
            }
            .navigationTitle("Write Review")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let review = Review(
                            id: UUID(),
                            author: author.isEmpty ? "Anonymous" : author,
                            text: text,
                            rating: rating,
                            date: Date()
                        )
                        onSave(review)
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
