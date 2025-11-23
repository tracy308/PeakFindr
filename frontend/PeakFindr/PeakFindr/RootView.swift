
import SwiftUI

/// Root gate: shows Auth flow if not logged in, otherwise main app.
/// IMPORTANT: Auth flow is embedded in a NavigationStack so NavigationLinks work.
struct RootView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        Group {
            if authVM.isAuthenticated {
                ContentView()
            } else {
                NavigationStack {
                    AuthLandingView()
                }
            }
        }
        .task {
            await authVM.restoreSessionIfPossible()
        }
    }
}
