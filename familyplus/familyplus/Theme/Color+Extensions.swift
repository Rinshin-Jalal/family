//
//  Color+Extensions.swift
//  StoryRide
//
//  Design system color tokens
//

import SwiftUI

extension Color {
    // MARK: - Base Colors

    /// dark Background (#000000)
    static let inkBlack = Color(hex: "000000")

    /// light/Child Background (#FFFFFF)
    static let paperWhite = Color(hex: "FFFFFF")

    /// Elder Background (#FFF9C4) - High contrast warm tone
    static let warmYellow = Color(hex: "FFF9C4")

    /// Cards/Modals Light Mode (#F2F2F7)
    static let surfaceGrey = Color(hex: "F2F2F7")

    /// Cards/Modals Dark Mode (#1C1C1E)
    static let darkGrey = Color(hex: "1C1C1E")

    // MARK: - Accent Colors (Brand Identity)

    /// Primary Buttons, Links, Active States (#5856D6)
    static let brandIndigo = Color(hex: "5856D6")

    /// Secondary backgrounds, tags (#E5E1FA)
    static let softIndigo = Color(hex: "E5E1FA")

    /// Stop recording, Delete, Errors (#FF3B30)
    static let alertRed = Color(hex: "FF3B30")

    /// Child mode accent (#FF9500)
    static let playfulOrange = Color(hex: "FF9500")

    // MARK: - Storyteller Colors (Timeline)

    /// Grandma/Elder segment color
    static let storytellerOrange = Color(hex: "FF9500")

    /// Dad/light segment color
    static let storytellerBlue = Color(hex: "007AFF")

    /// dark segment color
    static let storytellerPurple = Color(hex: "AF52DE")

    /// Child segment color
    static let storytellerGreen = Color(hex: "34C759")

    // MARK: - Hex Initializer

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Semantic Color Extensions

extension Color {
    /// Adaptive text color based on theme
    static func adaptiveText(for theme: PersonaTheme) -> Color {
        theme.textColor
    }

    /// Adaptive background based on theme
    static func adaptiveBackground(for theme: PersonaTheme) -> Color {
        theme.backgroundColor
    }

    /// Adaptive accent based on theme
    static func adaptiveAccent(for theme: PersonaTheme) -> Color {
        theme.accentColor
    }
}
