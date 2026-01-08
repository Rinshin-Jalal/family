//
//  Color+Extensions.swift
//  StoryRide
//
//  Design system color tokens - Owl Library Aesthetic
//

import SwiftUI

extension Color {
    // MARK: - Base Colors (Warm Neutrals from Owl Feathers)

    /// Dark mode background - Rich espresso (#1A1210)
    static let espressoDark = Color(hex: "1A1210")

    /// Dark mode cards/surfaces - Warm cocoa (#3D2B2B)
    static let cocoaBrown = Color(hex: "3D2B2B")

    /// Mid-tone accent - Owl body tan (#C4A574)
    static let warmTan = Color(hex: "C4A574")

    /// Light mode cards/surfaces - Soft parchment (#F5E6D3)
    static let softParchment = Color(hex: "F5E6D3")

    /// Light mode background - Warm ivory cream (#FFF8F0)
    static let ivoryCream = Color(hex: "FFF8F0")

    // MARK: - Legacy Aliases (for backward compatibility)

    /// @deprecated Use espressoDark instead
    static let inkBlack = espressoDark

    /// @deprecated Use ivoryCream instead
    static let paperWhite = ivoryCream

    /// @deprecated Use softParchment instead
    static let surfaceGrey = softParchment

    /// @deprecated Use cocoaBrown instead
    static let darkGrey = cocoaBrown

    /// @deprecated Use ivoryCream instead
    static let warmYellow = ivoryCream

    // MARK: - Scarf Accents (Brand Identity)

    /// Primary accent - Deep burgundy red from scarf (#8B2942)
    static let burgundyRed = Color(hex: "8B2942")

    /// Secondary accent - Forest green from scarf (#3D6B4F)
    static let forestGreen = Color(hex: "3D6B4F")

    /// Highlight/CTA - Golden amber from owl's eyes (#D4A84A)
    static let owlGold = Color(hex: "D4A84A")

    /// Soft accent background - Light burgundy tint (#F5E1E6)
    static let softBurgundy = Color(hex: "F5E1E6")

    /// Soft accent background - Light green tint (#E1F0E6)
    static let softGreen = Color(hex: "E1F0E6")

    /// Soft accent background - Light gold tint (#FFF5E1)
    static let softGold = Color(hex: "FFF5E1")

    // MARK: - Legacy Accent Aliases

    /// @deprecated Use burgundyRed instead
    static let brandIndigo = burgundyRed

    /// @deprecated Use softBurgundy instead
    static let softIndigo = softBurgundy

    /// @deprecated Use owlGold instead
    static let playfulOrange = owlGold

    // MARK: - Alert Colors

    /// Stop recording, Delete, Errors - Warm red (#C42B2B)
    static let alertRed = Color(hex: "C42B2B")

    // MARK: - Storyteller Colors (Timeline Segments)

    /// Elder segment - Wise gold (#D4A84A)
    static let storytellerElder = Color(hex: "D4A84A")

    /// Parent segment - Grounded green (#3D6B4F)
    static let storytellerParent = Color(hex: "3D6B4F")

    /// Teen segment - Bold burgundy (#8B2942)
    static let storytellerTeen = Color(hex: "8B2942")

    /// Child segment - Playful amber (#C4946A)
    static let storytellerChild = Color(hex: "C4946A")

    // MARK: - Legacy Storyteller Aliases

    /// @deprecated Use storytellerElder instead
    static let storytellerOrange = storytellerElder

    /// @deprecated Use storytellerParent instead
    static let storytellerBlue = storytellerParent

    /// @deprecated Use storytellerTeen instead
    static let storytellerPurple = storytellerTeen

    /// @deprecated Use storytellerChild instead
    static let storytellerGreen = storytellerChild

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
