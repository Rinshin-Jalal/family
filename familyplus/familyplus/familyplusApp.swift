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

    var body: some Scene {
        WindowGroup {
            MainNavigationFlow()
                .environmentObject(themeManager)
        }
    }
}
