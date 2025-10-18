//
//  Layout.swift
//  playground
//
//  Created by Wong Nixon on 18/10/2025.
//

import SwiftUI

struct LayoutView<Content: View>: View {
    @State private var selectedTab: Tab = .discover
    let content: Content

    enum Tab: String, CaseIterable {
        case discover = "Discover"
        case social = "Social"
        case guide = "Guide"
        case profile = "Profile"

        var iconName: String {
            switch self {
            case .discover: return "compass"
            case .social: return "message"
            case .guide: return "sparkles"
            case .profile: return "person"
            }
        }
    }

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    LinearGradient(colors: [Color.red.opacity(0.8), Color.red], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .frame(width: 40, height: 40)
                        .cornerRadius(10)
                        .shadow(color: Color.red.opacity(0.3), radius: 5, x: 0, y: 2)
                    Text("🇭🇰")
                        .font(.system(size: 20))
                }
                VStack(alignment: .leading) {
                    Text("HK Explorer")
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text("Discover Hidden Treasures")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .overlay(Rectangle().frame(height: 1).foregroundColor(Color.gray.opacity(0.1)), alignment: .bottom)
            .zIndex(1)

            // Main content
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(colors: [Color.gray.opacity(0.08), Color.white, Color.red.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .ignoresSafeArea()
                )

            // Bottom tab bar
            HStack {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: tab.iconName)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(selectedTab == tab ? Color.red : Color.gray)
                            .scaleEffect(selectedTab == tab ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: selectedTab)
                        Text(tab.rawValue)
                            .font(.caption2)
                            .foregroundColor(selectedTab == tab ? Color.red : Color.gray)
                            .lineLimit(1)
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedTab = tab
                        // Add actual navigation logic here as needed
                    }
                    Spacer()
                }
            }
            .background(.ultraThinMaterial)
            .overlay(Rectangle().frame(height: 1).foregroundColor(Color.gray.opacity(0.1)), alignment: .top)
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 0) }
        }
    }
}
