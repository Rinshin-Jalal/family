//
//  ManageMembersModal.swift
//  familyplus
//
//  Member management interface for viewing, editing, and removing family members
//

import SwiftUI

// MARK: - Manage Members Modal

struct ManageMembersModal: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) var theme

    @State private var searchText = ""
    @State private var selectedMember: FamilyMember?
    @State private var showActionSheet = false
    @State private var showRemoveConfirmation = false
    @State private var showElderPreferences = false
    @State private var showInviteModal = false

    // Sample data - TODO: Replace with actual API data
    @State private var members: [FamilyMember] = FamilyMember.sampleMembers

    var filteredMembers: [FamilyMember] {
        if searchText.isEmpty {
            return members
        }
        return members.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundColor.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search Bar
                    SearchBarView(searchText: $searchText)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 16)

                    if filteredMembers.isEmpty {
                        EmptySearchState(searchText: searchText)
                    } else {
                        // Member List
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredMembers) { member in
                                    MemberRowView(member: member) {
                                        selectedMember = member
                                        showActionSheet = true
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 100) // Space for button
                        }
                    }

                    Spacer()

                    // Add Member Button
                    Button(action: { showInviteModal = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Add Family Member")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(theme.accentColor)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("Manage Members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.accentColor)
                }
            }
        }
        .confirmationDialog(
            selectedMember?.name ?? "Member",
            isPresented: $showActionSheet,
            titleVisibility: .visible
        ) {
            Button("View Profile") {
                // TODO: Navigate to profile
            }

            if selectedMember?.isElder == true {
                Button("Elder Preferences") {
                    showElderPreferences = true
                }
            }

            Button("Remove from Family", role: .destructive) {
                showRemoveConfirmation = true
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            if let member = selectedMember {
                Text("\(member.storyCount) stories recorded")
            }
        }
        .alert("Remove Member?", isPresented: $showRemoveConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                if let member = selectedMember {
                    removeMember(member)
                }
            }
        } message: {
            if let member = selectedMember {
                Text("Are you sure you want to remove \(member.name) from your family? Their stories will remain in the family archive.")
            }
        }
        .sheet(isPresented: $showElderPreferences) {
            if let member = selectedMember {
                ElderPreferencesModal(elderName: member.name)
            }
        }
        .sheet(isPresented: $showInviteModal) {
            InviteFamilyModal()
        }
    }

    private func removeMember(_ member: FamilyMember) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            members.removeAll { $0.id == member.id }
        }
        selectedMember = nil
    }
}

// MARK: - Search Bar View

struct SearchBarView: View {
    @Binding var searchText: String
    @Environment(\.theme) var theme
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(theme.secondaryTextColor)

            TextField("Search members", text: $searchText)
                .font(.body)
                .foregroundColor(theme.textColor)
                .focused($isFocused)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(theme.secondaryTextColor)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Member Row View

struct MemberRowView: View {
    let member: FamilyMember
    let onTap: () -> Void
    @Environment(\.theme) var theme

    var statusColor: Color {
        switch member.status {
        case .online: return .green
        case .away: return .orange
        case .offline: return .gray
        }
    }

    var statusText: String {
        switch member.status {
        case .online: return "Online"
        case .away: return "Away"
        case .offline: return "Offline"
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Avatar with status indicator
                ZStack(alignment: .bottomTrailing) {
                    ZStack {
                        Circle()
                            .fill(theme.accentColor.opacity(0.15))
                            .frame(width: 52, height: 52)

                        Text(member.avatarEmoji)
                            .font(.system(size: 26))
                    }

                    // Status dot
                    Circle()
                        .fill(statusColor)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle()
                                .stroke(theme.cardBackgroundColor, lineWidth: 2)
                        )
                        .offset(x: 2, y: 2)
                }

                // Member info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(member.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(theme.textColor)

                        if member.isElder {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.pink)
                        }
                    }

                    Text(statusText)
                        .font(.system(size: 13))
                        .foregroundColor(statusColor)
                }

                Spacer()

                // Story count
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(member.storyCount)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(theme.accentColor)

                    Text("stories")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(theme.secondaryTextColor)
                        .textCase(.uppercase)
                }

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.secondaryTextColor.opacity(0.5))
            }
            .padding(14)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty Search State

struct EmptySearchState: View {
    let searchText: String
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "person.slash")
                .font(.system(size: 48))
                .foregroundColor(theme.secondaryTextColor.opacity(0.5))

            Text("No members found")
                .font(.headline)
                .foregroundColor(theme.textColor)

            Text("No one matches \"\(searchText)\"")
                .font(.subheadline)
                .foregroundColor(theme.secondaryTextColor)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    ManageMembersModal()
        .themed(DarkTheme())
}
