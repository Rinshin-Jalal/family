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

    var body: some Scene {
        WindowGroup {
            MainNavigationFlow()
                .environmentObject(themeManager)
                .onAppear {
                    // Track app open on launch
                    ValueAnalyticsService.shared.onAppOpen()
                }
        }
    }
}
