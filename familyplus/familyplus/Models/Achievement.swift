//
//  Achievement.swift
//  StoryRide
//
//  Shared data model for achievements
//

import Foundation

struct Achievement: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let earned: Bool
    let earnedAt: Date?
    let progress: Double?
}
