//
//  FamilyMember.swift
//  familyplus
//
//  Created by Rinshin on 31/12/25.
//
import SwiftUI


struct FamilyMember: Identifiable {
    let id = UUID()
    let name: String
    let avatarEmoji: String
    let storyCount: Int
    let weeksStreak: Int
    let status: MemberStatus
    var isElder: Bool = false


    var statusColor: Color {
        switch status {
        case .online: return .green
        case .away: return .orange
        case .offline: return .gray
        }
    }

    var statusText: String {
        switch status {
        case .online: return "Online"
        case .away: return "Away"
        case .offline: return "Offline"
        }
    }

    enum MemberStatus {
        case online
        case away
        case offline
    }

    static let sampleMembers: [FamilyMember] = [
        FamilyMember(name: "Grandma Rose", avatarEmoji: "❤️", storyCount: 15, weeksStreak: 3, status: .offline, isElder: true),
        FamilyMember(name: "Dad",  avatarEmoji: "👨", storyCount: 12, weeksStreak: 4, status: .online),
        FamilyMember(name: "Leo",  avatarEmoji: "🎸", storyCount: 8, weeksStreak: 2, status: .away),
        FamilyMember(name: "Mia", avatarEmoji: "🌟", storyCount: 7, weeksStreak: 3, status: .online)
    ]
}
