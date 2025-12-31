//
//  AddElderModal.swift
//  familyplus
//
//  Multi-step modal for adding and onboarding elder family members
//

import SwiftUI

// MARK: - Elder Onboarding Step

enum ElderOnboardingStep: Int, CaseIterable {
    case intro = 0
    case contact = 1
    case preferences = 2
    case confirmation = 3

    var title: String {
        switch self {
        case .intro: return "Add an Elder"
        case .contact: return "Contact Details"
        case .preferences: return "Their Preferences"
        case .confirmation: return "All Set!"
        }
    }
}

// MARK: - Elder Contact Info

struct ElderContactInfo {
    var name: String = ""
    var phoneNumber: String = ""
    var relationship: String = ""
    var avatarEmoji: String = "👴"
}

// MARK: - Add Elder Modal

struct AddElderModal: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    @State private var currentStep: ElderOnboardingStep = .intro
    @State private var elderInfo = ElderContactInfo()
    @State private var callFrequency: ElderPreferences.CallFrequency = .weekly
    @State private var preferredTopics: Set<String> = []
    @State private var isLoading = false
    @State private var showSuccess = false

    private let availableTopics = ["Childhood", "Career", "Travel", "Family traditions", "Hobbies", "Life lessons", "Recipes", "Music", "Sports", "History"]
    private let relationships = ["Grandmother", "Grandfather", "Great-Aunt", "Great-Uncle", "Elder Relative", "Family Friend"]
    private let emojiOptions = ["👴", "👵", "🧓", "❤️", "🌟", "📖", "🎭", "🌺"]

    var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundColor
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress indicator
                    if !showSuccess {
                        ProgressBar(currentStep: currentStep.rawValue, totalSteps: ElderOnboardingStep.allCases.count)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                    }

                    // Content
                    ScrollView {
                        VStack(spacing: 24) {
                            if showSuccess {
                                SuccessView(elderName: elderInfo.name)
                            } else {
                                switch currentStep {
                                case .intro:
                                    IntroStepView()
                                case .contact:
                                    ContactStepView(
                                        elderInfo: $elderInfo,
                                        relationships: relationships,
                                        emojiOptions: emojiOptions
                                    )
                                case .preferences:
                                    PreferencesStepView(
                                        callFrequency: $callFrequency,
                                        preferredTopics: $preferredTopics,
                                        availableTopics: availableTopics
                                    )
                                case .confirmation:
                                    ConfirmationStepView(elderInfo: elderInfo, callFrequency: callFrequency)
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
                    if currentStep == .intro && !showSuccess {
                        Button("Cancel") { dismiss() }
                    } else if !showSuccess && currentStep != .intro {
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

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        Button(action: goNext) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(currentStep == .confirmation ? "Send Invite" : "Continue")
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

    // MARK: - Navigation Logic

    private var canProceed: Bool {
        switch currentStep {
        case .intro: return true
        case .contact: return !elderInfo.name.isEmpty && !elderInfo.phoneNumber.isEmpty && !elderInfo.relationship.isEmpty
        case .preferences: return true
        case .confirmation: return true
        }
    }

    private func goNext() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if currentStep == .confirmation {
                sendInvite()
            } else if let nextStep = ElderOnboardingStep(rawValue: currentStep.rawValue + 1) {
                currentStep = nextStep
            }
        }
    }

    private func goBack() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if let prevStep = ElderOnboardingStep(rawValue: currentStep.rawValue - 1) {
                currentStep = prevStep
            }
        }
    }

    private func sendInvite() {
        isLoading = true
        // TODO: Replace with actual API call
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                isLoading = false
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showSuccess = true
                }

                // Auto-dismiss after success
                Task {
                    try? await Task.sleep(nanoseconds: 2_500_000_000)
                    await MainActor.run {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Progress Bar

struct ProgressBar: View {
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

// MARK: - Intro Step

struct IntroStepView: View {
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 32) {
            // Hero illustration
            ZStack {
                Circle()
                    .fill(theme.accentColor.opacity(0.15))
                    .frame(width: 160, height: 160)

                Circle()
                    .fill(theme.accentColor.opacity(0.1))
                    .frame(width: 120, height: 120)

                Text("👴❤️")
                    .font(.system(size: 56))
            }
            .padding(.top, 40)

            VStack(spacing: 16) {
                Text("Add an Elder to Your Family")
                    .font(.title2.bold())
                    .foregroundColor(theme.textColor)
                    .multilineTextAlignment(.center)

                Text("Elders are the heart of family stories. We'll help you set up comfortable ways for them to share their memories.")
                    .font(.body)
                    .foregroundColor(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }

            // Features list
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "phone.fill", title: "Phone-first experience", subtitle: "No app needed - we call them")
                FeatureRow(icon: "clock.fill", title: "Flexible scheduling", subtitle: "Set times that work for them")
                FeatureRow(icon: "heart.fill", title: "Comfort-focused", subtitle: "Topics they enjoy talking about")
            }
            .padding(.top, 16)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Environment(\.theme) var theme

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(theme.accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(theme.textColor)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Contact Step

struct ContactStepView: View {
    @Binding var elderInfo: ElderContactInfo
    let relationships: [String]
    let emojiOptions: [String]
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 24) {
            // Avatar selection
            VStack(spacing: 12) {
                Text(elderInfo.avatarEmoji)
                    .font(.system(size: 64))
                    .frame(width: 100, height: 100)
                    .background(
                        Circle()
                            .fill(theme.accentColor.opacity(0.2))
                    )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(emojiOptions, id: \.self) { emoji in
                            Button {
                                elderInfo.avatarEmoji = emoji
                            } label: {
                                Text(emoji)
                                    .font(.title)
                                    .padding(8)
                                    .background(
                                        Circle()
                                            .fill(elderInfo.avatarEmoji == emoji ? theme.accentColor.opacity(0.3) : Color.clear)
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

                    TextField("e.g., Grandma Rose", text: $elderInfo.name)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.name)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Phone Number")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(theme.secondaryTextColor)

                    TextField("(555) 123-4567", text: $elderInfo.phoneNumber)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Relationship")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(theme.secondaryTextColor)

                    Picker("Relationship", selection: $elderInfo.relationship) {
                        Text("Select...").tag("")
                        ForEach(relationships, id: \.self) { relationship in
                            Text(relationship).tag(relationship)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                }
            }
        }
        .padding(.top, 24)
    }
}

// MARK: - Preferences Step

struct PreferencesStepView: View {
    @Binding var callFrequency: ElderPreferences.CallFrequency
    @Binding var preferredTopics: Set<String>
    let availableTopics: [String]
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 24) {
            // Call frequency
            VStack(alignment: .leading, spacing: 12) {
                Text("How often should we call?")
                    .font(.headline)
                    .foregroundColor(theme.textColor)

                ForEach(ElderPreferences.CallFrequency.allCases, id: \.self) { frequency in
                    Button {
                        callFrequency = frequency
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: frequency.icon)
                                .font(.title3)
                                .foregroundColor(callFrequency == frequency ? theme.accentColor : theme.secondaryTextColor)
                                .frame(width: 28)

                            Text(frequency.rawValue)
                                .font(.body)
                                .foregroundColor(theme.textColor)

                            Spacer()

                            if callFrequency == frequency {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(theme.accentColor)
                            }
                        }
                        .padding()
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()

            // Topic preferences
            VStack(alignment: .leading, spacing: 12) {
                Text("Topics they enjoy (optional)")
                    .font(.headline)
                    .foregroundColor(theme.textColor)

                Text("Select topics they'd love to talk about")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)

                FlowLayout(spacing: 8) {
                    ForEach(availableTopics, id: \.self) { topic in
                        TopicChip(
                            topic: topic,
                            isSelected: preferredTopics.contains(topic)
                        ) {
                            if preferredTopics.contains(topic) {
                                preferredTopics.remove(topic)
                            } else {
                                preferredTopics.insert(topic)
                            }
                        }
                    }
                }
            }
        }
        .padding(.top, 16)
    }
}

struct TopicChip: View {
    let topic: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.theme) var theme

    var body: some View {
        Button(action: action) {
            Text(topic)
                .font(.subheadline)
                .foregroundColor(isSelected ? .white : theme.textColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? theme.accentColor : theme.cardBackgroundColor)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Confirmation Step

struct ConfirmationStepView: View {
    let elderInfo: ElderContactInfo
    let callFrequency: ElderPreferences.CallFrequency
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 24) {
            // Summary card
            VStack(spacing: 16) {
                Text(elderInfo.avatarEmoji)
                    .font(.system(size: 64))

                Text(elderInfo.name)
                    .font(.title2.bold())
                    .foregroundColor(theme.textColor)

                Text(elderInfo.relationship)
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryTextColor)
            }
            .padding(.top, 24)

            // Details
            VStack(spacing: 12) {
                SummaryRow(icon: "phone.fill", label: "Phone", value: elderInfo.phoneNumber)
                SummaryRow(icon: "calendar", label: "Call frequency", value: callFrequency.rawValue)
            }
            .padding()
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))

            // What happens next
            VStack(alignment: .leading, spacing: 12) {
                Text("What happens next?")
                    .font(.headline)
                    .foregroundColor(theme.textColor)

                VStack(alignment: .leading, spacing: 8) {
                    NextStepRow(number: 1, text: "We'll send \(elderInfo.name) a welcome call")
                    NextStepRow(number: 2, text: "They can opt-in to story calls")
                    NextStepRow(number: 3, text: "Stories will appear in your family feed")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 16)
        }
    }
}

struct SummaryRow: View {
    let icon: String
    let label: String
    let value: String
    @Environment(\.theme) var theme

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(theme.accentColor)
                .frame(width: 24)

            Text(label)
                .font(.subheadline)
                .foregroundColor(theme.secondaryTextColor)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundColor(theme.textColor)
        }
    }
}

struct NextStepRow: View {
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

struct SuccessView: View {
    let elderName: String
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
                Text("Invite Sent!")
                    .font(.title.bold())
                    .foregroundColor(theme.textColor)

                Text("\(elderName) will receive a welcome call soon")
                    .font(.body)
                    .foregroundColor(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    AddElderModal()
        .themed(DarkTheme())
}
