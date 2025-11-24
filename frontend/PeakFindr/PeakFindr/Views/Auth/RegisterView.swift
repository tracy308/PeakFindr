
import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var showPassword = false

    var body: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 12)
            Text("Create account").font(.title2).bold()

            VStack(spacing: 12) {
                TextField("Username", text: $username)
                    .textInputAutocapitalization(.words)
                    .padding().background(Color(.systemGray6)).cornerRadius(10)

                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding().background(Color(.systemGray6)).cornerRadius(10)

                HStack {
                    Group {
                        if showPassword { TextField("Password", text: $password) }
                        else { SecureField("Password", text: $password) }
                    }
                    Button { showPassword.toggle() } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye").foregroundColor(.secondary)
                    }
                }
                .padding().background(Color(.systemGray6)).cornerRadius(10)
            }.padding(.horizontal)

            if let err = authVM.errorMessage {
                Text(err).foregroundColor(.red).font(.caption).padding(.horizontal)
            }

            Button {
                Task { await authVM.register(email: email, username: username, password: password) }
            } label: {
                if authVM.isLoading {
                    ProgressView().tint(.white).frame(maxWidth: .infinity).padding()
                } else {
                    Text("Register").frame(maxWidth: .infinity).padding()
                }
            }
            .background(Color(red: 170/255, green: 64/255, blue: 57/255))
            .foregroundColor(.white).cornerRadius(12).padding(.horizontal)

            HStack {
                Text("Already have an account?")
                NavigationLink("Log In") { LoginView() }
            }.font(.footnote).foregroundColor(.secondary)

            Spacer()
        }
        .navigationTitle("Register")
        .navigationBarTitleDisplayMode(.inline)
    }
}
