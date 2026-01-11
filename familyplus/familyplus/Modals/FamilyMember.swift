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

    // Create from API data
    static func from(memberData: FamilyMemberData, stories: [StoryData] = []) -> FamilyMember {
        let memberStories = stories.filter { $0.familyId == memberData.id }
        return FamilyMember(
            name: memberData.fullName ?? "Family Member",
            avatarEmoji: "👤", // Default - could load from avatarUrl
            storyCount: memberStories.count,
            status: .online, // Default - TODO: implement real status
            isElder: memberData.role.lowercased().contains("elder")
        )
    }
}
