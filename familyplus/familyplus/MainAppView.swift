//
//  MainAppView.swift
//  StoryRide
//
//  Main app container with adaptive navigation
//

import SwiftUI

// MARK: - Main App View

struct MainAppView: View {
    @State private var currentProfile: UserProfile
    @State private var selectedTab = 0
    @State private var showStudio = false

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
                    showStudio: $showStudio,
                    currentProfile: $currentProfile,
                    profiles: profiles
                )
            case .parent:
                ParentNavigation(
                    selectedTab: $selectedTab,
                    showStudio: $showStudio,
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

// MARK: - Teen Navigation (Minimal Floating Bar)

struct TeenNavigation: View {
    @Binding var selectedTab: Int
    @Binding var showStudio: Bool
    @Binding var currentProfile: UserProfile
    let profiles: [UserProfile]

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            TabView(selection: $selectedTab) {
                HubView()
                    .tag(0)

                ProfileView()
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Custom floating tab bar
            HStack(spacing: 60) {
                Button(action: { selectedTab = 0 }) {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                        .font(.title2)
                        .foregroundColor(selectedTab == 0 ? .brandIndigo : .white.opacity(0.6))
                }

                // Floating action button
                Button(action: { showStudio = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.brandIndigo)
                        .shadow(color: .brandIndigo.opacity(0.3), radius: 12)
                }

                Button(action: { selectedTab = 1 }) {
                    Image(systemName: selectedTab == 1 ? "person.fill" : "person")
                        .font(.title2)
                        .foregroundColor(selectedTab == 1 ? .brandIndigo : .white.opacity(0.6))
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

            // Profile switcher
            VStack {
                HStack {
                    Spacer()
                    ProfileSwitcher(currentProfile: $currentProfile, profiles: profiles)
                }
                .padding()
                Spacer()
            }
        }
        .sheet(isPresented: $showStudio) {
            StudioView()
        }
    }
}

// MARK: - Parent Navigation (Standard Tab Bar)

struct ParentNavigation: View {
    @Binding var selectedTab: Int
    @Binding var showStudio: Bool
    @Binding var currentProfile: UserProfile
    let profiles: [UserProfile]

    var body: some View {
        TabView(selection: $selectedTab) {
            HubView()
                .tabItem {
                    Label("Stories", systemImage: "book.fill")
                }
                .tag(0)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        ProfileSwitcher(currentProfile: $currentProfile, profiles: profiles)
                    }
                }

            ProfileView()
                .tabItem {
                    Label("Family", systemImage: "person.2.fill")
                }
                .tag(1)
        }
        .overlay(alignment: .bottomTrailing) {
            // Floating action button
            Button(action: { showStudio = true }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.brandIndigo)
                    .shadow(color: .brandIndigo.opacity(0.3), radius: 12)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 80)
        }
        .sheet(isPresented: $showStudio) {
            StudioView()
        }
    }
}

// MARK: - Child Navigation (No Tab Bar, Linear Flow)

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
                ProfileSwitcher(currentProfile: $currentProfile, profiles: profiles)

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

// MARK: - Elder Navigation (Single Screen)

struct ElderNavigation: View {
    @Binding var currentProfile: UserProfile
    let profiles: [UserProfile]

    var body: some View {
        VStack {
            // Profile switcher
            HStack {
                Spacer()
                ProfileSwitcher(currentProfile: $currentProfile, profiles: profiles)
            }
            .padding()

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
