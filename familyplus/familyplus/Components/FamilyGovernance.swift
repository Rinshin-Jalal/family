//
//  FamilyGovernance.swift
//  StoryRide
//
//  Family governance, permissions, and safety controls
//

import SwiftUI

// MARK: - Permission

struct Permission: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let isAllowed: Bool
    
    static let all: [Permission] = [
        Permission(
            name: "Add Prompts",
            description: "Create new story prompts for the family",
            icon: "plus.bubble",
            isAllowed: true
        ),
        Permission(
            name: "Vote on Prompts",
            description: "Vote to prioritize which prompts to answer",
            icon: "hand.thumbsup",
            isAllowed: true
        ),
        Permission(
            name: "Trigger Calls",
            description: "Initiate phone calls to elders for stories",
            icon: "phone.fill",
            isAllowed: true
        ),
        Permission(
            name: "See Sensitive Memories",
            description: "Access to memories marked as sensitive",
            icon: "eye",
            isAllowed: true
        ),
        Permission(
            name: "Invite Members",
            description: "Send invitations to join the family",
            icon: "person.badge.plus",
            isAllowed: true
        ),
        Permission(
            name: "Export Audio",
            description: "Download and export story recordings",
            icon: "square.and.arrow.down",
            isAllowed: true
        )
    ]
}

// MARK: - Permissions Matrix Component

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

                    // Permission status indicator
                    Image(systemName: permission.isAllowed ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(permission.isAllowed ? .green : .gray)

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

                    HStack(spacing: 6) {
                        Image(systemName: permission.isAllowed ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(permission.isAllowed ? .green : .gray)
                        Text(permission.isAllowed ? "This permission is enabled" : "This permission is disabled")
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }
                .padding(12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

struct RoleIndicator: View {
    let name: String  // Simple name instead of PersonaRole
    let allowed: Bool

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
    let name: String  // Simple name instead of PersonaRole
    let allowed: Bool
    @Environment(\.theme) var theme

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: allowed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(allowed ? .green : .gray)
                .font(.caption)

            Text(name)
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
