//
//  CaptureMemorySheet.swift
//  StoryRide
//
//  Sheet for capturing new memories with inline recording or typing
//

import SwiftUI

// MARK: - Capture Memory Sheet

struct CaptureMemorySheet: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    var initialPrompt: PromptData? = nil

    @State private var selectedPrompt: PromptData?
    @State private var customPromptText = ""
    @State private var isLoadingPrompts = false

    // Input mode: recording or typing
    @State private var inputMode: InputMode = .recording

    // Recording state
    @State private var isRecording = false
    @State private var recordingDuration: TimeInterval = 0
    @State private var recordingTimer: Timer?

    // Text input state
    @State private var memoryText = ""

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
        VStack(spacing: 0) {
            // Header
            header

            ScrollView {
                VStack(spacing: 24) {
                    // Prompt selection
                    promptSection

                    // Input mode toggle
                    inputModeToggle

                    // Recording or typing section (one at a time)
                    inputSection
                }
                .padding(.horizontal, theme.screenPadding)
                .padding(.bottom, 20)
            }
        }
        .background(theme.backgroundColor)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            if let initialPrompt = initialPrompt {
                selectedPrompt = initialPrompt
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Share a Memory")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(theme.textColor)

            Spacer()

            Button("Cancel") {
                stopRecording()
                dismiss()
            }
            .foregroundColor(theme.accentColor)
            .font(.system(size: 17, weight: .semibold))
        }
        .padding(.horizontal, theme.screenPadding)
        .padding(.vertical, 16)
        .background(theme.backgroundColor)
    }

    // MARK: - Prompt Section

    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Prompt")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(theme.textColor)

            if selectedPrompt == nil {
                // Suggested prompts grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(suggestedPrompts) { prompt in
                        PromptSuggestionCard(
                            prompt: prompt,
                            theme: theme,
                            onTap: {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedPrompt = prompt
                                }
                            }
                        )
                    }
                }
            } else {
                // Selected prompt display
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(selectedPrompt?.text ?? customPromptText)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(theme.textColor)

                        Spacer()

                        Button("Change") {
                            withAnimation(.spring(response: 0.3)) {
                                selectedPrompt = nil
                                customPromptText = ""
                            }
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(theme.accentColor)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.cardBackgroundColor)
                )
            }

            // Custom prompt input
            TextField("Or type your own prompt...", text: $customPromptText)
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
                .onChange(of: customPromptText) { _, _ in
                    selectedPrompt = nil
                }
        }
    }

    // MARK: - Input Mode Toggle

    private var inputModeToggle: some View {
        HStack(spacing: 0) {
            // Record option
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    inputMode = .recording
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 16))
                    Text("Record")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(inputMode == .recording ? .white : theme.accentColor)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(inputMode == .recording ? theme.accentColor : Color.clear)
                )
            }
            .buttonStyle(.plain)

            // Type option
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    inputMode = .typing
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 16))
                    Text("Type")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(inputMode == .typing ? .white : theme.accentColor)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(inputMode == .typing ? theme.accentColor : Color.clear)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(theme.accentColor.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Input Section

    @ViewBuilder
    private var inputSection: some View {
        switch inputMode {
        case .recording:
            recordingSection
        case .typing:
            typingSection
        }
    }

    // MARK: - Recording Section

    private var recordingSection: some View {
        HStack(spacing: 16) {
            // Record button
            Button(action: toggleRecording) {
                ZStack {
                    Circle()
                        .fill(isRecording ? Color.red : theme.accentColor)
                        .frame(width: 60, height: 60)
                        .shadow(color: isRecording ? Color.red.opacity(0.3) : theme.accentColor.opacity(0.25), radius: 12, y: 6)

                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(durationText)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textColor)

                Text(isRecording ? "Recording..." : "Tap to record")
                    .font(.system(size: 13))
                    .foregroundColor(theme.secondaryTextColor)
            }

            Spacer()

            // Save button (only when has recording)
            if !isRecording && recordingDuration > 0 {
                Button(action: saveAndDismiss) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackgroundColor)
        )
    }

    // MARK: - Typing Section

    private var typingSection: some View {
        VStack(spacing: 16) {
            // Text editor
            ZStack(alignment: .topLeading) {
                if memoryText.isEmpty {
                    Text("Write your memory here...")
                        .foregroundColor(theme.secondaryTextColor.opacity(0.5))
                        .font(.system(size: 16))
                        .padding(16)
                }

                TextEditor(text: $memoryText)
                    .font(.system(size: 16))
                    .foregroundColor(theme.textColor)
                    .padding(12)
                    .background(Color.clear)
                    .scrollContentBackground(.hidden)
            }
            .frame(minHeight: 150)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(theme.cardBackgroundColor)
            )

            // Save button (only when has text)
            if !memoryText.isEmpty {
                Button(action: saveAndDismiss) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.green)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Duration Text

    private var durationText: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Actions

    private func toggleRecording() {
        withAnimation {
            isRecording.toggle()

            if isRecording {
                startRecording()
            } else {
                stopRecording()
            }
        }
    }

    private func startRecording() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            recordingDuration += 0.1
        }
        // TODO: Integrate with AudioRecorderService
    }

    private func stopRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        // TODO: Stop AudioRecorderService
    }

    private func saveAndDismiss() {
        // TODO: Save to backend
        dismiss()
    }
}

// MARK: - Input Mode

enum InputMode {
    case recording
    case typing
}

// MARK: - Prompt Suggestion Card

struct PromptSuggestionCard: View {
    let prompt: PromptData
    let theme: PersonaTheme
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Text(prompt.text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.textColor)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(theme.accentColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
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
