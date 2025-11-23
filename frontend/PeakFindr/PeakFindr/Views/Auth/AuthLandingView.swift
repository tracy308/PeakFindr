
import SwiftUI

struct AuthLandingView: View {
    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "mountain.2.fill")
                .font(.system(size: 64))
                .foregroundColor(Color(red: 170/255, green: 64/255, blue: 57/255))

            Text("Peakfindr")
                .font(.largeTitle).bold()

            Text("Swipe hidden gems, save your next adventure, and explore together.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 24)

            NavigationLink {
                LoginView()
            } label: {
                Text("Log In")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 170/255, green: 64/255, blue: 57/255))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)

            NavigationLink {
                RegisterView()
            } label: {
                Text("Create Account")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
            }
            .padding(.horizontal)

            Spacer()
            Text("Mock mode is ON. Toggle it in APIClient.useMockServer.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
        }
        .navigationTitle("")
        .navigationBarHidden(true)
    }
}
