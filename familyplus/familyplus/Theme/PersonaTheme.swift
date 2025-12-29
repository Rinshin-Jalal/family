//
//  PersonaTheme.swift
//  StoryRide
//
//  Adaptive theme system that morphs UI based on user persona
//

import SwiftUI

// MARK: - Persona Types

public enum PersonaRole: String, Codable, CaseIterable {
    case teen
    case parent
    case child
    case elder

    var displayName: String {
        switch self {
        case .teen: return "Teen"
        case .parent: return "Parent"
        case .child: return "Child"
        case .elder: return "Elder"
        }
    }

    var icon: String {
        switch self {
        case .teen: return "music.note"
        case .parent: return "person.fill"
        case .child: return "star.fill"
        case .elder: return "heart.fill"
        }
    }
}

// MARK: - Persona Theme Protocol

public protocol PersonaTheme {
    var role: PersonaRole { get }

    // Colors
    var backgroundColor: Color { get }
    var textColor: Color { get }
    var secondaryTextColor: Color { get }
    var accentColor: Color { get }
    var cardBackgroundColor: Color { get }

    // Typography
    var headlineFont: Font { get }
    var bodyFont: Font { get }
    var storyFont: Font { get }

    // Spacing
    var screenPadding: CGFloat { get }
    var cardRadius: CGFloat { get }
    var buttonHeight: CGFloat { get }
    var touchTarget: CGFloat { get }

    // Motion
    var animation: Animation { get }
    var transitionDuration: Double { get }

    // Features
    var showNavigation: Bool { get }
    var enableAudioPrompts: Bool { get }
    var enableHaptics: Bool { get }
}

// MARK: - Teen Theme

struct TeenTheme: PersonaTheme {
    let role: PersonaRole = .teen

    // Colors - Dark mode aesthetic
    let backgroundColor = Color.inkBlack
    let textColor = Color.white
    let secondaryTextColor = Color.white.opacity(0.7)
    let accentColor = Color.brandIndigo
    let cardBackgroundColor = Color.darkGrey

    // Typography - Trendy, tight spacing
    let headlineFont = Font.custom("SF Pro Display", size: 16).weight(.bold)
    let bodyFont = Font.system(size: 17, weight: .regular, design: .default)
    let storyFont = Font.custom("New York", size: 20).italic()

    // Spacing
    let screenPadding: CGFloat = 16
    let cardRadius: CGFloat = 12
    let buttonHeight: CGFloat = 44
    let touchTarget: CGFloat = 44

    // Motion - Snappy, springy
    let animation = Animation.spring(response: 0.3, dampingFraction: 0.7)
    let transitionDuration: Double = 0.25

    // Features
    let showNavigation = true
    let enableAudioPrompts = false
    let enableHaptics = true
}

// MARK: - Parent Theme

struct ParentTheme: PersonaTheme {
    let role: PersonaRole = .parent

    // Colors - Light mode, clean
    let backgroundColor = Color.paperWhite
    let textColor = Color.black
    let secondaryTextColor = Color.gray
    let accentColor = Color.brandIndigo
    let cardBackgroundColor = Color.surfaceGrey

    // Typography - Clear, trustworthy
    let headlineFont = Font.system(size: 16, weight: .semibold, design: .default)
    let bodyFont = Font.system(size: 17, weight: .regular, design: .default)
    let storyFont = Font.custom("New York", size: 20)

    // Spacing
    let screenPadding: CGFloat = 20
    let cardRadius: CGFloat = 16
    let buttonHeight: CGFloat = 48
    let touchTarget: CGFloat = 48

    // Motion - Smooth, ease in/out
    let animation = Animation.easeInOut(duration: 0.3)
    let transitionDuration: Double = 0.3

    // Features
    let showNavigation = true
    let enableAudioPrompts = false
    let enableHaptics = false
}

// MARK: - Child Theme

struct ChildTheme: PersonaTheme {
    let role: PersonaRole = .child

    // Colors - Bright, playful
    let backgroundColor = Color.paperWhite
    let textColor = Color.black
    let secondaryTextColor = Color.gray
    let accentColor = Color.playfulOrange
    let cardBackgroundColor = Color.white

    // Typography - Playful, friendly, large
    let headlineFont = Font.system(size: 32, weight: .heavy, design: .rounded)
    let bodyFont = Font.system(size: 22, weight: .medium, design: .rounded)
    let storyFont = Font.system(size: 24, weight: .medium, design: .rounded)

    // Spacing - Large touch targets
    let screenPadding: CGFloat = 24
    let cardRadius: CGFloat = 24
    let buttonHeight: CGFloat = 80
    let touchTarget: CGFloat = 80

    // Motion - Bouncy, elastic
    let animation = Animation.spring(response: 0.4, dampingFraction: 0.6)
    let transitionDuration: Double = 0.4

    // Features
    let showNavigation = false // Hidden - use arrows
    let enableAudioPrompts = true
    let enableHaptics = true
}

// MARK: - Elder Theme

struct ElderTheme: PersonaTheme {
    let role: PersonaRole = .elder

    // Colors - High contrast, warm
    let backgroundColor = Color.warmYellow
    let textColor = Color.black
    let secondaryTextColor = Color.black.opacity(0.7)
    let accentColor = Color.brandIndigo
    let cardBackgroundColor = Color.white

    // Typography - Maximum legibility
    let headlineFont = Font.system(size: 34, weight: .bold, design: .default)
    let bodyFont = Font.system(size: 28, weight: .medium, design: .default)
    let storyFont = Font.system(size: 28, weight: .medium, design: .default)

    // Spacing - Accessible
    let screenPadding: CGFloat = 32
    let cardRadius: CGFloat = 24
    let buttonHeight: CGFloat = 60
    let touchTarget: CGFloat = 60

    // Motion - Slow, gentle fades
    let animation = Animation.easeInOut(duration: 0.5)
    let transitionDuration: Double = 0.5

    // Features
    let showNavigation = false // One screen at a time
    let enableAudioPrompts = true
    let enableHaptics = false
}

// MARK: - Theme Factory

struct ThemeFactory {
    static func theme(for role: PersonaRole) -> PersonaTheme {
        switch role {
        case .teen:
            return TeenTheme()
        case .parent:
            return ParentTheme()
        case .child:
            return ChildTheme()
        case .elder:
            return ElderTheme()
        }
    }
}

// MARK: - Theme Environment Key

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: PersonaTheme = ParentTheme()
}

extension EnvironmentValues {
    var theme: PersonaTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - Theme Modifier

struct ThemedView: ViewModifier {
    let theme: PersonaTheme

    func body(content: Content) -> some View {
        content
            .environment(\.theme, theme)
            .environment(\.colorScheme, colorScheme(for: theme))
            .background(theme.backgroundColor.ignoresSafeArea())
            .foregroundColor(theme.textColor)
    }

    private func colorScheme(for theme: PersonaTheme) -> ColorScheme {
        // Teen theme uses dark mode for proper text contrast
        switch theme.role {
        case .teen:
            return .dark
        case .parent, .child, .elder:
            return .light
        }
    }
}

extension View {
    func themed(_ theme: PersonaTheme) -> some View {
        modifier(ThemedView(theme: theme))
    }
}
