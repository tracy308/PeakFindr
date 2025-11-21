
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                DiscoveryView()
            }
            .tabItem {
                Label("Discover", systemImage: "sparkles")
            }

            NavigationStack {
                SocialHubView()
            }
            .tabItem {
                Label("Social", systemImage: "bubble.left.and.bubble.right")
            }

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
        }
    }
}
