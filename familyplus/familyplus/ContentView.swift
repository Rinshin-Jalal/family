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
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

    var theme: PersonaTheme {
        themeManager.currentTheme.theme
    }

    var body: some View {
        ZStack {
            // Main navigation content
            if showOnboarding {
                OnboardingView(onComplete: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showOnboarding = false
                    }
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                })
            } else {
                MainTabView(selectedTab: $navigationCoordinator.selectedTab)
                    .environmentObject(navigationCoordinator)
            }

            // Theme toggle (for demo purposes)
            ThemeToggleView()
                .padding()
        }
        .themed(theme)
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

// MARK: - Onboarding View

struct OnboardingView: View {
    let onComplete: () -> Void
    @Environment(\.theme) var theme
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "waveform.badge.mic",
            title: "Capture Family Stories",
            subtitle: "Record and preserve your family's most precious memories with ease"
        ),
        OnboardingPage(
            icon: "person.3.fill",
            title: "Connect Generations",
            subtitle: "Bring together your whole family, from grandlights to kids"
        ),
        OnboardingPage(
            icon: "sparkles",
            title: "Create Lasting Memories",
            subtitle: "Build a treasure trove of stories that will last forever"
        )
    ]

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [theme.accentColor.opacity(0.2), theme.backgroundColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button(action: onComplete) {
                        Text("Skip")
                            .font(.headline)
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }
                .padding()

                Spacer()

                // Onboarding content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: 400)

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? theme.accentColor : theme.secondaryTextColor.opacity(0.4))
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 40)

                // Action button
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage += 1
                        }
                    } else {
                        onComplete()
                    }
                }) {
                    HStack {
                        Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                            .font(.headline)
                        if currentPage < pages.count - 1 {
                            Image(systemName: "arrow.right")
                                .font(.headline)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(theme.accentColor)
                    .clipShape(Capsule())
                    .shadow(color: theme.accentColor.opacity(0.4), radius: 12, y: 6)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
            }
        }
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 32) {
            // Icon
            ZStack {
                Circle()
                    .fill(theme.accentColor.opacity(0.15))
                    .frame(width: 180, height: 180)

                Circle()
                    .fill(theme.accentColor.opacity(0.1))
                    .frame(width: 140, height: 140)

                Image(systemName: page.icon)
                    .font(.system(size: 64))
                    .foregroundColor(theme.accentColor)
            }
            .padding(.top, 60)

            // Text
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.title.bold())
                    .foregroundColor(theme.textColor)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.title3)
                    .foregroundColor(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    MainNavigationFlow()
        .themed(DarkTheme())
}
