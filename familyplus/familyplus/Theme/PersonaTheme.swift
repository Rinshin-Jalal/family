//
//  PersonaTheme.swift
//  StoryRide
//
//  Adaptive theme system with Dark/Light mode support
//  Owl Library Aesthetic - Scholarly warmth meets cozy storytelling
//

import SwiftUI

// MARK: - App Theme Types

public enum AppTheme: String, Codable, CaseIterable {
    case dark
    case light

    var displayName: String {
        switch self {
        case .dark: return "Scholarly Night"
        case .light: return "Cozy Library"
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

// MARK: - Dark Theme (Scholarly Night)

public struct DarkTheme: PersonaTheme {
    public init() {}
    public let role: AppTheme = .dark

    // Colors - Warm espresso & gold aesthetic
    // Background: Espresso Dark (#1A1210)
    public let backgroundColor = Color(hex: "1A1210")
    // Text: Ivory Cream (#FFF8F0)
    public let textColor = Color(hex: "FFF8F0")
    // Secondary: Warm Tan at 70% (#C4A574)
    public let secondaryTextColor = Color(hex: "C4A574").opacity(0.7)
    // Accent: Owl Gold (#D4A84A)
    public let accentColor = Color(hex: "D4A84A")
    // Cards: Cocoa Brown (#3D2B2B)
    public let cardBackgroundColor = Color(hex: "3D2B2B")

    // Typography - Trendy, tight spacing
    public let headlineFont = Font.custom("SF Pro Display", size: 16).weight(.bold)
    public let bodyFont = Font.system(size: 17, weight: .regular, design: .default)
    public let storyFont = Font.custom("New York", size: 20).italic()

    // Spacing
    public let screenPadding: CGFloat = 16
    public let cardRadius: CGFloat = 12
    public let buttonHeight: CGFloat = 44
    public let touchTarget: CGFloat = 44

    // Motion - Snappy, springy
    public let animation = Animation.spring(response: 0.3, dampingFraction: 0.7)
    public let transitionDuration: Double = 0.25

    // Features
    public let showNavigation = true
    public let enableAudioPrompts = false
    public let enableHaptics = true
}

// MARK: - Light Theme (Cozy Library)

public struct LightTheme: PersonaTheme {
    public init() {}
    public let role: AppTheme = .light

    // Colors - Warm cream & burgundy aesthetic
    // Background: Ivory Cream (#FFF8F0)
    public let backgroundColor = Color(hex: "FFF8F0")
    // Text: Espresso Dark (#1A1210)
    public let textColor = Color(hex: "1A1210")
    // Secondary: Cocoa Brown (#3D2B2B)
    public let secondaryTextColor = Color(hex: "3D2B2B").opacity(0.6)
    // Accent: Burgundy Red (#8B2942)
    public let accentColor = Color(hex: "8B2942")
    // Cards: Soft Parchment (#F5E6D3)
    public let cardBackgroundColor = Color(hex: "F5E6D3")

    // Typography - Clear, trustworthy
    public let headlineFont = Font.system(size: 16, weight: .semibold, design: .default)
    public let bodyFont = Font.system(size: 17, weight: .regular, design: .default)
    public let storyFont = Font.custom("New York", size: 20)

    // Spacing
    public let screenPadding: CGFloat = 20
    public let cardRadius: CGFloat = 16
    public let buttonHeight: CGFloat = 48
    public let touchTarget: CGFloat = 48

    // Motion - Smooth, ease in/out
    public let animation = Animation.easeInOut(duration: 0.3)
    public let transitionDuration: Double = 0.3

    // Features
    public let showNavigation = true
    public let enableAudioPrompts = false
    public let enableHaptics = true
}

// MARK: - Theme Factory

public struct ThemeFactory {
    public static func theme(for role: AppTheme) -> PersonaTheme {
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
    public var theme: PersonaTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - Theme Modifier

public struct ThemedView: ViewModifier {
    public let theme: PersonaTheme

    public func body(content: Content) -> some View {
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
    public func themed(_ theme: PersonaTheme) -> some View {
        modifier(ThemedView(theme: theme))
    }
}
