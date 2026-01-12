//
//  AddFamilyMemberModal.swift
//  familyplus
//
//  Modal for directly adding family members (organizer only)
//

import SwiftUI

enum FamilyMemberOnboardingStep: Int, CaseIterable {
    case profile = 0
    case confirmation = 1

    var title: String {
        switch self {
        case .profile: return "Add Family Member"
        case .confirmation: return "Confirm"
        }
    }
}

struct FamilyMemberInfo {
    var name: String = ""
    var avatarEmoji: String = "👤"
    var role: String = "member"
}

struct AddFamilyMemberModal: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    @State private var currentStep: FamilyMemberOnboardingStep = .profile
    @State private var memberInfo = FamilyMemberInfo()
    @State private var isLoading = false
    @State private var showSuccess = false

    private let avatarOptions = ["👨", "👩", "🧑", "👦", "👧", "🧓", "👴", "👵", "❤️", "🌟", "📖", "🎭"]
    private let roleOptions = ["member", "child"]

    var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundColor
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress indicator
                    if !showSuccess {
                        AddMemberProgressBar(currentStep: currentStep.rawValue, totalSteps: FamilyMemberOnboardingStep.allCases.count)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                    }

                    // Content
                    ScrollView {
                        VStack(spacing: 24) {
                            if showSuccess {
                                AddMemberSuccessView(memberName: memberInfo.name)
                            } else {
                                switch currentStep {
                                case .profile:
                                    ProfileStepView(
                                        memberInfo: $memberInfo,
                                        avatarOptions: avatarOptions,
                                        roleOptions: roleOptions
                                    )
                                case .confirmation:
                                    AddMemberConfirmationStepView(memberInfo: memberInfo)
                                }
                            }
                        }
                        .padding(20)
                    }

                    // Bottom buttons
                    if !showSuccess {
                        bottomButtons
                            .padding(20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if currentStep == .profile && !showSuccess {
                        Button("Cancel") { dismiss() }
                    } else if !showSuccess && currentStep != .profile {
                        Button(action: goBack) {
                            Image(systemName: "chevron.left")
                                .fontWeight(.semibold)
                        }
                    }
                }

                ToolbarItem(placement: .principal) {
                    if !showSuccess {
                        Text(currentStep.title)
                            .font(.headline)
                    }
                }
            }
        }
    }

    private var bottomButtons: some View {
        Button(action: goNext) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(currentStep == .confirmation ? "Add Member" : "Continue")
                        .font(.headline)
                    if currentStep != .confirmation {
                        Image(systemName: "arrow.right")
                    }
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
        }
        .buttonStyle(.glassProminent)
        .tint(theme.accentColor)
        .disabled(!canProceed || isLoading)
        .opacity(canProceed ? 1.0 : 0.5)
    }

    private var canProceed: Bool {
        switch currentStep {
        case .profile: return !memberInfo.name.isEmpty
        case .confirmation: return true
        }
    }

    private func goNext() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if currentStep == .confirmation {
                addMember()
            } else if let nextStep = FamilyMemberOnboardingStep(rawValue: currentStep.rawValue + 1) {
                currentStep = nextStep
            }
        }
    }

    private func goBack() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if let prevStep = FamilyMemberOnboardingStep(rawValue: currentStep.rawValue - 1) {
                currentStep = prevStep
            }
        }
    }

    private func addMember() {
        isLoading = true
        Task {
            do {
                let _ = try await APIService.shared.addFamilyMember(
                    name: memberInfo.name,
                    avatar: memberInfo.avatarEmoji,
                    role: memberInfo.role
                )

                await MainActor.run {
                    isLoading = false
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        showSuccess = true
                    }

                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        await MainActor.run {
                            dismiss()
                        }
                    }
                }
            } catch {
                print("Error adding family member: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Profile Step

struct ProfileStepView: View {
    @Binding var memberInfo: FamilyMemberInfo
    let avatarOptions: [String]
    let roleOptions: [String]
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 24) {
            // Avatar selection
            VStack(spacing: 12) {
                Text(memberInfo.avatarEmoji)
                    .font(.system(size: 64))
                    .frame(width: 100, height: 100)
                    .background(
                        Circle()
                            .fill(theme.accentColor.opacity(0.2))
                    )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(avatarOptions, id: \.self) { emoji in
                            Button {
                                memberInfo.avatarEmoji = emoji
                            } label: {
                                Text(emoji)
                                    .font(.title)
                                    .padding(8)
                                    .background(
                                        Circle()
                                            .fill(memberInfo.avatarEmoji == emoji ? theme.accentColor.opacity(0.3) : Color.clear)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // Form fields
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(theme.secondaryTextColor)

                    TextField("e.g., Sarah", text: $memberInfo.name)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.name)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Role")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(theme.secondaryTextColor)

                    Picker("Role", selection: $memberInfo.role) {
                        ForEach(roleOptions, id: \.self) { role in
                            Text(role.capitalized).tag(role)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .padding(.top, 24)
    }
}

// MARK: - Confirmation Step

struct AddMemberConfirmationStepView: View {
    let memberInfo: FamilyMemberInfo
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 24) {
            // Summary card
            VStack(spacing: 16) {
                Text(memberInfo.avatarEmoji)
                    .font(.system(size: 64))

                Text(memberInfo.name)
                    .font(.title2.bold())
                    .foregroundColor(theme.textColor)

                Text(memberInfo.role.capitalized)
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryTextColor)
            }
            .padding(.top, 24)

            // What happens next
            VStack(alignment: .leading, spacing: 12) {
                Text("What happens next?")
                    .font(.headline)
                    .foregroundColor(theme.textColor)

                VStack(alignment: .leading, spacing: 8) {
                    AddMemberNextStepRow(number: 1, text: "\(memberInfo.name) will appear in your family")
                    AddMemberNextStepRow(number: 2, text: "They can sign up to set their password")
                    AddMemberNextStepRow(number: 3, text: "They'll see all family stories")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 16)
        }
    }
}

struct AddMemberNextStepRow: View {
    let number: Int
    let text: String
    @Environment(\.theme) var theme

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(theme.accentColor))

            Text(text)
                .font(.subheadline)
                .foregroundColor(theme.secondaryTextColor)
        }
    }
}

// MARK: - Success View

struct AddMemberSuccessView: View {
    let memberName: String
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 140, height: 140)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
            }

            VStack(spacing: 12) {
                Text("Member Added!")
                    .font(.title.bold())
                    .foregroundColor(theme.textColor)

                Text("\(memberName) is now part of your family")
                    .font(.body)
                    .foregroundColor(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Progress Bar (renamed to avoid conflict)

struct AddMemberProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    @Environment(\.theme) var theme

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep ? theme.accentColor : theme.secondaryTextColor.opacity(0.3))
                    .frame(height: 4)
                    .animation(.spring(response: 0.3), value: currentStep)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AddFamilyMemberModal()
        .themed(DarkTheme())
}
