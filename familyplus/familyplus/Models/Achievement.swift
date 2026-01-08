//
//  Milestone.swift
//  StoryRide
//
//  Content-based milestones - tracking value created, not engagement
//
//  TRANSFORMED FROM: Achievement.swift
//  Changed from gamification (streaks, daily engagement) to value-based milestones
//  (stories preserved, wisdom captured, elders reached)
//

import Foundation

struct Milestone: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let earned: Bool
    let earnedAt: Date?
    let progress: Double?
    let category: MilestoneCategory?

    enum MilestoneCategory {
        case preservation  // Stories saved
        case wisdom        // Wisdom captured
        case connection    // Family members reached
        case anthology     // Collections created
    }
}

// MARK: - Backward Compatibility Helpers

extension Milestone {
    /// Infer category from title/description if not explicitly provided
    static func inferCategory(from title: String, description: String) -> MilestoneCategory? {
        let lowercased = (title + " " + description).lowercased()
        if lowercased.contains("stori") || lowercased.contains("preserv") || lowercased.contains("record") {
            return .preservation
        } else if lowercased.contains("wisdom") || lowercased.contains("lesson") || lowercased.contains("advice") {
            return .wisdom
        } else if lowercased.contains("grandma") || lowercased.contains("grandpa") || lowercased.contains("elder") || lowercased.contains("family") {
            return .connection
        } else if lowercased.contains("antholog") || lowercased.contains("collection") {
            return .anthology
        }
        return nil
    }

    /// Create milestone with auto-inferred category
    static func withAutoCategory(
        title: String,
        description: String,
        icon: String,
        earned: Bool,
        earnedAt: Date? = nil,
        progress: Double? = nil
    ) -> Milestone {
        Milestone(
            title: title,
            description: description,
            icon: icon,
            earned: earned,
            earnedAt: earnedAt,
            progress: progress,
            category: inferCategory(from: title, description: description)
        )
    }
}

// Backward compatibility alias
typealias Achievement = Milestone
