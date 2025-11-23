
import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var token: String? = nil
    @Published var userID: String? = nil

    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    func restoreSessionIfPossible() async {
        if let saved = TokenStore.shared.loadToken() {
            token = saved
            isAuthenticated = true
        }
    }

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let res = try await AuthService.shared.login(email: email, password: password)
            token = res.token
            userID = res.user_id
            TokenStore.shared.save(token: res.token)
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
            token = res.token
            userID = res.user_id
            TokenStore.shared.save(token: res.token)
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
            isAuthenticated = false
        }
        isLoading = false
    }

    func logout() {
        isAuthenticated = false
        token = nil
        userID = nil
        TokenStore.shared.clear()
    }
}
