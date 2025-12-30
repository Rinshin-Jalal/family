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
            .animation(currentTheme.animation, value: selectedTab)
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

            ProfileView()
                .tabItem {
                    Label("Family", systemImage: "person.2.fill")
                }
                .tag(AppTab.family.rawValue)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
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
    let id = UUID()
    let title: String
    let storyteller: String
    let imageURL: String?
    let voiceCount: Int
    let timestamp: Date
    var storytellerColor: Color {
        //        switch  {
        //            case .elder:
        //                return .storytellerOrange
        //            case .parent:
        //                return .storytellerBlue
        //            case .teen:
        //                return .storytellerPurple
        //            case .child:
        //                return .storytellerGreen
        //            }
        //        }
        .storytellerPurple
    }
}

// MARK: - Sample Stories

extension Story {
    static let sampleStories: [Story] = [
        Story(
            title: "The Summer Road Trip of '68",
            storyteller: "Grandma Rose",
            imageURL: nil,
            voiceCount: 3,
            timestamp: Date().addingTimeInterval(-3600),
        ),
        Story(
            title: "My First Day at School",
            storyteller: "Dad",
            imageURL: nil,
            voiceCount: 2,
            timestamp: Date().addingTimeInterval(-7200),
        ),
        Story(
            title: "The Best Birthday Ever",
            storyteller: "Mia",
            imageURL: nil,
            voiceCount: 1,
            timestamp: Date().addingTimeInterval(-10800),
        ),
        Story(
            title: "When I Met Your Grandfather",
            storyteller: "Grandma Rose",
            imageURL: nil,
            voiceCount: 4,
            timestamp: Date().addingTimeInterval(-14400),
        ),
        Story(
            title: "My Favorite Toy",
            storyteller: "Leo",
            imageURL: nil,
            voiceCount: 1,
            timestamp: Date().addingTimeInterval(-18000),

        )
    ]
}
