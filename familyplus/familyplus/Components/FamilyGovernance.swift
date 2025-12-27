//
//  FamilyGovernance.swift
//  StoryRide
//
//  Family governance, permissions, and safety controls
//

import SwiftUI

// MARK: - Family Data Model

struct FamilyData {
    let id: String
    let name: String // e.g., "The Rodriguez Family"
    let memberCount: Int
    let storyCount: Int
    let ownerId: String
    let createdAt: Date
    var hasSensitiveTopics: Bool
    var allowsConflictingPerspectives: Bool
}

// MARK: - Permission

struct Permission: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let elderAllowed: Bool
    let parentAllowed: Bool
    let teenAllowed: Bool
    let childAllowed: Bool

    func isAllowed(for role: PersonaRole) -> Bool {
        switch role {
        case .elder: return elderAllowed
        case .parent: return parentAllowed
        case .teen: return teenAllowed
        case .child: return childAllowed
        }
    }

    static let all: [Permission] = [
        Permission(
            name: "Add Prompts",
            description: "Create new story prompts for the family",
            icon: "plus.bubble",
            elderAllowed: false,
            parentAllowed: true,
            teenAllowed: true,
            childAllowed: false
        ),
        Permission(
            name: "Vote on Prompts",
            description: "Vote to prioritize which prompts to answer",
            icon: "hand.thumbsup",
            elderAllowed: false,
            parentAllowed: true,
            teenAllowed: true,
            childAllowed: false
        ),
        Permission(
            name: "Trigger Calls",
            description: "Initiate phone calls to elders for stories",
            icon: "phone.fill",
            elderAllowed: false,
            parentAllowed: true,
            teenAllowed: false,
            childAllowed: false
        ),
        Permission(
            name: "See Sensitive Memories",
            description: "Access to memories marked as sensitive",
            icon: "eye",
            elderAllowed: true,
            parentAllowed: true,
            teenAllowed: false,
            childAllowed: false
        ),
        Permission(
            name: "Invite Members",
            description: "Send invitations to join the family",
            icon: "person.badge.plus",
            elderAllowed: false,
            parentAllowed: true, // Owner only in practice
            teenAllowed: false,
            childAllowed: false
        ),
        Permission(
            name: "Export Audio",
            description: "Download and export story recordings",
            icon: "square.and.arrow.down",
            elderAllowed: false,
            parentAllowed: true,
            teenAllowed: false,
            childAllowed: false
        )
    ]
}

// MARK: - Elder Preferences

struct ElderPreferences {
    var callTimeWindows: [CallTimeWindow]
    var frequency: CallFrequency
    var allowedTopics: [String]
    var disallowedTopics: [String]
    var isOptedOut: Bool

    enum CallFrequency: String, CaseIterable {
        case weekly = "Weekly"
        case biweekly = "Every 2 Weeks"
        case monthly = "Monthly"
        case paused = "Paused"

        var icon: String {
            switch self {
            case .weekly: return "calendar.badge.clock"
            case .biweekly: return "calendar"
            case .monthly: return "calendar.circle"
            case .paused: return "pause.circle"
            }
        }
    }
}

struct CallTimeWindow: Identifiable {
    let id = UUID()
    let dayOfWeek: String // e.g., "Tuesday"
    let startTime: String // e.g., "2:00 PM"
    let endTime: String   // e.g., "4:00 PM"

    var displayString: String {
        "\(dayOfWeek) \(startTime)-\(endTime)"
    }
}

// MARK: - Memory Visibility

enum MemoryVisibility: String, CaseIterable {
    case entireFamily = "Entire Family"
    case adultsOnly = "Adults Only"
    case privateToRecorder = "Private"
    case legacyMode = "Release Later"

    var icon: String {
        switch self {
        case .entireFamily: return "person.3.fill"
        case .adultsOnly: return "person.2.fill"
        case .privateToRecorder: return "lock.fill"
        case .legacyMode: return "clock.fill"
        }
    }

    var color: Color {
        switch self {
        case .entireFamily: return .blue
        case .adultsOnly: return .orange
        case .privateToRecorder: return .red
        case .legacyMode: return .purple
        }
    }

    var description: String {
        switch self {
        case .entireFamily:
            return "Everyone in the family can see this"
        case .adultsOnly:
            return "Only parents and elders can see this"
        case .privateToRecorder:
            return "Only you can see this"
        case .legacyMode:
            return "Will be released at a specified future date"
        }
    }
}

// MARK: - Family Header Component

struct FamilyHeaderCard: View {
    let family: FamilyData
    @Environment(\.theme) var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Stats row
            HStack(spacing: 24) {
                HStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(theme.accentColor)
                    Text("\(family.memberCount) members")
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryTextColor)
                }

                HStack(spacing: 8) {
                    Image(systemName: "book.fill")
                        .foregroundColor(.green)
                    Text("\(family.storyCount) stories")
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryTextColor)
                }
            }

            // Governance indicators
            VStack(alignment: .leading, spacing: 8) {
                if family.hasSensitiveTopics {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("Sensitive topics handled with care")
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }

                if family.allowsConflictingPerspectives {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text("Different perspectives welcome")
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackgroundColor)
        )
    }
}

// MARK: - Permissions Matrix Component

struct PermissionsMatrixView: View {
    @Environment(\.theme) var theme
    @State private var expandedPermission: Permission?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Permissions")
                        .font(.title2.bold())
                        .foregroundColor(theme.textColor)

                    Text("What each role can do in this family")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }

                Spacer()

                // Info button
                Button(action: {}) {
                    Image(systemName: "info.circle")
                        .foregroundColor(theme.accentColor)
                }
            }
            .padding(.horizontal, 20)

            // Permissions list
            VStack(spacing: 12) {
                ForEach(Permission.all) { permission in
                    PermissionRow(
                        permission: permission,
                        isExpanded: expandedPermission?.id == permission.id,
                        onTap: {
                            withAnimation(.spring(response: 0.3)) {
                                if expandedPermission?.id == permission.id {
                                    expandedPermission = nil
                                } else {
                                    expandedPermission = permission
                                }
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackgroundColor)
        )
    }
}

struct PermissionRow: View {
    let permission: Permission
    let isExpanded: Bool
    let onTap: () -> Void
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 0) {
            // Main row
            Button(action: onTap) {
                HStack(spacing: 12) {
                    // Icon
                    Image(systemName: permission.icon)
                        .font(.title3)
                        .foregroundColor(theme.accentColor)
                        .frame(width: 32)

                    // Name
                    Text(permission.name)
                        .font(.subheadline.bold())
                        .foregroundColor(theme.textColor)

                    Spacer()

                    // Role indicators (compact)
                    HStack(spacing: 4) {
                        RoleIndicator(role: .elder, allowed: permission.elderAllowed)
                        RoleIndicator(role: .parent, allowed: permission.parentAllowed)
                        RoleIndicator(role: .teen, allowed: permission.teenAllowed)
                        RoleIndicator(role: .child, allowed: permission.childAllowed)
                    }

                    // Expand chevron
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.tertiarySystemBackground))
                )
            }

            // Expanded description
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Text(permission.description)
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                        .padding(.top, 8)

                    // Detailed role breakdown
                    VStack(alignment: .leading, spacing: 6) {
                        RolePermissionDetail(role: .elder, allowed: permission.elderAllowed)
                        RolePermissionDetail(role: .parent, allowed: permission.parentAllowed)
                        RolePermissionDetail(role: .teen, allowed: permission.teenAllowed)
                        RolePermissionDetail(role: .child, allowed: permission.childAllowed)
                    }
                }
                .padding(12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

struct RoleIndicator: View {
    let role: PersonaRole
    let allowed: Bool

    var roleEmoji: String {
        switch role {
        case .elder: return "👴"
        case .parent: return "👨"
        case .teen: return "🧑"
        case .child: return "🧒"
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(allowed ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                .frame(width: 24, height: 24)

            if allowed {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.green)
            } else {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.gray)
            }
        }
    }
}

struct RolePermissionDetail: View {
    let role: PersonaRole
    let allowed: Bool
    @Environment(\.theme) var theme

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: allowed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(allowed ? .green : .gray)
                .font(.caption)

            Text(role.displayName)
                .font(.caption)
                .foregroundColor(theme.textColor)

            Spacer()

            Text(allowed ? "Allowed" : "Not allowed")
                .font(.caption2)
                .foregroundColor(allowed ? .green : theme.secondaryTextColor)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Elder Preferences View

struct ElderPreferencesView: View {
    let elderName: String
    @State private var preferences: ElderPreferences
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    init(elderName: String, preferences: ElderPreferences = ElderPreferences(
        callTimeWindows: [
            CallTimeWindow(dayOfWeek: "Tuesday", startTime: "2:00 PM", endTime: "4:00 PM"),
            CallTimeWindow(dayOfWeek: "Thursday", startTime: "10:00 AM", endTime: "12:00 PM")
        ],
        frequency: .weekly,
        allowedTopics: ["Childhood", "Career", "Family traditions"],
        disallowedTopics: ["Health issues", "Money"],
        isOptedOut: false
    )) {
        self.elderName = elderName
        self._preferences = State(initialValue: preferences)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Text("👴")
                            .font(.system(size: 64))

                        Text("\(elderName)'s Preferences")
                            .font(.title2.bold())
                            .foregroundColor(theme.textColor)

                        Text("Respecting \(elderName)'s comfort and boundaries")
                            .font(.subheadline)
                            .foregroundColor(theme.secondaryTextColor)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 24)

                    // Opt-out warning (if opted out)
                    if preferences.isOptedOut {
                        HStack(spacing: 12) {
                            Image(systemName: "pause.circle.fill")
                                .foregroundColor(.orange)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Calls Paused")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.orange)

                                Text("\(elderName) has opted out of calls")
                                    .font(.caption)
                                    .foregroundColor(theme.secondaryTextColor)
                            }

                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange.opacity(0.1))
                        )
                    }

                    // Call Frequency
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Call Frequency", systemImage: "calendar")
                            .font(.headline)
                            .foregroundColor(theme.textColor)

                        Picker("Frequency", selection: $preferences.frequency) {
                            ForEach(ElderPreferences.CallFrequency.allCases, id: \.self) { freq in
                                Label(freq.rawValue, systemImage: freq.icon)
                                    .tag(freq)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )

                    // Preferred Call Times
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Preferred Call Times", systemImage: "clock")
                            .font(.headline)
                            .foregroundColor(theme.textColor)

                        ForEach(preferences.callTimeWindows) { window in
                            HStack {
                                Image(systemName: "phone.fill")
                                    .foregroundColor(.green)
                                Text(window.displayString)
                                    .font(.subheadline)
                                    .foregroundColor(theme.textColor)
                                Spacer()
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.tertiarySystemBackground))
                            )
                        }

                        Button(action: {}) {
                            Label("Add Time Window", systemImage: "plus.circle")
                                .font(.subheadline)
                                .foregroundColor(theme.accentColor)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )

                    // Allowed Topics
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Comfortable Topics", systemImage: "checkmark.circle")
                            .font(.headline)
                            .foregroundColor(.green)

                        TopicFlowLayout(spacing: 8) {
                            ForEach(preferences.allowedTopics, id: \.self) { topic in
                                TopicBadge(topic: topic, color: .green)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.05))
                    )

                    // Disallowed Topics
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Topics to Avoid", systemImage: "xmark.circle")
                            .font(.headline)
                            .foregroundColor(.red)

                        TopicFlowLayout(spacing: 8) {
                            ForEach(preferences.disallowedTopics, id: \.self) { topic in
                                TopicBadge(topic: topic, color: .red)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.05))
                    )

                    // Emergency opt-out
                    VStack(spacing: 12) {
                        Divider()

                        Text("Need a break from calls?")
                            .font(.subheadline)
                            .foregroundColor(theme.secondaryTextColor)

                        Button(action: {
                            preferences.isOptedOut.toggle()
                        }) {
                            Label(
                                preferences.isOptedOut ? "Resume Calls" : "Pause All Calls",
                                systemImage: preferences.isOptedOut ? "play.circle" : "pause.circle"
                            )
                            .font(.headline)
                            .foregroundColor(preferences.isOptedOut ? .green : .orange)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(
                                        preferences.isOptedOut ? Color.green : Color.orange,
                                        lineWidth: 2
                                    )
                            )
                        }
                    }
                    .padding(.top, 16)
                }
                .padding(20)
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // TODO: Save preferences to backend
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}

struct TopicBadge: View {
    let topic: String
    let color: Color

    var body: some View {
        Text(topic)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
            )
            .overlay(
                Capsule()
                    .strokeBorder(color.opacity(0.3), lineWidth: 1)
            )
            .foregroundColor(color)
    }
}

// MARK: - Governance Sheet

struct GovernanceSheet: View {
    let familyData: FamilyData
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header message
                    VStack(spacing: 12) {
                        Text("🛡️")
                            .font(.system(size: 64))

                        Text("Family Governance")
                            .font(.title.bold())
                            .foregroundColor(theme.textColor)

                        Text("Understanding how your family works together safely")
                            .font(.subheadline)
                            .foregroundColor(theme.secondaryTextColor)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 24)

                    // Trust indicators
                    VStack(alignment: .leading, spacing: 12) {
                        if familyData.hasSensitiveTopics {
                            TrustIndicator(
                                icon: "checkmark.shield.fill",
                                text: "Sensitive topics handled with care",
                                color: .green
                            )
                        }

                        if familyData.allowsConflictingPerspectives {
                            TrustIndicator(
                                icon: "checkmark.circle.fill",
                                text: "Different perspectives welcome - we never label truth",
                                color: .blue
                            )
                        }

                        TrustIndicator(
                            icon: "lock.fill",
                            text: "Your memories belong to the family, not the app",
                            color: .purple
                        )
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                    )

                    // Permissions Matrix
                    PermissionsMatrixView()

                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct TrustIndicator: View {
    let icon: String
    let text: String
    let color: Color
    @Environment(\.theme) var theme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)

            Text(text)
                .font(.subheadline)
                .foregroundColor(theme.textColor)

            Spacer()
        }
    }
}

// MARK: - Topic Flow Layout

struct TopicFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = TopicFlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = TopicFlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                     y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct TopicFlowResult {
        var size: CGSize
        var positions: [CGPoint]

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var positions: [CGPoint] = []
            var size: CGSize = .zero
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let subviewSize = subview.sizeThatFits(.unspecified)

                if currentX + subviewSize.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, subviewSize.height)
                currentX += subviewSize.width + spacing
                size.width = max(size.width, currentX - spacing)
            }

            size.height = currentY + lineHeight
            self.size = size
            self.positions = positions
        }
    }
}
