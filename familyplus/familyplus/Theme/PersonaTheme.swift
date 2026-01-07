//
//  PersonaTheme.swift
//  StoryRide
//
//  Adaptive theme system with Dark/Light mode support
//

import SwiftUI

// MARK: - App Theme Types

public enum AppTheme: String, Codable, CaseIterable {
    case dark
    case light

    var displayName: String {
        switch self {
        case .dark: return "Dark"
        case .light: return "Light"
        }
    }

    var icon: String {
        switch self {
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        }
    }
}

// MARK: - App Theme Protocol

public protocol PersonaTheme {
    var role: AppTheme { get }

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

// MARK: - Dark Theme

struct DarkTheme: PersonaTheme {
    let role: AppTheme = .dark

    // Colors - Dark mode aesthetic (#000000, #5856D6, #1C1C1E)
    let backgroundColor = Color(red: 0.0, green: 0.0, blue: 0.0)
    let textColor = Color(red: 1.0, green: 1.0, blue: 1.0)
    let secondaryTextColor = Color(red: 1.0, green: 1.0, blue: 1.0).opacity(0.7)
    let accentColor = Color(red: 0.345, green: 0.337, blue: 0.839)
    let cardBackgroundColor = Color(red: 0.110, green: 0.110, blue: 0.118)

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

// MARK: - Light Theme

struct LightTheme: PersonaTheme {
    let role: AppTheme = .light

    // Colors - Light mode, clean (#FFFFFF, #5856D6, #F2F2F7)
    let backgroundColor = Color(red: 1.0, green: 1.0, blue: 1.0)
    let textColor = Color(red: 0.0, green: 0.0, blue: 0.0)
    let secondaryTextColor = Color.gray
    let accentColor = Color(red: 0.345, green: 0.337, blue: 0.839)
    let cardBackgroundColor = Color(red: 0.949, green: 0.949, blue: 0.969)

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

// MARK: - Theme Factory

struct ThemeFactory {
    static func theme(for role: AppTheme) -> PersonaTheme {
        switch role {
        case .dark:
            return DarkTheme()
        case .light:
            return LightTheme()
        }
    }
}

// MARK: - Theme Environment Key

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: PersonaTheme = LightTheme()
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
        switch theme.role {
        case .dark:
            return .dark
        case .light:
            return .light
        }
    }
}

extension View {
    func themed(_ theme: PersonaTheme) -> some View {
        modifier(ThemedView(theme: theme))
    }
}
