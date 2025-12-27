//
//  MyFamilyView.swift
//  StoryRide
//
//  Family members view - Adaptive per persona
//

import SwiftUI

// MARK: - My Family View

struct MyFamilyView: View {
    @Environment(\.theme) var theme
    @State private var loadingState: LoadingState<[FamilyMember]> = .loading
    @State private var selectedMember: FamilyMember?
    @State private var showInviteSheet = false
    @State private var showAddElderSheet = false
    @State private var showGovernance = false
    @State private var showElderPreferences = false
    @State private var selectedElderForPreferences: FamilyMember?

    // TODO: Replace with actual user ownership status from API
    @State private var isOwner: Bool = true

    // TODO: Replace with actual family data from API
    @State private var familyData = FamilyData(
        id: "family-123",
        name: "The Rodriguez Family",
        memberCount: 4,
        storyCount: 42,
        ownerId: "user-1",
        createdAt: Date(),
        hasSensitiveTopics: true,
        allowsConflictingPerspectives: true
    )

    var body: some View {
        Group {
            switch theme.role {
            case .teen:
                TeenMyFamily(
                    loadingState: loadingState,
                    selectedMember: $selectedMember,
                    showInviteSheet: $showInviteSheet,
                    showAddElderSheet: $showAddElderSheet,
                    showGovernance: $showGovernance,
                    isOwner: isOwner,
                    familyData: familyData
                )
            case .parent:
                ParentMyFamily(
                    loadingState: loadingState,
                    selectedMember: $selectedMember,
                    showInviteSheet: $showInviteSheet,
                    showAddElderSheet: $showAddElderSheet,
                    showGovernance: $showGovernance,
                    selectedElderForPreferences: $selectedElderForPreferences,
                    isOwner: isOwner,
                    familyData: familyData
                )
            case .child:
                ChildMyFamily(
                    loadingState: loadingState,
                    selectedMember: $selectedMember
                )
            case .elder:
                ElderMyFamily(
                    loadingState: loadingState,
                    selectedMember: $selectedMember
                )
            }
        }
        .sheet(item: $selectedMember) { member in
            MemberDetailSheet(member: member)
        }
        .sheet(isPresented: $showInviteSheet) {
            InviteFamilySheet()
        }
        .sheet(isPresented: $showAddElderSheet) {
            AddElderSheet()
        }
        .sheet(isPresented: $showGovernance) {
            GovernanceSheet(familyData: familyData)
        }
        .sheet(item: $selectedElderForPreferences) { elder in
            ElderPreferencesView(elderName: elder.name)
        }
        .onAppear {
            loadFamilyMembers()
        }
    }

    private func loadFamilyMembers() {
        loadingState = .loading
        // Simulate network call - replace with real API
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let members = FamilyMember.sampleMembers
            if members.isEmpty {
                loadingState = .empty
            } else {
                loadingState = .loaded(members)
            }
        }
    }
}

// MARK: - Invite Family Sheet

struct InviteFamilySheet: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    @State private var inviteCode = "ROSE2024"
    @State private var copied = false

    var inviteURL: String {
        "storyride.app/join/\(inviteCode.lowercased())"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Header illustration
                ZStack {
                    Circle()
                        .fill(theme.accentColor.opacity(0.1))
                        .frame(width: 140, height: 140)

                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 64))
                        .foregroundColor(theme.accentColor)
                }
                .padding(.top, 40)

                // Instructions
                VStack(spacing: 12) {
                    Text("Invite Family Members")
                        .font(.title2.bold())
                        .foregroundColor(theme.textColor)

                    Text("Share this link with your family members.\nThey can join your StoryRide family instantly.")
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 24)

                // Invite code card
                VStack(spacing: 16) {
                    Text("Family Code")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)

                    Text(inviteCode)
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundColor(theme.accentColor)
                        .tracking(4)

                    // Copy button
                    Button(action: {
                        UIPasteboard.general.string = inviteURL
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            copied = false
                        }
                    }) {
                        HStack {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            Text(copied ? "Copied!" : "Copy Link")
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(copied ? .green : theme.accentColor)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(copied ? Color.green : theme.accentColor, lineWidth: 2)
                        )
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(theme.cardBackgroundColor)
                )
                .padding(.horizontal, 24)

                Spacer()

                // Share button
                ShareLink(item: URL(string: "https://\(inviteURL)")!) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Invite Link")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(theme.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
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

// MARK: - Add Elder Sheet

struct AddElderSheet: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    @State private var elderName = ""
    @State private var phoneNumber = ""
    @State private var relationship = "Grandparent"

    let relationships = ["Grandparent", "Great Grandparent", "Aunt", "Uncle", "Other"]

    var isValid: Bool {
        !elderName.isEmpty && phoneNumber.count >= 10
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.storytellerOrange.opacity(0.15))
                                .frame(width: 100, height: 100)

                            Image(systemName: "phone.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.storytellerOrange)
                        }

                        Text("Add Phone-Only Member")
                            .font(.title2.bold())
                            .foregroundColor(theme.textColor)

                        Text("Elders can participate via phone calls.\nNo app download required for them.")
                            .font(.subheadline)
                            .foregroundColor(theme.secondaryTextColor)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 24)

                    // Form
                    VStack(spacing: 20) {
                        // Name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.subheadline.bold())
                                .foregroundColor(theme.textColor)

                            TextField("e.g., Grandma Rose", text: $elderName)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.secondarySystemBackground))
                                )
                        }

                        // Phone field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phone Number")
                                .font(.subheadline.bold())
                                .foregroundColor(theme.textColor)

                            TextField("+1 (555) 123-4567", text: $phoneNumber)
                                .textFieldStyle(.plain)
                                .keyboardType(.phonePad)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.secondarySystemBackground))
                                )
                        }

                        // Relationship picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Relationship")
                                .font(.subheadline.bold())
                                .foregroundColor(theme.textColor)

                            Picker("Relationship", selection: $relationship) {
                                ForEach(relationships, id: \.self) { rel in
                                    Text(rel).tag(rel)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    .padding(.horizontal, 24)

                    // Info box
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)

                        Text("We'll call them with story prompts and record their responses. All calls are encrypted.")
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )
                    .padding(.horizontal, 24)

                    Spacer()
                }
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        // TODO: Save elder to database
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(!isValid)
                }
            }
        }
    }
}

// MARK: - Member Detail Sheet

struct MemberDetailSheet: View {
    let member: FamilyMember
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    @State private var showRemoveAlert = false
    @State private var showElderPreferences = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Avatar and name
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(member.roleColor.opacity(0.2))
                                .frame(width: 120, height: 120)

                            Text(member.avatarEmoji)
                                .font(.system(size: 64))
                        }

                        VStack(spacing: 4) {
                            Text(member.name)
                                .font(.title.bold())
                                .foregroundColor(theme.textColor)

                            HStack(spacing: 8) {
                                Circle()
                                    .fill(member.statusColor)
                                    .frame(width: 10, height: 10)

                                Text(member.statusText)
                                    .font(.subheadline)
                                    .foregroundColor(theme.secondaryTextColor)
                            }
                        }
                    }
                    .padding(.top, 24)

                    // Stats grid
                    HStack(spacing: 16) {
                        MemberStatBox(
                            icon: "book.fill",
                            value: "\(member.storyCount)",
                            label: "Stories",
                            color: .blue
                        )

                        MemberStatBox(
                            icon: "flame.fill",
                            value: "\(member.weeksStreak)",
                            label: "Week Streak",
                            color: .orange
                        )

                        MemberStatBox(
                            icon: "person.fill",
                            value: member.role.displayName,
                            label: "Role",
                            color: member.roleColor
                        )
                    }
                    .padding(.horizontal, 24)

                    // Actions
                    VStack(spacing: 12) {
                        if member.role == .elder {
                            // Elder-specific actions
                            Button(action: { showElderPreferences = true }) {
                                Label("Preferences & Schedule", systemImage: "gearshape.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                                    .background(theme.accentColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }

                            Button(action: {}) {
                                Label("Call Now", systemImage: "phone.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                                    .background(Color.green)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }

                            Button(action: {}) {
                                Label("Schedule Call", systemImage: "calendar")
                                    .font(.headline)
                                    .foregroundColor(theme.accentColor)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .strokeBorder(theme.accentColor, lineWidth: 2)
                                    )
                            }
                        } else {
                            Button(action: {}) {
                                Label("Send Story Prompt", systemImage: "bubble.left.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                                    .background(theme.accentColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }

                            Button(action: {}) {
                                Label("View Stories", systemImage: "book.fill")
                                    .font(.headline)
                                    .foregroundColor(theme.accentColor)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .strokeBorder(theme.accentColor, lineWidth: 2)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 40)

                    // Remove member (danger zone)
                    Button(action: { showRemoveAlert = true }) {
                        Text("Remove from Family")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                    .padding(.bottom, 32)
                }
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Remove Member?", isPresented: $showRemoveAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Remove", role: .destructive) {
                    // TODO: Remove member
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to remove \(member.name) from your family? Their stories will remain in the archive.")
            }
            .sheet(isPresented: $showElderPreferences) {
                ElderPreferencesView(elderName: member.name)
            }
        }
    }
}

struct MemberStatBox: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.headline)
                .foregroundColor(.primary)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Family Member Skeleton

struct FamilyMemberCardSkeleton: View {
    @Environment(\.theme) var theme

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 60, height: 60)
                .shimmer()

            VStack(alignment: .leading, spacing: 8) {
                SkeletonShape(width: 120, height: 18, cornerRadius: 4)
                SkeletonShape(width: 80, height: 14, cornerRadius: 4)
                SkeletonShape(width: 60, height: 12, cornerRadius: 4)
            }

            Spacer()

            VStack(spacing: 6) {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 12, height: 12)
                    .shimmer()

                SkeletonShape(width: 40, height: 10, cornerRadius: 3)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackgroundColor)
        )
    }
}

// MARK: - Family Empty State

struct FamilyEmptyState: View {
    @Environment(\.theme) var theme
    let onInvite: () -> Void
    let onAddElder: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Illustration
            ZStack {
                Circle()
                    .stroke(theme.accentColor.opacity(0.2), lineWidth: 2)
                    .frame(width: 160, height: 160)

                Image(systemName: "person.3.fill")
                    .font(.system(size: 56))
                    .foregroundColor(theme.accentColor)
            }

            VStack(spacing: 12) {
                Text("No Family Members Yet")
                    .font(.title2.bold())
                    .foregroundColor(theme.textColor)

                Text("Invite your family to start sharing\nstories across generations.")
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }

            // Action buttons
            VStack(spacing: 12) {
                Button(action: onInvite) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Invite Family")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(theme.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button(action: onAddElder) {
                    HStack {
                        Image(systemName: "phone.fill")
                        Text("Add Phone-Only Elder")
                    }
                    .font(.headline)
                    .foregroundColor(theme.accentColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(theme.accentColor, lineWidth: 2)
                    )
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .background(theme.backgroundColor)
    }
}

// MARK: - Teen Family View (Minimalist Cards)

struct TeenMyFamily: View {
    let loadingState: LoadingState<[FamilyMember]>
    @Binding var selectedMember: FamilyMember?
    @Binding var showInviteSheet: Bool
    @Binding var showAddElderSheet: Bool
    @Binding var showGovernance: Bool
    let isOwner: Bool // Can add members if owner
    let familyData: FamilyData
    @Environment(\.theme) var theme

    var body: some View {
        NavigationStack {
            Group {
                switch loadingState {
                case .loading:
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(0..<4, id: \.self) { _ in
                                FamilyMemberCardSkeleton()
                            }
                        }
                        .padding(.horizontal, theme.screenPadding)
                        .padding(.vertical, 12)
                    }

                case .empty:
                    if isOwner {
                        FamilyEmptyState(
                            onInvite: { showInviteSheet = true },
                            onAddElder: { showAddElderSheet = true }
                        )
                    } else {
                        TeenNonOwnerEmptyState()
                    }

                case .loaded(let members):
                    ScrollView {
                        VStack(spacing: 16) {
                            // Family Header Card
                            FamilyHeaderCard(family: familyData)

                            // Governance quick access (owner only)
                            if isOwner {
                                Button(action: { showGovernance = true }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "shield.checkered")
                                            .font(.title3)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Family Governance")
                                                .font(.headline)

                                            Text("Permissions & safety")
                                                .font(.caption)
                                                .foregroundColor(theme.secondaryTextColor)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(theme.secondaryTextColor)
                                    }
                                    .foregroundColor(theme.accentColor)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(theme.accentColor.opacity(0.1))
                                    )
                                }
                            }

                            // Member cards
                            ForEach(members) { member in
                                TeenFamilyMemberCard(member: member)
                                    .onTapGesture { selectedMember = member }
                            }

                            // Add member option for owners
                            if isOwner {
                                TeenAddMemberCard(
                                    onInvite: { showInviteSheet = true },
                                    onAddElder: { showAddElderSheet = true }
                                )
                            }
                        }
                        .padding(.horizontal, theme.screenPadding)
                        .padding(.vertical, 12)
                    }

                case .error(let message):
                    ErrorStateView(message: message, onRetry: {})
                }
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationTitle(familyData.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if isOwner {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(action: { showInviteSheet = true }) {
                                Label("Invite Member", systemImage: "person.badge.plus")
                            }
                            Button(action: { showAddElderSheet = true }) {
                                Label("Add Elder (Phone)", systemImage: "phone.fill")
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(theme.accentColor)
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Teen Add Member Card

struct TeenAddMemberCard: View {
    @Environment(\.theme) var theme
    let onInvite: () -> Void
    let onAddElder: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .strokeBorder(theme.accentColor.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .frame(width: 48, height: 48)

                Image(systemName: "plus")
                    .font(.title3)
                    .foregroundColor(theme.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Add Family Member")
                    .font(.headline)
                    .foregroundColor(theme.accentColor)

                Text("Invite or add phone-only elder")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(theme.secondaryTextColor)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: theme.cardRadius)
                .strokeBorder(theme.accentColor.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [6]))
        )
        .contentShape(Rectangle())
        .onTapGesture { onInvite() }
    }
}

// MARK: - Teen Non-Owner Empty State

struct TeenNonOwnerEmptyState: View {
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.3.fill")
                .font(.system(size: 56))
                .foregroundColor(theme.accentColor.opacity(0.6))

            VStack(spacing: 8) {
                Text("No Family Members Yet")
                    .font(.title3.bold())
                    .foregroundColor(theme.textColor)

                Text("Ask your parent to invite\nfamily members")
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
    }
}

struct TeenFamilyMemberCard: View {
    let member: FamilyMember
    @Environment(\.theme) var theme

    var body: some View {
        HStack(spacing: 16) {
            Text(member.avatarEmoji)
                .font(.system(size: 48))

            VStack(alignment: .leading, spacing: 4) {
                Text(member.name)
                    .font(.headline)
                    .foregroundColor(theme.textColor)

                Text(member.role.displayName)
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)

                HStack(spacing: 8) {
                    Image(systemName: "mic.fill")
                        .font(.caption2)
                    Text("\(member.storyCount) stories")
                        .font(.caption2)
                }
                .foregroundColor(theme.secondaryTextColor.opacity(0.7))
            }

            Spacer()

            VStack(spacing: 4) {
                Circle()
                    .fill(member.statusColor)
                    .frame(width: 12, height: 12)

                Text(member.statusText)
                    .font(.caption2)
                    .foregroundColor(theme.secondaryTextColor)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: theme.cardRadius)
                .fill(theme.cardBackgroundColor)
        )
    }
}

// MARK: - Parent Family View (Detailed Grid)

struct ParentMyFamily: View {
    let loadingState: LoadingState<[FamilyMember]>
    @Binding var selectedMember: FamilyMember?
    @Binding var showInviteSheet: Bool
    @Binding var showAddElderSheet: Bool
    @Binding var showGovernance: Bool
    @Binding var selectedElderForPreferences: FamilyMember?
    let isOwner: Bool // Can add members if owner
    let familyData: FamilyData
    @Environment(\.theme) var theme

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            Group {
                switch loadingState {
                case .loading:
                    ScrollView {
                        VStack(spacing: 24) {
                            // Stats skeleton
                            HStack(spacing: 20) {
                                SkeletonShape(height: 120, cornerRadius: 16)
                                SkeletonShape(height: 120, cornerRadius: 16)
                            }
                            .padding(.horizontal, theme.screenPadding)

                            // Grid skeleton
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(0..<4, id: \.self) { _ in
                                    ParentFamilyMemberCardSkeleton()
                                }
                            }
                            .padding(.horizontal, theme.screenPadding)
                        }
                        .padding(.vertical, theme.screenPadding)
                    }

                case .empty:
                    if isOwner {
                        FamilyEmptyState(
                            onInvite: { showInviteSheet = true },
                            onAddElder: { showAddElderSheet = true }
                        )
                    } else {
                        ParentNonOwnerEmptyState()
                    }

                case .loaded(let members):
                    ScrollView {
                        VStack(spacing: 24) {
                            // Family Header Card
                            FamilyHeaderCard(family: familyData)

                            // Governance quick access (owner only)
                            if isOwner {
                                Button(action: { showGovernance = true }) {
                                    HStack {
                                        Image(systemName: "shield.checkered")
                                            .font(.title3)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Family Governance")
                                                .font(.headline)

                                            Text("Permissions, privacy & safety settings")
                                                .font(.caption)
                                                .foregroundColor(theme.secondaryTextColor)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(theme.secondaryTextColor)
                                    }
                                    .foregroundColor(theme.accentColor)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(theme.accentColor.opacity(0.1))
                                    )
                                }
                            }

                            // Members grid
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(members) { member in
                                    ParentGridMemberCard(member: member)
                                        .onTapGesture { selectedMember = member }
                                }

                                // Add member card (only for owners)
                                if isOwner {
                                    AddMemberCard(
                                        onInvite: { showInviteSheet = true },
                                        onAddElder: { showAddElderSheet = true }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, theme.screenPadding)
                        .padding(.vertical, theme.screenPadding)
                    }

                case .error(let message):
                    ErrorStateView(message: message, onRetry: {})
                }
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationTitle(familyData.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if isOwner {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(action: { showInviteSheet = true }) {
                                Label("Invite Member", systemImage: "person.badge.plus")
                            }
                            Button(action: { showAddElderSheet = true }) {
                                Label("Add Elder (Phone)", systemImage: "phone.fill")
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(theme.accentColor)
                        }
                    }
                }
            }
            .tint(theme.accentColor)
        }
    }
}

// MARK: - Parent Non-Owner Empty State

struct ParentNonOwnerEmptyState: View {
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(theme.accentColor.opacity(0.1))
                    .frame(width: 140, height: 140)

                Image(systemName: "person.3.fill")
                    .font(.system(size: 56))
                    .foregroundColor(theme.accentColor)
            }

            VStack(spacing: 12) {
                Text("No Family Members Yet")
                    .font(.title2.bold())
                    .foregroundColor(theme.textColor)

                Text("The family owner will invite\nmembers to join.")
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
    }
}

// MARK: - Add Member Card

struct AddMemberCard: View {
    @Environment(\.theme) var theme
    let onInvite: () -> Void
    let onAddElder: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .strokeBorder(theme.accentColor.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [6]))
                    .frame(width: 60, height: 60)

                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(theme.accentColor)
            }

            Text("Add Member")
                .font(.subheadline.bold())
                .foregroundColor(theme.accentColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(theme.accentColor.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onInvite()
        }
    }
}

// MARK: - Parent Grid Member Card (for 2-column grid)

struct ParentGridMemberCard: View {
    let member: FamilyMember
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(member.roleColor.opacity(0.2))
                    .frame(width: 80, height: 80)

                Text(member.avatarEmoji)
                    .font(.system(size: 48))
            }

            // Name
            Text(member.name)
                .font(.headline)
                .foregroundColor(theme.textColor)
                .lineLimit(1)

            // Role badge
            Text(member.role.displayName)
                .font(.caption)
                .foregroundColor(member.roleColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(member.roleColor.opacity(0.15))
                )

            // Stats
            HStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text("\(member.storyCount)")
                        .font(.subheadline.bold())
                        .foregroundColor(theme.textColor)

                    Text("Stories")
                        .font(.caption2)
                        .foregroundColor(theme.secondaryTextColor)
                }

                VStack(spacing: 2) {
                    Text("\(member.weeksStreak)")
                        .font(.subheadline.bold())
                        .foregroundColor(.orange)

                    Text("Weeks")
                        .font(.caption2)
                        .foregroundColor(theme.secondaryTextColor)
                }
            }

            // Status
            HStack(spacing: 4) {
                Circle()
                    .fill(member.statusColor)
                    .frame(width: 6, height: 6)

                Text(member.statusText)
                    .font(.caption2)
                    .foregroundColor(theme.secondaryTextColor)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackgroundColor)
        )
    }
}

// MARK: - Parent Family Member Card Skeleton

struct ParentFamilyMemberCardSkeleton: View {
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(Color.gray.opacity(0.15))
                .frame(width: 80, height: 80)
                .shimmer()

            VStack(spacing: 8) {
                SkeletonShape(width: 80, height: 16, cornerRadius: 4)
                SkeletonShape(width: 60, height: 14, cornerRadius: 4)
            }

            HStack(spacing: 16) {
                SkeletonShape(width: 30, height: 12, cornerRadius: 3)
                SkeletonShape(width: 30, height: 12, cornerRadius: 3)
            }

            SkeletonShape(width: 50, height: 10, cornerRadius: 3)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackgroundColor)
        )
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Child Family View (Big Friendly Cards)

struct ChildMyFamily: View {
    let loadingState: LoadingState<[FamilyMember]>
    @Binding var selectedMember: FamilyMember?
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 32) {
            Text("My Family")
                .font(theme.headlineFont)
                .foregroundColor(theme.textColor)
                .padding(.top, theme.screenPadding)

            Group {
                switch loadingState {
                case .loading:
                    VStack(spacing: 24) {
                        ForEach(0..<3, id: \.self) { _ in
                            ChildFamilyMemberCardSkeleton()
                        }
                    }
                    .padding(theme.screenPadding)

                case .empty:
                    ChildFamilyEmptyState()

                case .loaded(let members):
                    ScrollView {
                        VStack(spacing: 24) {
                            ForEach(members) { member in
                                ChildFamilyMemberCard(member: member)
                                    .onTapGesture { selectedMember = member }
                            }
                        }
                        .padding(theme.screenPadding)
                    }

                case .error(let message):
                    ChildErrorState(message: message)
                }
            }
        }
        .background(theme.backgroundColor.ignoresSafeArea())
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Child Family Skeleton

struct ChildFamilyMemberCardSkeleton: View {
    @Environment(\.theme) var theme

    var body: some View {
        HStack(spacing: 24) {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 100, height: 100)
                .shimmer()

            VStack(alignment: .leading, spacing: 12) {
                SkeletonShape(width: 140, height: 28, cornerRadius: 6)
                SkeletonShape(width: 100, height: 20, cornerRadius: 4)
                SkeletonShape(width: 80, height: 18, cornerRadius: 4)
            }

            Spacer()
        }
        .padding(theme.screenPadding)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: theme.cardRadius)
                .fill(theme.cardBackgroundColor)
        )
    }
}

// MARK: - Child Family Empty State

struct ChildFamilyEmptyState: View {
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Fun illustration
            ZStack {
                Circle()
                    .fill(Color.storytellerPurple.opacity(0.2))
                    .frame(width: 180, height: 180)

                Text("👨‍👩‍👧‍👦")
                    .font(.system(size: 80))
            }

            VStack(spacing: 16) {
                Text("Your Family is Coming!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textColor)

                Text("Ask a grown-up to invite\nyour family members")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
    }
}

// MARK: - Child Error State

struct ChildErrorState: View {
    let message: String
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("😢")
                .font(.system(size: 80))

            Text("Oops! Something went wrong")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(theme.textColor)

            Text("Let's try again later!")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(theme.secondaryTextColor)

            Spacer()
        }
    }
}

struct ChildFamilyMemberCard: View {
    let member: FamilyMember
    @Environment(\.theme) var theme

    var body: some View {
        HStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(member.roleColor.opacity(0.3))
                    .frame(width: 100, height: 100)

                Text(member.avatarEmoji)
                    .font(.system(size: 56))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(member.name)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textColor)

                Text(member.role.displayName)
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundColor(theme.secondaryTextColor)

                HStack(spacing: 12) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.playfulOrange)
                    Text("\(member.storyCount) stories!")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundColor(theme.secondaryTextColor)
                }
            }

            Spacer()
        }
        .padding(theme.screenPadding)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: theme.cardRadius)
                .fill(theme.cardBackgroundColor)
        )
        .shadow(color: member.roleColor.opacity(0.3), radius: 8)
    }
}

// MARK: - Elder Family View (Large, Simple List)

struct ElderMyFamily: View {
    let loadingState: LoadingState<[FamilyMember]>
    @Binding var selectedMember: FamilyMember?
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 32) {
            Text("My Family")
                .font(theme.headlineFont)
                .foregroundColor(theme.textColor)
                .padding(.top, theme.screenPadding)

            Group {
                switch loadingState {
                case .loading:
                    VStack(spacing: 24) {
                        ForEach(0..<3, id: \.self) { _ in
                            ElderFamilyMemberRowSkeleton()
                        }
                    }
                    .padding(.horizontal, theme.screenPadding)

                case .empty:
                    ElderFamilyEmptyState()

                case .loaded(let members):
                    ScrollView {
                        VStack(spacing: 24) {
                            ForEach(members) { member in
                                ElderFamilyMemberRow(member: member)
                                    .onTapGesture { selectedMember = member }
                            }
                        }
                        .padding(.horizontal, theme.screenPadding)
                    }

                case .error(let message):
                    ElderErrorState(message: message)
                }
            }
        }
        .background(theme.backgroundColor.ignoresSafeArea())
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Elder Family Skeleton

struct ElderFamilyMemberRowSkeleton: View {
    @Environment(\.theme) var theme

    var body: some View {
        HStack(spacing: 24) {
            Circle()
                .fill(Color.gray.opacity(0.15))
                .frame(width: 80, height: 80)
                .shimmer()

            VStack(alignment: .leading, spacing: 12) {
                SkeletonShape(width: 150, height: 28, cornerRadius: 6)
                SkeletonShape(width: 180, height: 22, cornerRadius: 5)
            }

            Spacer()
        }
        .padding(theme.screenPadding)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: theme.cardRadius)
                .fill(theme.cardBackgroundColor)
        )
    }
}

// MARK: - Elder Family Empty State

struct ElderFamilyEmptyState: View {
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Simple, clear illustration
            ZStack {
                Circle()
                    .fill(Color.storytellerOrange.opacity(0.15))
                    .frame(width: 200, height: 200)

                Image(systemName: "person.3.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.storytellerOrange)
            }

            VStack(spacing: 20) {
                Text("No Family Yet")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(theme.textColor)

                Text("Your family members will\nappear here once they join")
                    .font(.system(size: 24))
                    .foregroundColor(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }

            Spacer()
        }
        .padding(theme.screenPadding)
    }
}

// MARK: - Elder Error State

struct ElderErrorState: View {
    let message: String
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 80))
                .foregroundColor(.orange)

            VStack(spacing: 16) {
                Text("Something Went Wrong")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(theme.textColor)

                Text("Please try again in a moment")
                    .font(.system(size: 24))
                    .foregroundColor(theme.secondaryTextColor)
            }

            Spacer()
        }
    }
}

struct ElderFamilyMemberRow: View {
    let member: FamilyMember
    @Environment(\.theme) var theme

    var body: some View {
        HStack(spacing: 24) {
            Text(member.avatarEmoji)
                .font(.system(size: 64))

            VStack(alignment: .leading, spacing: 8) {
                Text(member.name)
                    .font(theme.headlineFont)
                    .foregroundColor(theme.textColor)

                Text("Has shared \(member.storyCount) stories")
                    .font(theme.bodyFont)
                    .foregroundColor(theme.secondaryTextColor)
            }

            Spacer()
        }
        .padding(theme.screenPadding)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: theme.cardRadius)
                .fill(theme.cardBackgroundColor)
        )
    }
}

// MARK: - Family Member Model

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

// MARK: - Preview

struct MyFamilyView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MyFamilyView()
                .themed(TeenTheme())
                .previewDisplayName("Teen Family")

            MyFamilyView()
                .themed(ParentTheme())
                .previewDisplayName("Parent Family")

            MyFamilyView()
                .themed(ChildTheme())
                .previewDisplayName("Child Family")

            MyFamilyView()
                .themed(ElderTheme())
                .previewDisplayName("Elder Family")
        }
    }
}
