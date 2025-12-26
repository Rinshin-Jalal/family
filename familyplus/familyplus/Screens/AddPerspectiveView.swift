//
//  AddPerspectiveView.swift
//  StoryRide
//
//  Recording replies to existing story segments (multiplayer perspectives)
//

import SwiftUI

// MARK: - Add Perspective View

struct AddPerspectiveView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    // Context: What we're replying to
    let story: StoryData
    let replyingTo: StorySegmentData? // nil = replying to story, non-nil = replying to specific response

    @State private var isRecording = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    @StateObject private var audioRecorder = AudioRecorderService()
    @StateObject private var audioMonitor = AudioLevelMonitor()

    // TODO: Get from actual user context
    private let currentUserId = "test-user-id"
    private let currentUserName = "You"
    private let currentUserRole = "parent"

    var contextPrompt: String {
        if let replying = replyingTo {
            return "Responding to \(replying.fullName)'s perspective..."
        } else {
            return story.title ?? "Add your perspective to this story"
        }
    }

    var body: some View {
        ZStack {
            Group {
                switch theme.role {
                case .teen:
                    TeenAddPerspective(
                        contextPrompt: contextPrompt,
                        replyingToName: replyingTo?.fullName,
                        isRecording: $isRecording,
                        recordingDuration: audioRecorder.recordingDuration,
                        audioLevels: audioMonitor.recentLevels,
                        onStartRecording: startRecording,
                        onStopRecording: stopRecording,
                        onCancel: { dismiss() }
                    )
                case .parent:
                    ParentAddPerspective(
                        contextPrompt: contextPrompt,
                        replyingToName: replyingTo?.fullName,
                        isRecording: $isRecording,
                        recordingDuration: audioRecorder.recordingDuration,
                        audioLevels: audioMonitor.recentLevels,
                        onStartRecording: startRecording,
                        onStopRecording: stopRecording,
                        onCancel: { dismiss() }
                    )
                case .child:
                    ChildAddPerspective(
                        contextPrompt: contextPrompt,
                        replyingToName: replyingTo?.fullName,
                        isRecording: $isRecording,
                        recordingDuration: audioRecorder.recordingDuration,
                        currentAudioLevel: CGFloat(audioMonitor.currentLevel),
                        onStartRecording: startRecording,
                        onStopRecording: stopRecording,
                        onCancel: { dismiss() }
                    )
                case .elder:
                    ElderAddPerspective(
                        contextPrompt: contextPrompt,
                        onCancel: { dismiss() }
                    )
                }
            }
            .animation(theme.animation, value: isRecording)

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
}

// MARK: - Teen Add Perspective (Minimal)

struct TeenAddPerspective: View {
    @Environment(\.theme) var theme

    let contextPrompt: String
    let replyingToName: String?
    @Binding var isRecording: Bool
    let recordingDuration: TimeInterval
    let audioLevels: [CGFloat]
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
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
                // Header
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

                    if isRecording {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .opacity(animateWave ? 1 : 0.3)

                            Text(formattedTime)
                                .font(.system(size: 15, weight: .medium, design: .monospaced))
                                .foregroundColor(theme.textColor)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(theme.cardBackgroundColor)
                        )
                    }

                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
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

                // Waveform
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
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.15).repeatForever(autoreverses: true)) {
                animateWave = true
            }
        }
    }
}

// MARK: - Parent Add Perspective (Professional)

struct ParentAddPerspective: View {
    @Environment(\.theme) var theme

    let contextPrompt: String
    let replyingToName: String?
    @Binding var isRecording: Bool
    let recordingDuration: TimeInterval
    let audioLevels: [CGFloat]
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
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

                    // Recording Section
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

                    // Controls
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

// MARK: - Child Add Perspective (Playful)

struct ChildAddPerspective: View {
    @Environment(\.theme) var theme

    let contextPrompt: String
    let replyingToName: String?
    @Binding var isRecording: Bool
    let recordingDuration: TimeInterval
    let currentAudioLevel: CGFloat
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
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
                // Header
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
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()

                if isRecording {
                    // Recording visualization
                    ChildRecordingVisualizer(
                        duration: recordingDuration,
                        audioLevel: currentAudioLevel,
                        accentColor: theme.accentColor
                    )
                } else {
                    // Ready state
                    VStack(spacing: 24) {
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
                }

                Spacer()

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

// MARK: - Elder Add Perspective (Phone Call)

struct ElderAddPerspective: View {
    @Environment(\.theme) var theme

    let contextPrompt: String
    let onCancel: () -> Void

    @State private var callScheduled = false

    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
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
                }
                .padding(.horizontal, 32)
                .padding(.top, 24)

                Spacer()

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
