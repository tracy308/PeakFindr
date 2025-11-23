
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
                    TextEditor(text: $comment).frame(height: 120)
                    Stepper("Rating: \(rating)", value: $rating, in: 1...5)
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
