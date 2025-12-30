struct FamilyMember: Identifiable {
    let id = UUID()
    let name: String
    let role: PersonaRole
    let avatarEmoji: String
    let storyCount: Int
    let weeksStreak: Int
    let status: MemberStatus

    var roleColor: Color {
        switch role {
        case .teen: return .storytellerPurple
        case .parent: return .storytellerBlue
        case .child: return .storytellerGreen
        case .elder: return .storytellerOrange
        }
    }

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
        FamilyMember(name: "Grandma Rose", role: .elder, avatarEmoji: "❤️", storyCount: 15, weeksStreak: 3, status: .offline),
        FamilyMember(name: "Dad", role: .parent, avatarEmoji: "👨", storyCount: 12, weeksStreak: 4, status: .online),
        FamilyMember(name: "Leo", role: .teen, avatarEmoji: "🎸", storyCount: 8, weeksStreak: 2, status: .away),
        FamilyMember(name: "Mia", role: .child, avatarEmoji: "🌟", storyCount: 7, weeksStreak: 3, status: .online)
    ]
}
