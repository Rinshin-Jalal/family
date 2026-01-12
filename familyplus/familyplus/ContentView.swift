//
//  ContentView.swift
//  familyplus
//
//  Main app navigation flow with adaptive themes
//

import SwiftUI
import Combine

// MARK: - Theme Manager

public enum ThemeMode: Equatable {
    case dark
    case light

    public var theme: PersonaTheme {
        switch self {
        case .dark: return DarkTheme()
        case .light: return LightTheme()
        }
    }

    public init(for appTheme: AppTheme) {
        switch appTheme {
        case .dark: self = .dark
        case .light: self = .light
        }
    }
}

open class ThemeManager: ObservableObject {
    @Published public var currentTheme: ThemeMode = .light

    public func setTheme(_ appTheme: AppTheme) {
        currentTheme = ThemeMode(for: appTheme)
    }
}

// MARK: - Main Navigation Flow

struct MainNavigationFlow: View {
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var navigationCoordinator = NavigationCoordinator.shared
    @ObservedObject private var authService = AuthService.shared
    @State private var showOnboarding: Bool = false

    var theme: PersonaTheme {
        themeManager.currentTheme.theme
    }

    var body: some View {
        ZStack {
            // Main navigation content
            if showOnboarding {
                // Empty background - onboarding covers everything
                Color.clear
            } else {
                MainTabView(selectedTab: $navigationCoordinator.selectedTab)
                    .environmentObject(navigationCoordinator)
            }

            // Fullscreen onboarding overlay
            if showOnboarding {
                AuthOnboardingView {
                    // Onboarding complete - hide onboarding
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showOnboarding = false
                    }
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                }
                .ignoresSafeArea(.all)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(9999)
            }

            // Theme toggle (hide during onboarding)
            if !showOnboarding {
                ThemeToggleView()
                    .padding()
            }
        }
        .themed(theme)
        .onAppear {
            updateOnboardingState()
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("AuthStateDidChange"))) { _ in
            updateOnboardingState()
        }
    }

    private func updateOnboardingState() {
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        withAnimation {
            showOnboarding = !hasCompletedOnboarding || !authService.isAuthenticated
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @Binding var selectedTab: MainTab
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @Environment(\.theme) var theme

    var body: some View {
        TabView(selection: $selectedTab) {
            HubView()
                .tabItem {
                    Label("Hub", systemImage: MainTab.hub.icon)
                }
                .tag(MainTab.hub)

            FamilyView()
                .environmentObject(navigationCoordinator)
                .tabItem {
                    Label("Family", systemImage: MainTab.family.icon)
                }
                .tag(MainTab.family)
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: MainTab.settings.icon)
                }
                .tag(MainTab.settings)
        }
        .tint(theme.accentColor)
        .onAppear {
            // Customize tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(theme.cardBackgroundColor)
            UITabBar.appearance().standardAppearance = appearance
        }
    }
}

// MARK: - Theme Toggle View

struct ThemeToggleView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.theme) var theme

    var body: some View {
        VStack {
            Spacer()

            HStack {
                Spacer()

                Button(action: {
                    themeManager.setTheme(theme.role == .dark ? .light : .dark)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: theme.role == .dark ? "sun.max.fill" : "moon.fill")
                            .font(.caption)
                        Text(theme.role.displayName)
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.6))
                    )
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
    }
}

#Preview {
    MainNavigationFlow()
        .themed(DarkTheme())
}
