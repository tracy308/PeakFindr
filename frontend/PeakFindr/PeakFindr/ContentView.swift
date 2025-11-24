
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var profileVM: ProfileViewModel

    var body: some View {
        TabView {
            NavigationStack { DiscoveryView() }
                .tabItem { Label("Discover", systemImage: "sparkles") }

            NavigationStack { SavedLocationsView() }
                .tabItem { Label("Saved", systemImage: "heart.fill") }

            NavigationStack { SocialHubView() }
                .tabItem { Label("Social", systemImage: "bubble.left.and.bubble.right") }

            NavigationStack {
                ProfileView(onLogout: { authVM.logout() })
            }
            .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
        .tint(Color(red: 176/255, green: 62/255, blue: 55/255))
        
        .onAppear {
            if let uid = authVM.userId {
                profileVM.refreshAll(userId: uid, username: authVM.username, email: authVM.email)
            }
        }
    }
}
