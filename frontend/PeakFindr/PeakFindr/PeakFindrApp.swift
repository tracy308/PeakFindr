
import SwiftUI

@main
struct PeakfindrApp: App {
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var discoveryVM = DiscoveryViewModel()
    @StateObject private var profileVM = ProfileViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authVM)
                .environmentObject(discoveryVM)
                .environmentObject(profileVM)
        }
    }
}
