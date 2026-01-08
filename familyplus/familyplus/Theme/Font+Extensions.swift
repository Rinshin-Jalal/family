//
//  Font+Extensions.swift
//  StoryRide
//
//  Design system typography - Simple dark/light themes
//

import SwiftUI

extension Font {
    // MARK: - Theme-based Typography

    /// Headline font based on current theme
    static func themedHeadline(for theme: PersonaTheme) -> Font {
        theme.headlineFont
    }

    /// Body font based on current theme
    static func themedBody(for theme: PersonaTheme) -> Font {
        theme.bodyFont
    }

    /// Story text font based on current theme
    static func themedStory(for theme: PersonaTheme) -> Font {
        theme.storyFont
    }

    // MARK: - Direct Access (for convenience)

    /// Dark theme typography
    struct dark {
        static let headline = Font.custom("SF Pro Display", size: 28).weight(.bold)
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let story = Font.custom("New York", size: 20).italic()
    }

    /// Light theme typography
    struct light {
        static let headline = Font.system(size: 24, weight: .semibold, design: .default)
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let story = Font.custom("New York", size: 20)
    }
}

// MARK: - Text Style Extensions

extension Text {
    /// Apply themed headline style
    func themedHeadline(theme: PersonaTheme) -> Text {
        self.font(theme.headlineFont)
    }

    /// Apply themed body style
    func themedBody(theme: PersonaTheme) -> Text {
        self.font(theme.bodyFont)
    }

    /// Apply themed story style
    func themedStory(theme: PersonaTheme) -> Text {
        self.font(theme.storyFont)
    }
}
