import Foundation
internal import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userId: String? = nil
    @Published var username: String = ""
    @Published var email: String = ""

    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    func restoreSession() {
        if let id = UserIdStore.shared.load() {
            self.userId = id
            self.isAuthenticated = true
        }
    }

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let res = try await AuthService.shared.login(email: email, password: password)
            self.userId = res.user_id
            self.username = res.username
            self.email = res.email

            // save user ID in Keychain
            UserIdStore.shared.save(userId: res.user_id)

            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
            isAuthenticated = false
        }
        isLoading = false
    }

    func register(email: String, username: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let res = try await AuthService.shared.register(email: email, username: username, password: password)
            self.userId = res.user_id
            self.username = res.username
            self.email = res.email

            UserIdStore.shared.save(userId: res.user_id)

            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
            isAuthenticated = false
        }
        isLoading = false
    }

    func logout() {
        UserIdStore.shared.clear()
        userId = nil
        username = ""
        email = ""
        isAuthenticated = false
    }
}
