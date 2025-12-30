//
//  Font+Extensions.swift
//  StoryRide
//
//  Design system typography
//

import SwiftUI

extension Font {
    // MARK: - Adaptive Typography

    /// Adaptive headline font based on persona
    static func adaptiveHeadline(for theme: PersonaTheme) -> Font {
        theme.headlineFont
    }

    /// Adaptive body font based on persona
    static func adaptiveBody(for theme: PersonaTheme) -> Font {
        theme.bodyFont
    }

    /// Adaptive story text font based on persona
    static func adaptiveStory(for theme: PersonaTheme) -> Font {
        theme.storyFont
    }

    // MARK: - dark Typography

    struct dark {
        static let headline = Font.custom("SF Pro Display", size: 28).weight(.bold)
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let story = Font.custom("New York", size: 20).italic()
    }

    // MARK: - light Typography

    struct light {
        static let headline = Font.system(size: 24, weight: .semibold, design: .default)
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let story = Font.custom("New York", size: 20)
    }

    // MARK: - Child Typography

    struct Child {
        static let headline = Font.system(size: 32, weight: .heavy, design: .rounded)
        static let body = Font.system(size: 22, weight: .medium, design: .rounded)
        static let story = Font.system(size: 24, weight: .medium, design: .rounded)
    }

    // MARK: - Elder Typography

    struct Elder {
        static let headline = Font.system(size: 34, weight: .bold, design: .default)
        static let body = Font.system(size: 28, weight: .medium, design: .default)
        static let story = Font.system(size: 28, weight: .medium, design: .default)
    }
}

// MARK: - Text Style Extensions

extension Text {
    /// Apply adaptive headline style
    func adaptiveHeadline(theme: PersonaTheme) -> Text {
        self.font(theme.headlineFont)
    }

    /// Apply adaptive body style
    func adaptiveBody(theme: PersonaTheme) -> Text {
        self.font(theme.bodyFont)
    }

    /// Apply adaptive story style
    func adaptiveStory(theme: PersonaTheme) -> Text {
        self.font(theme.storyFont)
    }
}
