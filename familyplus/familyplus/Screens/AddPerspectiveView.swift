//
//  AddPerspectiveView.swift
//  StoryRide
//
//  Recording replies to existing story segments (multiplayer perspectives)
//

import SwiftUI

// MARK: - Perspective Composer Mode

enum PerspectiveComposerMode: String, CaseIterable {
    case voice = "Record Voice"
    case text = "Write Text"

    var icon: String {
        switch self {
        case .voice: return "mic.fill"
        case .text: return "text.cursor"
        }
    }
}

// MARK: - Add Perspective View (Enhanced Perspective Composer)

struct AddPerspectiveView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    // Context: What we're replying to
    let story: StoryData
    let replyingTo: StorySegmentData? // nil = replying to story, non-nil = replying to specific response

    // Composer mode
    @State private var composerMode: PerspectiveComposerMode = .voice
    @State private var isPrivate: Bool = false

    // Voice recording state
    @State private var isRecording = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    // Text input state
    @State private var textInput: String = ""

    @StateObject private var audioRecorder = AudioRecorderService()
    @StateObject private var audioMonitor = AudioLevelMonitor()

    // TODO: Get from actual user context
    private let currentUserId = "test-user-id"
    private let currentUserName = "You"
    private let currentUserRole = "parent"

    var contextPrompt: String {
        // "Your version of this memory" framing
        if let replying = replyingTo {
            return "Your response to \(replying.fullName)'s version"
        } else {
            return story.title ?? "Your version of this memory"
        }
    }

    var guidingText: String {
        if replyingTo != nil {
            return "How do you remember this moment differently?"
        } else {
            return "Share your unique perspective on this memory"
        }
    }

    var body: some View {
        ZStack {
            Group {
                switch theme.role {
                case .teen:
                    TeenAddPerspective(
                        contextPrompt: contextPrompt,
                        guidingText: guidingText,
                        replyingToName: replyingTo?.fullName,
                        composerMode: $composerMode,
                        isPrivate: $isPrivate,
                        isRecording: $isRecording,
                        recordingDuration: audioRecorder.recordingDuration,
                        audioLevels: audioMonitor.recentLevels,
                        textInput: $textInput,
                        onStartRecording: startRecording,
                        onStopRecording: stopRecording,
                        onTextSubmit: submitTextPerspective,
                        onCancel: { dismiss() }
                    )
                case .parent:
                    ParentAddPerspective(
                        contextPrompt: contextPrompt,
                        guidingText: guidingText,
                        replyingToName: replyingTo?.fullName,
                        composerMode: $composerMode,
                        isPrivate: $isPrivate,
                        isRecording: $isRecording,
                        recordingDuration: audioRecorder.recordingDuration,
                        audioLevels: audioMonitor.recentLevels,
                        textInput: $textInput,
                        onStartRecording: startRecording,
                        onStopRecording: stopRecording,
                        onTextSubmit: submitTextPerspective,
                        onCancel: { dismiss() }
                    )
                case .child:
                    ChildAddPerspective(
                        contextPrompt: contextPrompt,
                        guidingText: guidingText,
                        replyingToName: replyingTo?.fullName,
                        composerMode: $composerMode,
                        isPrivate: $isPrivate,
                        isRecording: $isRecording,
                        recordingDuration: audioRecorder.recordingDuration,
                        currentAudioLevel: CGFloat(audioMonitor.currentLevel),
                        textInput: $textInput,
                        onStartRecording: startRecording,
                        onStopRecording: stopRecording,
                        onTextSubmit: submitTextPerspective,
                        onCancel: { dismiss() }
                    )
                case .elder:
                    ElderAddPerspective(
                        contextPrompt: contextPrompt,
                        guidingText: guidingText,
                        composerMode: $composerMode,
                        isPrivate: $isPrivate,
                        isRecording: $isRecording,
                        recordingDuration: audioRecorder.recordingDuration,
                        audioLevels: audioMonitor.recentLevels,
                        textInput: $textInput,
                        onStartRecording: startRecording,
                        onStopRecording: stopRecording,
                        onTextSubmit: submitTextPerspective,
                        onCancel: { dismiss() }
                    )
                }
            }
            .animation(theme.animation, value: isRecording)
            .animation(theme.animation, value: composerMode)

            // Saving overlay
            if isSaving {
                SavingOverlay()
            }
        }
        .alert("Recording Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }

    private func startRecording() {
        Task {
            do {
                try await audioRecorder.startRecording()
                audioMonitor.startMonitoring()
                isRecording = true
            } catch {
                errorMessage = "Failed to start recording: \(error.localizedDescription)"
            }
        }
    }

    private func stopRecording() {
        // Stop recording
        guard let recordingURL = audioRecorder.stopRecording() else {
            errorMessage = "No recording to save"
            return
        }

        audioMonitor.stopMonitoring()
        isRecording = false

        // Upload to Supabase
        isSaving = true

        Task {
            do {
                // Upload audio file
                let publicURL = try await SupabaseService.shared.uploadAudio(
                    fileURL: recordingURL,
                    familyId: story.familyId,
                    storyId: story.id
                )

                print("✅ Perspective recorded! Public URL: \(publicURL)")

                // TODO: Send to backend API to create story segment
                // POST /api/stories/{storyId}/responses
                // Body: {
                //   "mediaUrl": publicURL,
                //   "durationSeconds": Int(audioRecorder.recordingDuration),
                //   "replyToResponseId": replyingTo?.id
                // }

                // Clean up local file
                try? FileManager.default.removeItem(at: recordingURL)

                isSaving = false
                dismiss()
            } catch {
                isSaving = false
                errorMessage = "Failed to save perspective: \(error.localizedDescription)"

                // Clean up local file even on error
                try? FileManager.default.removeItem(at: recordingURL)
            }
        }
    }

    private func submitTextPerspective() {
        guard !textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter your perspective"
            return
        }

        isSaving = true

        Task {
            do {
                // TODO: Send to backend API to create text story segment
                // POST /api/stories/{storyId}/responses
                // Body: {
                //   "transcriptionText": textInput,
                //   "mediaUrl": null,
                //   "durationSeconds": 0,
                //   "replyToResponseId": replyingTo?.id,
                //   "isPrivate": isPrivate
                // }

                print("✅ Perspective submitted! Text: \(textInput.prefix(50))...")
                print("🔒 Private: \(isPrivate)")

                isSaving = false
                dismiss()
            } catch {
                isSaving = false
                errorMessage = "Failed to save perspective: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Composer Mode Selector (Shared Component)

struct ComposerModeSelector: View {
    @Environment(\.theme) var theme
    @Binding var selectedMode: PerspectiveComposerMode

    var body: some View {
        HStack(spacing: 0) {
            ForEach(PerspectiveComposerMode.allCases, id: \.self) { mode in
                Button(action: {
                    withAnimation(theme.animation) {
                        selectedMode = mode
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 14, weight: .medium))
                        Text(mode.rawValue)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(selectedMode == mode ? .white : theme.secondaryTextColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        selectedMode == mode ?
                            theme.accentColor :
                            theme.cardBackgroundColor
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.cardBackgroundColor)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
    }
}

// MARK: - Private Toggle (Shared Component)

struct PrivateToggle: View {
    @Environment(\.theme) var theme
    @Binding var isPrivate: Bool

    var body: some View {
        Button(action: {
            withAnimation(theme.animation) {
                isPrivate.toggle()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: isPrivate ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isPrivate ? theme.accentColor : theme.secondaryTextColor)

                Text(isPrivate ? "Private" : "Public")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isPrivate ? theme.accentColor : theme.secondaryTextColor)

                if isPrivate {
                    Text("(only you)")
                        .font(.system(size: 12))
                        .foregroundColor(theme.secondaryTextColor.opacity(0.8))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isPrivate ?
                          theme.accentColor.opacity(0.1) :
                          theme.cardBackgroundColor)
                    .overlay(
                        Capsule()
                            .stroke(isPrivate ? theme.accentColor : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Teen Add Perspective (Enhanced with Composer Mode)

struct TeenAddPerspective: View {
    @Environment(\.theme) var theme

    let contextPrompt: String
    let guidingText: String
    let replyingToName: String?
    @Binding var composerMode: PerspectiveComposerMode
    @Binding var isPrivate: Bool
    @Binding var isRecording: Bool
    let recordingDuration: TimeInterval
    let audioLevels: [CGFloat]
    @Binding var textInput: String
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
    let onTextSubmit: () -> Void
    let onCancel: () -> Void

    @State private var animateWave = false

    var formattedTime: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    theme.backgroundColor,
                    isRecording ? theme.accentColor.opacity(0.05) : theme.backgroundColor
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with Composer Mode Selector
                VStack(spacing: 16) {
                    HStack {
                        Button(action: onCancel) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(theme.textColor.opacity(0.6))
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(theme.cardBackgroundColor)
                                )
                        }
                        Spacer()
                        PrivateToggle(isPrivate: $isPrivate)
                    }

                    // Composer Mode Selector
                    ComposerModeSelector(selectedMode: $composerMode)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()

                // Context Card
                VStack(spacing: 20) {
                    if let replyingToName = replyingToName {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.turn.down.right")
                                .font(.caption)
                            Text("Replying to \(replyingToName)")
                                .font(.caption)
                        }
                        .foregroundColor(theme.accentColor)
                    }

                    Text(contextPrompt)
                        .font(.system(size: 24, weight: .medium, design: .serif))
                        .foregroundColor(theme.textColor)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 40)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(theme.cardBackgroundColor)
                        .shadow(color: .black.opacity(0.08), radius: 20, y: 10)
                )
                .padding(.horizontal, 24)

                Spacer()

                // Mode-specific content
                if composerMode == .voice {
                    // Voice mode
                    if isRecording {
                        TeenWaveformVisualizer(amplitudes: audioLevels, accentColor: theme.accentColor)
                            .frame(height: 80)
                            .padding(.horizontal, 40)
                            .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    }

                    Spacer()

                    // Record Button
                    VStack(spacing: 20) {
                        TeenRecordButton(
                            isRecording: isRecording,
                            accentColor: theme.accentColor,
                            textColor: theme.textColor
                        ) {
                            if isRecording {
                                onStopRecording()
                            } else {
                                onStartRecording()
                            }
                        }

                        Text(isRecording ? "Tap to finish" : "Add your perspective")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.secondaryTextColor)
                    }
                    .padding(.bottom, 60)
                } else {
                    // Text mode
                    Spacer()

                    VStack(spacing: 16) {
                        Text(guidingText)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.secondaryTextColor)
                            .multilineTextAlignment(.center)

                        TextEditor(text: $textInput)
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(theme.textColor)
                            .padding(16)
                            .frame(minHeight: 180)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(theme.cardBackgroundColor)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(textInput.isEmpty ?
                                            theme.secondaryTextColor.opacity(0.2) :
                                            theme.accentColor.opacity(0.5), lineWidth: 1)
                            )

                        Button(action: onTextSubmit) {
                            Text("Share your perspective")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(textInput.isEmpty ?
                                              theme.secondaryTextColor :
                                              theme.accentColor)
                                )
                        }
                        .disabled(textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 60)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.15).repeatForever(autoreverses: true)) {
                animateWave = true
            }
        }
    }
}

// MARK: - Parent Add Perspective (Enhanced with Composer Mode)

struct ParentAddPerspective: View {
    @Environment(\.theme) var theme

    let contextPrompt: String
    let guidingText: String
    let replyingToName: String?
    @Binding var composerMode: PerspectiveComposerMode
    @Binding var isPrivate: Bool
    @Binding var isRecording: Bool
    let recordingDuration: TimeInterval
    let audioLevels: [CGFloat]
    @Binding var textInput: String
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
    let onTextSubmit: () -> Void
    let onCancel: () -> Void

    var formattedTime: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        let tenths = Int((recordingDuration.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%d:%02d.%d", minutes, seconds, tenths)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundColor.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Composer Mode Selector & Private Toggle
                    VStack(spacing: 12) {
                        HStack {
                            ComposerModeSelector(selectedMode: $composerMode)
                            PrivateToggle(isPrivate: $isPrivate)
                        }
                    }
                    .padding(24)
                    .padding(.bottom, 8)

                    Divider()
                        .padding(.horizontal, 24)

                    // Context Section
                    VStack(alignment: .leading, spacing: 16) {
                        if let replyingToName = replyingToName {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.turn.down.right")
                                    .font(.caption)
                                Text("Replying to \(replyingToName)")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(theme.accentColor)
                        }

                        Text(contextPrompt)
                            .font(.system(size: 20, weight: .medium, design: .serif))
                            .foregroundColor(theme.textColor)
                            .lineSpacing(6)
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(theme.cardBackgroundColor)
                            )
                    }
                    .padding(24)

                    Divider()
                        .padding(.horizontal, 24)

                    // Mode-specific content
                    if composerMode == .voice {
                        // Voice Recording Section
                        VStack(spacing: 32) {
                            if isRecording {
                                VStack(spacing: 24) {
                                    ParentWaveformView(levels: audioLevels, accentColor: theme.accentColor)
                                        .frame(height: 100)
                                        .padding(.horizontal, 24)

                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 12, height: 12)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.red.opacity(0.3), lineWidth: 4)
                                                    .scaleEffect(1.5)
                                            )

                                        Text(formattedTime)
                                            .font(.system(size: 48, weight: .light, design: .monospaced))
                                            .foregroundColor(theme.textColor)
                                    }
                                }
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            } else {
                                VStack(spacing: 16) {
                                    Image(systemName: "waveform.circle")
                                        .font(.system(size: 80))
                                        .foregroundColor(theme.secondaryTextColor.opacity(0.3))

                                    Text("Ready to add your perspective")
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundColor(theme.secondaryTextColor)
                                }
                                .frame(height: 160)
                            }
                        }
                        .frame(maxHeight: .infinity)

                        // Voice Controls
                        VStack(spacing: 16) {
                            ParentRecordButton(
                                isRecording: isRecording,
                                accentColor: theme.accentColor
                            ) {
                                if isRecording {
                                    onStopRecording()
                                } else {
                                    onStartRecording()
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    } else {
                        // Text Mode Section
                        VStack(spacing: 20) {
                            Text(guidingText)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(theme.secondaryTextColor)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            TextEditor(text: $textInput)
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(theme.textColor)
                                .padding(16)
                                .frame(minHeight: 200)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(theme.cardBackgroundColor)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(textInput.isEmpty ?
                                                theme.secondaryTextColor.opacity(0.2) :
                                                theme.accentColor.opacity(0.5), lineWidth: 1)
                                )
                                .frame(maxHeight: .infinity)

                            // Text Submit Button
                            Button(action: onTextSubmit) {
                                Text("Share your perspective")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(textInput.isEmpty ?
                                                  theme.secondaryTextColor :
                                                  theme.accentColor)
                                    )
                            }
                            .disabled(textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        .padding(24)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Add Perspective")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                        .foregroundColor(theme.accentColor)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isRecording {
                        Button("Done") {
                            onStopRecording()
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(theme.accentColor)
                    }
                }
            }
        }
    }
}

// MARK: - Child Add Perspective (Enhanced with Composer Mode)

struct ChildAddPerspective: View {
    @Environment(\.theme) var theme

    let contextPrompt: String
    let guidingText: String
    let replyingToName: String?
    @Binding var composerMode: PerspectiveComposerMode
    @Binding var isPrivate: Bool
    @Binding var isRecording: Bool
    let recordingDuration: TimeInterval
    let currentAudioLevel: CGFloat
    @Binding var textInput: String
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
    let onTextSubmit: () -> Void
    let onCancel: () -> Void

    @State private var showCelebration = false

    var audioReactiveScale: CGFloat {
        1.0 + (currentAudioLevel * 0.3)
    }

    var body: some View {
        ZStack {
            ChildStudioBackground(isRecording: isRecording, accentColor: theme.accentColor)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with mode selector and private toggle
                VStack(spacing: 12) {
                    HStack {
                        Button(action: onCancel) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 24, weight: .bold))
                                Text("Back")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(theme.accentColor)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(theme.cardBackgroundColor)
                                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                            )
                        }
                        Spacer()
                        PrivateToggle(isPrivate: $isPrivate)
                    }

                    // Composer Mode Selector (larger for child)
                    ComposerModeSelector(selectedMode: $composerMode)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()

                // Context Card
                VStack(spacing: 16) {
                    if let replyingToName = replyingToName {
                        Text("Reply to \(replyingToName)!")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundColor(theme.accentColor)
                    }

                    Text(contextPrompt)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                // Mode-specific content
                if composerMode == .voice {
                    // Voice mode
                    if isRecording {
                        // Recording visualization
                        ChildRecordingVisualizer(
                            duration: recordingDuration,
                            audioLevel: currentAudioLevel,
                            accentColor: theme.accentColor
                        )
                    }

                    // Magic mic button
                    ChildMagicMicButton(
                        isRecording: isRecording,
                        accentColor: theme.accentColor
                    ) {
                        if isRecording {
                            onStopRecording()
                            showCelebration = true
                        } else {
                            onStartRecording()
                        }
                    }
                    .padding(.bottom, 24)

                    Text(isRecording ? "Tap when you're done!" : "Tap to talk!")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(theme.accentColor)
                        .padding(.bottom, 40)
                } else {
                    // Text mode
                    VStack(spacing: 20) {
                        Text(guidingText)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(theme.accentColor)
                            .multilineTextAlignment(.center)

                        TextEditor(text: $textInput)
                            .font(.system(size: 22, weight: .medium, design: .rounded))
                            .foregroundColor(theme.textColor)
                            .padding(20)
                            .frame(minHeight: 200)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(theme.cardBackgroundColor)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(textInput.isEmpty ?
                                            Color.clear :
                                            theme.accentColor, lineWidth: 3)
                            )

                        Button(action: onTextSubmit) {
                            Text("Share!")
                                .font(.system(size: 24, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 70)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(textInput.isEmpty ?
                                              theme.secondaryTextColor :
                                              theme.accentColor)
                                )
                        }
                        .disabled(textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                }
            }

            // Celebration
            if showCelebration {
                ChildCelebrationView {
                    showCelebration = false
                    onCancel()
                }
                .transition(.opacity)
            }
        }
    }
}

// MARK: - Elder Add Perspective (Enhanced with Composer Mode)

struct ElderAddPerspective: View {
    @Environment(\.theme) var theme

    let contextPrompt: String
    let guidingText: String
    @Binding var composerMode: PerspectiveComposerMode
    @Binding var isPrivate: Bool
    @Binding var isRecording: Bool
    let recordingDuration: TimeInterval
    let audioLevels: [CGFloat]
    @Binding var textInput: String
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
    let onTextSubmit: () -> Void
    let onCancel: () -> Void

    @State private var callScheduled = false

    var formattedTime: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with mode selector and private toggle
                VStack(spacing: 16) {
                    HStack {
                        Button(action: onCancel) {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 28, weight: .bold))
                                Text("Back")
                                    .font(.system(size: 28, weight: .semibold))
                            }
                            .foregroundColor(theme.accentColor)
                        }
                        Spacer()
                        PrivateToggle(isPrivate: $isPrivate)
                    }
                    .padding(.horizontal, 32)

                    // Composer Mode Selector (larger for elder)
                    ComposerModeSelector(selectedMode: $composerMode)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 24)

                Spacer()

                // Context Card
                VStack(spacing: 32) {
                    Text(contextPrompt)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(theme.textColor)
                        .multilineTextAlignment(.center)
                        .lineSpacing(10)
                        .padding(.horizontal, 40)

                    if composerMode == .voice {
                        // Voice mode - Phone call UI
                        if !callScheduled {
                            VStack(spacing: 40) {
                                ZStack {
                                    Circle()
                                        .fill(theme.accentColor.opacity(0.15))
                                        .frame(width: 200, height: 200)

                                    Image(systemName: "phone.fill")
                                        .font(.system(size: 80, weight: .medium))
                                        .foregroundColor(theme.accentColor)
                                }

                                VStack(spacing: 20) {
                                    Text("Add Your Perspective")
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(theme.textColor)

                                    Text("We'll call you to record\nyour response")
                                        .font(.system(size: 26))
                                        .foregroundColor(theme.secondaryTextColor)
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(8)
                                }
                            }

                            Spacer()

                            Button(action: {
                                withAnimation(.spring()) {
                                    callScheduled = true
                                }
                            }) {
                                HStack(spacing: 16) {
                                    Image(systemName: "phone.arrow.down.left")
                                        .font(.system(size: 32, weight: .semibold))
                                    Text("Call Me Now")
                                        .font(.system(size: 32, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 90)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.green)
                                        .shadow(color: Color.green.opacity(0.4), radius: 16, y: 8)
                                )
                            }
                            .padding(.horizontal, 32)
                            .padding(.bottom, 60)
                        } else {
                            // Call scheduled
                            VStack(spacing: 40) {
                                ZStack {
                                    Circle()
                                        .fill(Color.green.opacity(0.15))
                                        .frame(width: 200, height: 200)

                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 100))
                                        .foregroundColor(.green)
                                }

                                VStack(spacing: 20) {
                                    Text("Calling You Now!")
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(theme.textColor)

                                    Text("Please answer when\nyour phone rings")
                                        .font(.system(size: 28))
                                        .foregroundColor(theme.secondaryTextColor)
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(8)
                                }

                                Image(systemName: "phone.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.green)
                                    .symbolEffect(.pulse)
                            }

                            Spacer()

                            Button(action: onCancel) {
                                Text("Done")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 80)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(theme.accentColor)
                                    )
                            }
                            .padding(.horizontal, 32)
                            .padding(.bottom, 60)
                        }
                    } else {
                        // Text mode - Large text input for elders
                        VStack(spacing: 24) {
                            Text(guidingText)
                                .font(.system(size: 30, weight: .semibold))
                                .foregroundColor(theme.secondaryTextColor)
                                .multilineTextAlignment(.center)
                                .lineSpacing(8)

                            TextEditor(text: $textInput)
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(theme.textColor)
                                .padding(24)
                                .frame(minHeight: 300)
                                .background(
                                    RoundedRectangle(cornerRadius: 24)
                                        .fill(theme.cardBackgroundColor)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(textInput.isEmpty ?
                                                theme.secondaryTextColor.opacity(0.2) :
                                                theme.accentColor, lineWidth: 2)
                                )

                            Button(action: onTextSubmit) {
                                Text("Share Your Perspective")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 90)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(textInput.isEmpty ?
                                                  theme.secondaryTextColor :
                                                  theme.accentColor)
                                    )
                            }
                            .disabled(textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 60)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct AddPerspectiveView_Previews: PreviewProvider {
    static var previews: some View {
        AddPerspectiveView(
            story: StoryData(
                id: "story-1",
                promptId: nil,
                familyId: "family-1",
                title: "What was your favorite childhood memory?",
                summaryText: nil,
                coverImageUrl: nil,
                voiceCount: 2,
                isCompleted: false,
                createdAt: ISO8601DateFormatter().string(from: Date()),
                promptText: "What was your favorite childhood memory?",
                promptCategory: "childhood"
            ),
            replyingTo: nil
        )
        .themed(ParentTheme())
    }
}
