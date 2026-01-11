//
//  MainAppView.swift
//  StoryRide
//
//  Main app container with unified navigation
//

import SwiftUI

// MARK: - Main App View

struct MainAppView: View {
    @State private var selectedTab = 0

    var currentTheme: PersonaTheme {
        ThemeFactory.theme(for: AppTheme.dark)
    }

    var body: some View {
        MainNavigation(selectedTab: $selectedTab)
            .themed(currentTheme)
    }
}

// MARK: - Tab Enum

enum AppTab: Int {
    case home = 0
    case family = 1
    case profile = 2
}

// MARK: - Main Navigation

struct MainNavigation: View {
    @Binding var selectedTab: Int
    @Environment(\.theme) var theme

    var body: some View {
        TabView(selection: $selectedTab) {
            HubView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(AppTab.home.rawValue)

            FamilyView()
                .tabItem {
                    Label("Family", systemImage: "person.2.fill")
                }
                .tag(AppTab.family.rawValue)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "person.fill")
                }
                .tag(AppTab.profile.rawValue)
        }
        .tint(theme.accentColor)
    }
}

// MARK: - Preview

struct MainAppView_Previews: PreviewProvider {
    static var previews: some View {
        MainAppView()
    }
}
// MARK: - Story Model

struct Story: Identifiable {
    let id: String
    let title: String
    let storyteller: String
    let imageURL: String?
    let voiceCount: Int
    let timestamp: Date
    var storytellerColor: Color {
        .storytellerPurple
    }

    // Helper to create from StoryData (API model)
    static func from(storyData: StoryData, memberName: String? = nil) -> Story {
        Story(
            id: storyData.id,
            title: storyData.title ?? storyData.promptText ?? "Untitled Story",
            storyteller: memberName ?? "Family Member",
            imageURL: storyData.coverImageUrl,
            voiceCount: storyData.voiceCount,
            timestamp: storyData.createdAtDate
        )
    }
}
