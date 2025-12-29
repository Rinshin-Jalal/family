//
//  CaptureMemorySheet.swift
//  StoryRide
//
//  Sheet for capturing new memories with prompt selection
//

import SwiftUI

// MARK: - Capture Memory Sheet

struct CaptureMemorySheet: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    @State private var selectedPrompt: PromptData?
    @State private var customPromptText = ""
    @State private var showRecordView = false
    @State private var showTextView = false
    @State private var isLoadingPrompts = false

    // Sample prompts - in production, fetch from API
    @State private var suggestedPrompts: [PromptData] = [
        PromptData(id: "1", text: "What's your favorite childhood memory?", category: "story", isCustom: false, createdAt: ""),
        PromptData(id: "2", text: "Tell me about a holiday tradition", category: "story", isCustom: false, createdAt: ""),
        PromptData(id: "3", text: "What's something you're grateful for today?", category: "reflection", isCustom: false, createdAt: ""),
        PromptData(id: "4", text: "Describe a moment that changed your life", category: "voiceMemory", isCustom: false, createdAt: ""),
        PromptData(id: "5", text: "What's a lesson you learned the hard way?", category: "reflection", isCustom: false, createdAt: ""),
        PromptData(id: "6", text: "Tell me about your first job", category: "story", isCustom: false, createdAt: "")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header illustration
                    headerSection

                    // Prompt picker or custom
                    if selectedPrompt == nil {
                        promptSuggestionGrid
                    } else {
                        selectedPromptDisplay
                    }

                    // Custom prompt input
                    customPromptSection

                    // Action buttons
                    actionButtons
                }
                .padding(.horizontal, theme.screenPadding)
                .padding(.vertical, 20)
            }
            .background(theme.backgroundColor)
            .navigationTitle("Share a Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(theme.accentColor)
                    .font(.system(size: 17, weight: .semibold))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showRecordView) {
            // TODO: Integrate with recording flow
            RecordingPlaceholderSheet(prompt: selectedPrompt, customText: customPromptText)
        }
        .sheet(isPresented: $showTextView) {
            // TODO: Integrate with text input flow
            TextInputPlaceholderSheet(prompt: selectedPrompt, customText: customPromptText)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(theme.accentColor.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(theme.accentColor)
            }

            VStack(spacing: 8) {
                Text("Share a New Memory")
                    .font(theme.headlineFont)
                    .foregroundColor(theme.textColor)

                Text("Choose a prompt or create your own")
                    .font(.system(size: 15))
                    .foregroundColor(theme.secondaryTextColor)
            }
        }
        .padding(.top, 20)
    }

    // MARK: - Prompt Suggestion Grid

    private var promptSuggestionGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Suggested Prompts")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(theme.textColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            if isLoadingPrompts {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(suggestedPrompts) { prompt in
                        PromptSuggestionCard(
                            prompt: prompt,
                            theme: theme,
                            onTap: {
                                withAnimation {
                                    selectedPrompt = prompt
                                }
                            }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Selected Prompt Display

    private var selectedPromptDisplay: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Selected Prompt")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(theme.secondaryTextColor)

                Spacer()

                Button("Change") {
                    withAnimation {
                        selectedPrompt = nil
                    }
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(theme.accentColor)
            }

            if let prompt = selectedPrompt {
                VStack(alignment: .leading, spacing: 12) {
                    Text(prompt.text)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(theme.textColor)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack {
                        categoryBadge(for: prompt.category ?? "Memory")
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: theme.cardRadius)
                        .fill(theme.cardBackgroundColor)
                )
            }
        }
    }

    // MARK: - Custom Prompt Section

    private var customPromptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Or create your own")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(theme.secondaryTextColor)

            TextField("Type your custom prompt here...", text: $customPromptText, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.cardBackgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(customPromptText.isEmpty ? Color.clear : theme.accentColor, lineWidth: 2)
                )
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 16) {
            // Record button
            Button(action: {
                showRecordView = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "mic.circle.fill")
                        .font(.title2)

                    Text("Record Memory")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(theme.accentColor)
                )
            }
            .buttonStyle(.plain)

            // Text input button
            Button(action: {
                showTextView = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "text.bubble")
                        .font(.title2)

                    Text("Type Memory")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(theme.accentColor)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(theme.accentColor, lineWidth: 2)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 20)
    }

    // MARK: - Helper: Category Badge

    @ViewBuilder
    private func categoryBadge(for category: String) -> some View {
        let (emoji, name): (String, String) = {
            switch category.lowercased() {
            case "voice_memory", "voicememory": return ("🎙️", "Voice Memory")
            case "story": return ("📖", "Story")
            case "reflection": return ("💭", "Reflection")
            default: return ("✨", "Memory")
            }
        }()

        HStack(spacing: 4) {
            Text(emoji)
            Text(name)
        }
        .font(.system(size: 13, weight: .medium))
        .foregroundColor(theme.accentColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(theme.accentColor.opacity(0.12))
        )
    }
}

// MARK: - Prompt Suggestion Card

struct PromptSuggestionCard: View {
    let prompt: PromptData
    let theme: PersonaTheme
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                // Prompt text
                Text(prompt.text)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(theme.textColor)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                // Category badge
                categoryBadge(for: prompt.category ?? "Memory")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: theme.cardRadius)
                    .fill(theme.cardBackgroundColor)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func categoryBadge(for category: String) -> some View {
        let (emoji, name): (String, String) = {
            switch category.lowercased() {
            case "voice_memory", "voicememory": return ("🎙️", "Voice")
            case "story": return ("📖", "Story")
            case "reflection": return ("💭", "Reflection")
            default: return ("✨", "Memory")
            }
        }()

        HStack(spacing: 4) {
            Text(emoji)
            Text(name)
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundColor(theme.secondaryTextColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(theme.secondaryTextColor.opacity(0.1))
        )
    }
}

// MARK: - Placeholder Sheets (TODO: Replace with actual implementations)

struct RecordingPlaceholderSheet: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    let prompt: PromptData?
    let customText: String

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(theme.accentColor)

                Text("Recording Flow")
                    .font(.title2.bold())
                    .foregroundColor(theme.textColor)

                if let prompt = prompt {
                    Text("Prompt: \(prompt.text)")
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                } else if !customText.isEmpty {
                    Text("Prompt: \(customText)")
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                }

                Text("TODO: Integrate with AddPerspectiveView recording flow")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .navigationTitle("Record")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct TextInputPlaceholderSheet: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    let prompt: PromptData?
    let customText: String

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "text.bubble")
                    .font(.system(size: 80))
                    .foregroundColor(theme.accentColor)

                Text("Text Input Flow")
                    .font(.title2.bold())
                    .foregroundColor(theme.textColor)

                if let prompt = prompt {
                    Text("Prompt: \(prompt.text)")
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                } else if !customText.isEmpty {
                    Text("Prompt: \(customText)")
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                }

                Text("TODO: Integrate with AddPerspectiveView text input flow")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .navigationTitle("Type")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Preview

struct CaptureMemorySheet_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CaptureMemorySheet()
                .themed(TeenTheme())
                .previewDisplayName("Teen")

            CaptureMemorySheet()
                .themed(ParentTheme())
                .previewDisplayName("Parent")

            CaptureMemorySheet()
                .themed(ChildTheme())
                .previewDisplayName("Child")

            CaptureMemorySheet()
                .themed(ElderTheme())
                .previewDisplayName("Elder")
        }
    }
}
