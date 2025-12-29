//
//  MainAppView.swift
//  StoryRide
//
//  Main app container with unified 3-tab navigation
//

import SwiftUI

// MARK: - Main App View

struct MainAppView: View {
    @State private var currentProfile: UserProfile
    @State private var selectedTab = 0

    let profiles: [UserProfile] = [
        UserProfile(name: "Leo", role: .teen, avatarEmoji: "🎸"),
        UserProfile(name: "Mom", role: .parent, avatarEmoji: "👩"),
        UserProfile(name: "Mia", role: .child, avatarEmoji: "🌟"),
        UserProfile(name: "Grandma", role: .elder, avatarEmoji: "❤️")
    ]

    init() {
        // Default to parent profile
        _currentProfile = State(initialValue: UserProfile(name: "Mom", role: .parent, avatarEmoji: "👩"))
    }

    var currentTheme: PersonaTheme {
        ThemeFactory.theme(for: currentProfile.role)
    }

    var body: some View {
        Group {
            switch currentProfile.role {
            case .teen:
                TeenNavigation(
                    selectedTab: $selectedTab,
                    currentProfile: $currentProfile,
                    profiles: profiles
                )
            case .parent:
                ParentNavigation(
                    selectedTab: $selectedTab,
                    currentProfile: $currentProfile,
                    profiles: profiles
                )
            case .child:
                ChildNavigation(
                    currentProfile: $currentProfile,
                    profiles: profiles
                )
            case .elder:
                ElderNavigation(
                    currentProfile: $currentProfile,
                    profiles: profiles
                )
            }
        }
        .themed(currentTheme)
        .animation(currentTheme.animation, value: currentProfile.role)
    }
}

// MARK: - Tab Enum

enum AppTab: Int {
    case home = 0
    case family = 1
    case profile = 2
}

// MARK: - Teen Navigation (Minimal Floating Bar - 3 Tabs)

struct TeenNavigation: View {
    @Binding var selectedTab: Int
    @Binding var currentProfile: UserProfile
    let profiles: [UserProfile]
    @Environment(\.theme) var theme

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            TabView(selection: $selectedTab) {
                HubView()
                    .tag(AppTab.home.rawValue)

                MyFamilyView()
                    .tag(AppTab.family.rawValue)

                ProfileView()
                    .tag(AppTab.profile.rawValue)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Custom floating tab bar
            HStack(spacing: 40) {
                Button(action: { selectedTab = AppTab.home.rawValue }) {
                    Image(systemName: selectedTab == AppTab.home.rawValue ? "house.fill" : "house")
                        .font(.title2)
                        .foregroundColor(selectedTab == AppTab.home.rawValue ? theme.accentColor : .white.opacity(0.6))
                }

                Button(action: { selectedTab = AppTab.family.rawValue }) {
                    Image(systemName: selectedTab == AppTab.family.rawValue ? "person.2.fill" : "person.2")
                        .font(.title2)
                        .foregroundColor(selectedTab == AppTab.family.rawValue ? theme.accentColor : .white.opacity(0.6))
                }

                Button(action: { selectedTab = AppTab.profile.rawValue }) {
                    Image(systemName: selectedTab == AppTab.profile.rawValue ? "person.fill" : "person")
                        .font(.title2)
                        .foregroundColor(selectedTab == AppTab.profile.rawValue ? theme.accentColor : .white.opacity(0.6))
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 40)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.2), radius: 12, y: 4)
            )
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Parent Navigation (Standard Tab Bar - 3 Tabs)

struct ParentNavigation: View {
    @Binding var selectedTab: Int
    @Binding var currentProfile: UserProfile
    let profiles: [UserProfile]

    var body: some View {
        TabView(selection: $selectedTab) {
            HubView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(AppTab.home.rawValue)

            MyFamilyView()
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
        .tint(.brandIndigo)
    }
}

// MARK: - Child Navigation (No Tab Bar, Linear Flow - Unchanged)

struct ChildNavigation: View {
    @Binding var currentProfile: UserProfile
    let profiles: [UserProfile]
    @State private var currentView: ChildView = .hub

    enum ChildView {
        case hub
        case profile
    }

    var body: some View {
        ZStack(alignment: .top) {
            switch currentView {
            case .hub:
                HubView()
            case .profile:
                ProfileView()
            }

            // Simple navigation arrows
            HStack {
                Spacer()

                Button(action: {
                    withAnimation {
                        currentView = currentView == .hub ? .profile : .hub
                    }
                }) {
                    Image(systemName: currentView == .hub ? "star.fill" : "house.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.playfulOrange)
                        .padding()
                        .background(
                            Circle()
                                .fill(.white)
                                .shadow(color: .playfulOrange.opacity(0.3), radius: 8)
                        )
                }
            }
            .padding()
        }
    }
}

// MARK: - Elder Navigation (Single Screen - Unchanged)

struct ElderNavigation: View {
    @Binding var currentProfile: UserProfile
    let profiles: [UserProfile]

    var body: some View {
        VStack {
            // Single screen - Hub
            HubView()
        }
    }
}

// MARK: - Preview

struct MainAppView_Previews: PreviewProvider {
    static var previews: some View {
        MainAppView()
    }
}
