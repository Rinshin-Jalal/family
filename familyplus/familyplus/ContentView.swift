//
//  ContentView.swift
//  familyplus
//
//  Main app navigation flow with adaptive tabs per persona
//

import SwiftUI
import Combine

// MARK: - Theme Manager

public enum ThemeWrapper: Equatable {
    case teen
    case parent
    case child
    case elder

    public var theme: PersonaTheme {
        switch self {
        case .teen: return TeenTheme()
        case .parent: return ParentTheme()
        case .child: return ChildTheme()
        case .elder: return ElderTheme()
        }
    }

    public init(for persona: PersonaRole) {
        switch persona {
        case .teen: self = .teen
        case .parent: self = .parent
        case .child: self = .child
        case .elder: self = .elder
        }
    }
}

open class ThemeManager: ObservableObject {
    @Published public var currentTheme: ThemeWrapper = .parent

    public func setPersona(_ persona: PersonaRole) {
        currentTheme = ThemeWrapper(for: persona)
    }
}

// MARK: - Main Navigation Flow

struct MainNavigationFlow: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTab: MainTab = .hub
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
                switch theme.role {
                case .teen:
                    TeenMainTabView(selectedTab: $selectedTab)
                case .parent:
                    ParentMainTabView(selectedTab: $selectedTab)
                case .child:
                    ChildMainTabView(selectedTab: $selectedTab)
                case .elder:
                    ElderMainTabView(selectedTab: $selectedTab)
                }
            }

            // Persona switcher (for demo purposes)
            PersonaSwitcher()
                .padding()
        }
        .themed(theme)
    }
}

// MARK: - Main Tabs

enum MainTab: String, CaseIterable {
    case hub = "Hub"
    case profile = "Profile"

    var icon: String {
        switch self {
        case .hub: return "house.fill"
        case .profile: return "person.fill"
        }
    }
}

// MARK: - Teen Main Tab View (Tab Bar at Bottom)

struct TeenMainTabView: View {
    @Binding var selectedTab: MainTab
    @Environment(\.theme) var theme

    var body: some View {
        TabView(selection: $selectedTab) {
            HubView()
                .tabItem {
                    Label("Hub", systemImage: MainTab.hub.icon)
                }
                .tag(MainTab.hub)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: MainTab.profile.icon)
                }
                .tag(MainTab.profile)
        }
        .tint(theme.accentColor)
        .onAppear {
            // Customize tab bar appearance for teen theme
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(theme.cardBackgroundColor)
            UITabBar.appearance().standardAppearance = appearance
        }
    }
}

// MARK: - Parent Main Tab View (Tab Bar at Bottom)

struct ParentMainTabView: View {
    @Binding var selectedTab: MainTab
    @Environment(\.theme) var theme

    var body: some View {
        TabView(selection: $selectedTab) {
            HubView()
                .tabItem {
                    Label("Home", systemImage: MainTab.hub.icon)
                }
                .tag(MainTab.hub)

            ProfileView()
                .tabItem {
                    Label("Family", systemImage: MainTab.profile.icon)
                }
                .tag(MainTab.profile)
        }
        .tint(theme.accentColor)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(theme.cardBackgroundColor)
            UITabBar.appearance().standardAppearance = appearance
        }
    }
}

// MARK: - Child Main Tab View (Simple Navigation - No Tab Bar)

struct ChildMainTabView: View {
    @Binding var selectedTab: MainTab
    @Environment(\.theme) var theme

    var body: some View {
        ZStack {
            // Content based on selected tab
            Group {
                switch selectedTab {
                case .hub:
                    HubView()
                case .profile:
                    ProfileView()
                }
            }

            // Simple bottom navigation bar
            VStack {
                Spacer()

                HStack(spacing: 40) {
                    // Home button
                    Button(action: { selectedTab = .hub }) {
                        VStack(spacing: 8) {
                            Image(systemName: MainTab.hub.icon)
                                .font(.system(size: 36, weight: .bold))
                            Text("Home")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(selectedTab == .hub ? theme.accentColor : theme.secondaryTextColor)
                        .frame(width: 120, height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedTab == .hub ? theme.accentColor.opacity(0.15) : Color.clear)
                        )
                    }

                    // Profile button
                    Button(action: { selectedTab = .profile }) {
                        VStack(spacing: 8) {
                            Image(systemName: MainTab.profile.icon)
                                .font(.system(size: 36, weight: .bold))
                            Text("My Stuff")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(selectedTab == .profile ? theme.accentColor : theme.secondaryTextColor)
                        .frame(width: 120, height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedTab == .profile ? theme.accentColor.opacity(0.15) : Color.clear)
                        )
                    }
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
                .background(theme.cardBackgroundColor)
            }
        }
    }
}

// MARK: - Elder Main Tab View (Accessible Custom Navigation)

struct ElderMainTabView: View {
    @Binding var selectedTab: MainTab
    @Environment(\.theme) var theme

    var body: some View {
        ZStack {
            // Content based on selected tab
            Group {
                switch selectedTab {
                case .hub:
                    HubView()
                case .profile:
                    ProfileView()
                }
            }

            // Large, accessible bottom navigation
            VStack {
                Spacer()

                HStack(spacing: 20) {
                    // Home button
                    Button(action: { selectedTab = .hub }) {
                        VStack(spacing: 12) {
                            Image(systemName: MainTab.hub.icon)
                                .font(.system(size: 40, weight: .bold))
                            Text("Home")
                                .font(.system(size: 22, weight: .bold))
                        }
                        .foregroundColor(selectedTab == .hub ? .white : theme.textColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(selectedTab == .hub ? theme.accentColor : theme.cardBackgroundColor)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
                    }

                    // Profile button
                    Button(action: { selectedTab = .profile }) {
                        VStack(spacing: 12) {
                            Image(systemName: MainTab.profile.icon)
                                .font(.system(size: 40, weight: .bold))
                            Text("My Profile")
                                .font(.system(size: 22, weight: .bold))
                        }
                        .foregroundColor(selectedTab == .profile ? .white : theme.textColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(selectedTab == .profile ? theme.accentColor : theme.cardBackgroundColor)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 24)
                .background(theme.backgroundColor)
            }
        }
    }
}

// MARK: - Persona Switcher (Demo/Debug)

struct PersonaSwitcher: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.theme) var theme
    @State private var showPersonaPicker = false
    @State private var currentPersona: PersonaRole = .parent

    var body: some View {
        VStack {
            Spacer()

            HStack {
                Spacer()

                Button(action: {
                    showPersonaPicker = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
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
        .sheet(isPresented: $showPersonaPicker) {
            PersonaPickerView(
                currentPersona: $currentPersona
            ) { newPersona in
                themeManager.setPersona(newPersona)
                showPersonaPicker = false
            }
        }
    }
}

struct PersonaPickerView: View {
    @Binding var currentPersona: PersonaRole
    let onSelect: (PersonaRole) -> Void
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    var personas: [(role: PersonaRole, icon: String, name: String)] {
        [
            (.teen, "tshirt.fill", "Teen"),
            (.parent, "figure.2.and.child.holdinghands", "Parent"),
            (.child, "star.fill", "Child"),
            (.elder, "cane.fill", "Elder")
        ]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Choose Your Persona")
                    .font(.title2.bold())
                    .padding(.top)

                LazyVGrid(columns: [GridItem(.flexible())], spacing: 16) {
                    ForEach(personas, id: \.role) { persona in
                        PersonaCard(
                            icon: persona.icon,
                            name: persona.name,
                            isSelected: currentPersona == persona.role
                        ) {
                            onSelect(persona.role)
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()

                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .font(.headline)
                        .foregroundColor(theme.accentColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .padding(.horizontal)
                }
                .padding(.bottom)
            }
            .navigationTitle("Switch Persona")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(theme.accentColor)
                }
            }
        }
    }
}

struct PersonaCard: View {
    let icon: String
    let name: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.theme) var theme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 48))
                    .foregroundColor(isSelected ? theme.accentColor : theme.secondaryTextColor)

                Text(name)
                    .font(.headline)
                    .foregroundColor(isSelected ? theme.accentColor : theme.textColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(theme.accentColor, lineWidth: isSelected ? 3 : 1)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(isSelected ? theme.accentColor.opacity(0.1) : theme.cardBackgroundColor)
                    )
            )
        }
        .buttonStyle(.plain)
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
            subtitle: "Bring together your whole family, from grandparents to kids"
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
        .themed(TeenTheme())
}
