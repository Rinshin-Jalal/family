//
//  familyplusApp.swift
//  StoryRide
//
//  Main app entry point
//

import SwiftUI

@main
struct StoryRideApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var valueAnalytics = ValueAnalyticsService.shared
    @StateObject private var deepLinkHandler = DeepLinkHandler.shared

    var body: some Scene {
        WindowGroup {
            MainNavigationFlow()
                .environmentObject(themeManager)
                .environmentObject(deepLinkHandler)
                .onAppear {
                    // Track app open on launch
                    ValueAnalyticsService.shared.onAppOpen()
                }
                .onOpenURL { url in
                    // Handle deep links (custom scheme and universal links)
                    _ = deepLinkHandler.handle(url: url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    // Handle universal links from web browsing
                    _ = deepLinkHandler.handleUniversalLink(userActivity)
                }
        }
    }
}
