
import SwiftUI

@main
struct PeakfindrApp: App {
    @StateObject private var discoveryVM = DiscoveryViewModel()
    @StateObject private var profileVM = ProfileViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(discoveryVM)
                .environmentObject(profileVM)
        }
    }
}
