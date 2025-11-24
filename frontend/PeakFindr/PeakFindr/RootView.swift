
import SwiftUI

struct RootView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        Group {
            if authVM.isAuthenticated {
                ContentView()
            } else {
                NavigationStack { AuthLandingView() }
            }
        }
        .onAppear { authVM.restoreSession() }
    }
}
