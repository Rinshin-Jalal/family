//
//  StudioView.swift
//  StoryRide
//
//  The Studio - Polished recording interfaces for each persona
//

import SwiftUI

// MARK: - Studio View

struct StudioView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    @State private var prompt = "What was your favorite childhood memory?"
    @State private var isRecording = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    @StateObject private var audioRecorder = AudioRecorderService()
    @StateObject private var audioMonitor = AudioLevelMonitor()

    // TODO: Get these from actual user context
    private let familyId = "test-family-id"
    private let storyId = "test-story-id"

    var body: some View {
        ZStack {
            Group {
                switch theme.role {
                case .teen:
                    TeenStudio(
                        prompt: prompt,
                        isRecording: $isRecording,
                        recordingDuration: audioRecorder.recordingDuration,
                        audioLevels: audioMonitor.recentLevels,
                        onStartRecording: startRecording,
                        onStopRecording: stopRecording
                    )
                case .parent:
                    ParentStudio(
                        prompt: $prompt,
                        isRecording: $isRecording,
                        recordingDuration: audioRecorder.recordingDuration,
                        audioLevels: audioMonitor.recentLevels,
                        onStartRecording: startRecording,
                        onStopRecording: stopRecording
                    )
                case .child:
                    ChildStudio(
                        prompt: prompt,
                        isRecording: $isRecording,
                        recordingDuration: audioRecorder.recordingDuration,
                        currentAudioLevel: CGFloat(audioMonitor.currentLevel),
                        onStartRecording: startRecording,
                        onStopRecording: stopRecording
                    )
                case .elder:
                    ElderStudio(prompt: prompt, isRecording: $isRecording)
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
                let publicURL = try await SupabaseService.shared.uploadAudio(
                    fileURL: recordingURL,
                    familyId: familyId,
                    storyId: storyId
                )

                print("✅ Recording saved! Public URL: \(publicURL)")

                // TODO: Send publicURL to backend API to create story segment

                // Clean up local file
                try? FileManager.default.removeItem(at: recordingURL)

                isSaving = false
                dismiss()
            } catch {
                isSaving = false
                errorMessage = "Failed to save recording: \(error.localizedDescription)"

                // Clean up local file even on error
                try? FileManager.default.removeItem(at: recordingURL)
            }
        }
    }
}

// MARK: - Saving Overlay

struct SavingOverlay: View {
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)

                Text("Saving your story...")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
        }
    }
}

// MARK: - Teen Studio (Minimal Elegance)

struct TeenStudio: View {
    let prompt: String
    @Binding var isRecording: Bool
    let recordingDuration: TimeInterval
    let audioLevels: [CGFloat]  // Real audio levels from speech
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void

    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
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
                    Button(action: { dismiss() }) {
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
                        // Recording indicator
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

                    // Placeholder for balance
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()

                // Prompt Card
                VStack(spacing: 20) {
                    Text("Today's Prompt")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(theme.accentColor)
                        .textCase(.uppercase)
                        .tracking(1.5)

                    Text(prompt)
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

                // Waveform visualizer - responds to real speech!
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

                    Text(isRecording ? "Tap to finish" : "Tap to record")
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

// MARK: - Teen Waveform Visualizer

struct TeenWaveformVisualizer: View {
    let amplitudes: [CGFloat]
    let accentColor: Color

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<amplitudes.count, id: \.self) { index in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 3, height: max(4, amplitudes[index] * 60))
                    .animation(.spring(response: 0.15, dampingFraction: 0.7), value: amplitudes[index])
            }
        }
    }
}

// MARK: - Teen Record Button

struct TeenRecordButton: View {
    let isRecording: Bool
    let accentColor: Color
    let textColor: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer ring
                Circle()
                    .strokeBorder(
                        isRecording ? Color.red.opacity(0.3) : accentColor.opacity(0.2),
                        lineWidth: 4
                    )
                    .frame(width: 100, height: 100)

                // Inner circle
                Circle()
                    .fill(isRecording ? Color.red : accentColor)
                    .frame(width: isRecording ? 36 : 72, height: isRecording ? 36 : 72)
                    .clipShape(isRecording ? AnyShape(RoundedRectangle(cornerRadius: 8)) : AnyShape(Circle()))

                // Mic icon (only when not recording)
                if !isRecording {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Parent Studio (Professional Dashboard)

struct ParentStudio: View {
    @Binding var prompt: String
    @Binding var isRecording: Bool
    let recordingDuration: TimeInterval
    let audioLevels: [CGFloat]  // Real audio levels from speech
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void

    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    @State private var isEditingPrompt = false
    @State private var showPromptLibrary = false

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
                    // Prompt Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Label("Story Prompt", systemImage: "text.quote")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(theme.secondaryTextColor)

                            Spacer()

                            Menu {
                                Button(action: { isEditingPrompt = true }) {
                                    Label("Edit Prompt", systemImage: "pencil")
                                }
                                Button(action: { showPromptLibrary = true }) {
                                    Label("Browse Library", systemImage: "book")
                                }
                                Button(action: {}) {
                                    Label("Random Prompt", systemImage: "shuffle")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .font(.system(size: 20))
                                    .foregroundColor(theme.accentColor)
                            }
                        }

                        if isEditingPrompt {
                            TextEditor(text: $prompt)
                                .font(.system(size: 18, weight: .medium, design: .serif))
                                .frame(minHeight: 100)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.systemBackground))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .strokeBorder(theme.accentColor, lineWidth: 2)
                                        )
                                )

                            HStack {
                                Spacer()
                                Button("Done") {
                                    isEditingPrompt = false
                                }
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(theme.accentColor)
                            }
                        } else {
                            Text(prompt)
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
                    }
                    .padding(24)

                    Divider()
                        .padding(.horizontal, 24)

                    // Recording Section
                    VStack(spacing: 32) {
                        if isRecording {
                            // Recording visualization
                            VStack(spacing: 24) {
                                // Live waveform - responds to real speech!
                                ParentWaveformView(levels: audioLevels, accentColor: theme.accentColor)
                                    .frame(height: 100)
                                    .padding(.horizontal, 24)

                                // Timer
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
                            // Idle state
                            VStack(spacing: 16) {
                                Image(systemName: "waveform.circle")
                                    .font(.system(size: 80))
                                    .foregroundColor(theme.secondaryTextColor.opacity(0.3))

                                Text("Ready to record")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(theme.secondaryTextColor)
                            }
                            .frame(height: 160)
                        }
                    }
                    .frame(maxHeight: .infinity)

                    // Controls
                    VStack(spacing: 16) {
                        // Record Button
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

                        // Alternative option
                        if !isRecording {
                            Button(action: {}) {
                                HStack(spacing: 8) {
                                    Image(systemName: "keyboard")
                                        .font(.system(size: 15))
                                    Text("Type your response instead")
                                        .font(.system(size: 15, weight: .medium))
                                }
                                .foregroundColor(theme.accentColor)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Record Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(theme.accentColor)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isRecording {
                        Button("Done") {
                            onStopRecording()
                            // Save and dismiss
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(theme.accentColor)
                    }
                }
            }
        }
    }
}

// MARK: - Parent Waveform View

struct ParentWaveformView: View {
    let levels: [CGFloat]
    let accentColor: Color

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                ForEach(0..<levels.count, id: \.self) { index in
                    Capsule()
                        .fill(accentColor.opacity(0.8))
                        .frame(width: (geo.size.width - CGFloat(levels.count - 1) * 2) / CGFloat(levels.count))
                        .frame(height: max(4, levels[index] * geo.size.height))
                        .animation(.spring(response: 0.1, dampingFraction: 0.6), value: levels[index])
                }
            }
            .frame(height: geo.size.height, alignment: .center)
        }
    }
}

// MARK: - Parent Record Button

struct ParentRecordButton: View {
    let isRecording: Bool
    let accentColor: Color
    let action: () -> Void

    @State private var isPressed = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        Button(action: action) {
            ZStack {
                // Pulse effect when recording
                if isRecording {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .scaleEffect(pulseScale)
                }

                // Main button
                Circle()
                    .fill(isRecording ? Color.red : accentColor)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Group {
                            if isRecording {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.white)
                                    .frame(width: 24, height: 24)
                            } else {
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                    )
                    .shadow(color: (isRecording ? Color.red : accentColor).opacity(0.4), radius: 12, y: 6)
            }
            .scaleEffect(isPressed ? 0.92 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.spring(response: 0.2)) { isPressed = true } }
                .onEnded { _ in withAnimation(.spring(response: 0.2)) { isPressed = false } }
        )
        .onAppear {
            if isRecording {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    pulseScale = 1.3
                }
            }
        }
        .onChange(of: isRecording) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    pulseScale = 1.3
                }
            } else {
                pulseScale = 1.0
            }
        }
    }
}

// MARK: - Child Studio (Magic Microphone)

struct ChildStudio: View {
    let prompt: String
    @Binding var isRecording: Bool
    let recordingDuration: TimeInterval
    let currentAudioLevel: CGFloat  // Real audio level from speech
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void

    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    @State private var hasListenedToPrompt = false
    @State private var isPlayingPrompt = false
    @State private var showCelebration = false
    @State private var floatingEmojis: [FloatingEmoji] = []
    @State private var micScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3

    var body: some View {
        ZStack {
            // Animated gradient background
            ChildStudioBackground(isRecording: isRecording, accentColor: theme.accentColor)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with back button
                HStack {
                    Button(action: { dismiss() }) {
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

                // Main content
                if !hasListenedToPrompt && !isRecording {
                    // Listen to prompt first
                    ChildListenButton(isPlaying: isPlayingPrompt) {
                        isPlayingPrompt = true
                        // Simulate prompt playing
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            isPlayingPrompt = false
                            hasListenedToPrompt = true
                        }
                    }
                    .padding(.horizontal, 32)
                } else if isRecording {
                    // Recording state - magical visualization responds to real speech!
                    ChildRecordingVisualizer(
                        duration: recordingDuration,
                        audioLevel: currentAudioLevel,
                        accentColor: theme.accentColor
                    )
                } else {
                    // Ready to record state
                    VStack(spacing: 24) {
                        Text("Your turn to talk!")
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundColor(theme.textColor)

                        Text("Tap the magic mic")
                            .font(.system(size: 24, weight: .medium, design: .rounded))
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }

                Spacer()

                // Giant magic microphone button
                if hasListenedToPrompt || isRecording {
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

                    // Helper text
                    Text(isRecording ? "Tap when you're done!" : "")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(theme.accentColor)
                        .padding(.bottom, 40)
                }
            }

            // Celebration overlay
            if showCelebration {
                ChildCelebrationView {
                    showCelebration = false
                    dismiss()
                }
                .transition(.opacity)
            }

            // Floating emojis during recording
            ForEach(floatingEmojis) { emoji in
                Text(emoji.symbol)
                    .font(.system(size: 40))
                    .position(emoji.position)
            }
        }
        .onChange(of: isRecording) { _, newValue in
            if newValue {
                startFloatingEmojis()
            } else {
                floatingEmojis.removeAll()
            }
        }
    }

    private func startFloatingEmojis() {
        let emojis = ["", "", "", "", "", "", "", ""]
        Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { timer in
            guard isRecording else {
                timer.invalidate()
                return
            }

            let newEmoji = FloatingEmoji(
                symbol: emojis.randomElement() ?? "",
                position: CGPoint(
                    x: CGFloat.random(in: 50...UIScreen.main.bounds.width - 50),
                    y: UIScreen.main.bounds.height + 50
                )
            )
            floatingEmojis.append(newEmoji)

            withAnimation(.easeOut(duration: 3)) {
                if let index = floatingEmojis.firstIndex(where: { $0.id == newEmoji.id }) {
                    floatingEmojis[index].position.y = -100
                }
            }

            // Clean up old emojis
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                floatingEmojis.removeAll { $0.id == newEmoji.id }
            }
        }
    }
}

struct FloatingEmoji: Identifiable {
    let id = UUID()
    let symbol: String
    var position: CGPoint
}

// MARK: - Child Studio Background

struct ChildStudioBackground: View {
    let isRecording: Bool
    let accentColor: Color

    @State private var animate = false

    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color.playfulOrange.opacity(0.1),
                    Color.storytellerPurple.opacity(0.1),
                    Color.storytellerGreen.opacity(0.1)
                ],
                startPoint: animate ? .topLeading : .bottomTrailing,
                endPoint: animate ? .bottomTrailing : .topLeading
            )

            // Floating shapes
            ForEach(0..<6) { index in
                Circle()
                    .fill(
                        [Color.playfulOrange, .storytellerPurple, .storytellerGreen, .storytellerBlue][index % 4]
                            .opacity(0.1)
                    )
                    .frame(width: CGFloat.random(in: 100...200))
                    .offset(
                        x: CGFloat.random(in: -150...150),
                        y: animate ? CGFloat.random(in: -300...300) : CGFloat.random(in: -200...200)
                    )
                    .blur(radius: 40)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

// MARK: - Child Listen Button

struct ChildListenButton: View {
    let isPlaying: Bool
    let action: () -> Void

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        Button(action: action) {
            VStack(spacing: 20) {
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(Color.storytellerBlue.opacity(0.3))
                        .frame(width: 160, height: 160)
                        .scaleEffect(pulseScale)
                        .blur(radius: 20)

                    // Main circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.storytellerBlue, Color.storytellerPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .shadow(color: Color.storytellerBlue.opacity(0.5), radius: 20, y: 10)

                    // Icon
                    Image(systemName: isPlaying ? "waveform" : "speaker.wave.3.fill")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundColor(.white)
                        .symbolEffect(.variableColor, isActive: isPlaying)
                }

                Text(isPlaying ? "Listening..." : "Tap to hear the question!")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.15
            }
        }
    }
}

// MARK: - Child Recording Visualizer

struct ChildRecordingVisualizer: View {
    let duration: TimeInterval
    let audioLevel: CGFloat  // Real audio level from speech
    let accentColor: Color

    var formattedTime: String {
        let seconds = Int(duration)
        return "\(seconds)"
    }

    // Reactive scale based on actual audio level!
    var audioReactiveScale: CGFloat {
        1.0 + (audioLevel * 0.3) // Scale from 1.0 to 1.3 based on volume
    }

    var body: some View {
        VStack(spacing: 32) {
            // Animated character - responds to real speech!
            ZStack {
                // Circular waves that pulse with voice
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(
                            accentColor.opacity(0.3 - Double(index) * 0.1 + (Double(audioLevel) * 0.2)),
                            lineWidth: 4 + (audioLevel * 4) // Thicker when louder
                        )
                        .frame(width: 200 + CGFloat(index) * 40, height: 200 + CGFloat(index) * 40)
                        .scaleEffect(audioReactiveScale + CGFloat(index) * 0.1)
                        .animation(.spring(response: 0.15, dampingFraction: 0.6), value: audioLevel)
                }

                // Center emoji that bounces with voice
                Text("")
                    .font(.system(size: 100))
                    .scaleEffect(audioReactiveScale)
                    .animation(.spring(response: 0.15, dampingFraction: 0.6), value: audioLevel)
            }

            VStack(spacing: 12) {
                Text(audioLevel > 0.5 ? "I hear you!" : "I'm listening!")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundColor(.primary)
                    .animation(.easeInOut(duration: 0.2), value: audioLevel > 0.5)

                Text("\(formattedTime) seconds")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(accentColor)
            }
        }
    }
}

// MARK: - Child Magic Mic Button

struct ChildMagicMicButton: View {
    let isRecording: Bool
    let accentColor: Color
    let action: () -> Void

    @State private var isPressed = false
    @State private var glowAmount: CGFloat = 0.5
    @State private var rotation: Double = 0

    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                (isRecording ? Color.red : accentColor).opacity(glowAmount),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 60,
                            endRadius: 120
                        )
                    )
                    .frame(width: 200, height: 200)

                // Sparkle ring
                ForEach(0..<8) { index in
                    Image(systemName: "sparkle")
                        .font(.system(size: 20))
                        .foregroundColor(isRecording ? .red : accentColor)
                        .offset(y: -85)
                        .rotationEffect(.degrees(Double(index) * 45 + rotation))
                        .opacity(glowAmount)
                }

                // Main button
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isRecording ?
                                [Color.red, Color.red.opacity(0.8)] :
                                [accentColor, accentColor.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 140, height: 140)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 4)
                    )
                    .shadow(color: (isRecording ? Color.red : accentColor).opacity(0.5), radius: 20, y: 8)

                // Icon
                if isRecording {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                        .frame(width: 40, height: 40)
                } else {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.spring(response: 0.2)) { isPressed = true } }
                .onEnded { _ in withAnimation(.spring(response: 0.2)) { isPressed = false } }
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowAmount = 0.8
            }
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - Child Celebration View

struct ChildCelebrationView: View {
    let onDismiss: () -> Void

    @State private var showContent = false
    @State private var confettiActive = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Text("")
                    .font(.system(size: 120))
                    .scaleEffect(showContent ? 1 : 0.1)
                    .rotationEffect(.degrees(showContent ? 0 : -180))

                VStack(spacing: 16) {
                    Text("Amazing!")
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)

                    Text("Your story is saved!")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)

                Button(action: onDismiss) {
                    Text("Hooray!")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 200, height: 70)
                        .background(
                            Capsule()
                                .fill(Color.storytellerGreen)
                                .shadow(color: Color.storytellerGreen.opacity(0.5), radius: 12, y: 6)
                        )
                }
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.5)
            }

            // Confetti
            if confettiActive {
                ConfettiView()
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showContent = true
            }
            confettiActive = true
        }
    }
}

// MARK: - Elder Studio (Simple & Clear)

struct ElderStudio: View {
    let prompt: String
    @Binding var isRecording: Bool
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    @State private var callScheduled = false

    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
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
                    // Main content - Phone recording option
                    VStack(spacing: 40) {
                        // Phone illustration
                        ZStack {
                            Circle()
                                .fill(theme.accentColor.opacity(0.15))
                                .frame(width: 200, height: 200)

                            Circle()
                                .fill(theme.accentColor.opacity(0.1))
                                .frame(width: 160, height: 160)

                            Image(systemName: "phone.fill")
                                .font(.system(size: 80, weight: .medium))
                                .foregroundColor(theme.accentColor)
                        }

                        VStack(spacing: 20) {
                            Text("Share Your Story")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(theme.textColor)

                            Text("We'll call you and ask\nabout your memories")
                                .font(.system(size: 26))
                                .foregroundColor(theme.secondaryTextColor)
                                .multilineTextAlignment(.center)
                                .lineSpacing(8)
                        }
                    }

                    Spacer()

                    // Call button
                    VStack(spacing: 20) {
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

                        Text("or")
                            .font(.system(size: 24))
                            .foregroundColor(theme.secondaryTextColor)

                        Button(action: {}) {
                            HStack(spacing: 16) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 28, weight: .semibold))
                                Text("Schedule for Later")
                                    .font(.system(size: 28, weight: .semibold))
                            }
                            .foregroundColor(theme.accentColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 80)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .strokeBorder(theme.accentColor, lineWidth: 3)
                            )
                        }
                        .padding(.horizontal, 32)
                    }
                    .padding(.bottom, 60)
                } else {
                    // Call scheduled confirmation
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

                            Text("Please answer your phone\nwhen it rings")
                                .font(.system(size: 28))
                                .foregroundColor(theme.secondaryTextColor)
                                .multilineTextAlignment(.center)
                                .lineSpacing(8)
                        }

                        // Simulated ringing animation
                        Image(systemName: "phone.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                            .symbolEffect(.pulse)
                    }

                    Spacer()

                    Button(action: { dismiss() }) {
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

// MARK: - AnyShape Helper

struct AnyShape: Shape {
    private let path: (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        path = { rect in
            shape.path(in: rect)
        }
    }

    func path(in rect: CGRect) -> Path {
        path(rect)
    }
}

// MARK: - Stories View (Library of all family stories)

struct StoriesView: View {
    @Environment(\.theme) var theme
    @State private var selectedStory: Story?
    @State private var searchText = ""

    // Filter stories based on search
    var filteredStories: [Story] {
        let stories = Story.sampleStories
        if searchText.isEmpty {
            return stories
        } else {
            return stories.filter { story in
                story.title.localizedCaseInsensitiveContains(searchText) ||
                story.storyteller.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        Group {
            switch theme.role {
            case .teen:
                TeenStoriesView(stories: filteredStories, selectedStory: $selectedStory)
            case .parent:
                ParentStoriesView(stories: filteredStories, selectedStory: $selectedStory)
            case .child:
                ChildStoriesView(stories: filteredStories, selectedStory: $selectedStory)
            case .elder:
                ElderStoriesView(stories: filteredStories, selectedStory: $selectedStory)
            }
        }
        .sheet(item: $selectedStory) { story in
            NavigationStack {
                StoryDetailView(story: story)
            }
        }
    }
}

// MARK: - Teen Stories View (Grid Layout)

struct TeenStoriesView: View {
    let stories: [Story]
    @Binding var selectedStory: Story?
    @Environment(\.theme) var theme

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Library")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(theme.textColor)
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20))
                        .foregroundColor(theme.secondaryTextColor)
                }
                .padding(.horizontal, 24)

                // Stories grid
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(stories) { story in
                        Button {
                            selectedStory = story
                        } label: {
                            TeenStoryCard(story: story, theme: theme)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.vertical, 24)
        }
        .background(theme.backgroundColor.ignoresSafeArea())
    }
}

// MARK: - Parent Stories View (Organized List)

struct ParentStoriesView: View {
    let stories: [Story]
    @Binding var selectedStory: Story?
    @Environment(\.theme) var theme
    @State private var filterOption: StoryFilter = .all

    enum StoryFilter: String, CaseIterable {
        case all = "All"
        case recent = "Recent"
        case favorites = "Favorites"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(StoryFilter.allCases, id: \.self) { filter in
                            FilterPill(title: filter.rawValue, isSelected: filterOption == filter) {
                                withAnimation {
                                    filterOption = filter
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }

                Divider()

                // Stories list
                if stories.isEmpty {
                    StoriesEmptyState(theme: theme)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(stories) { story in
                                ParentStoryRow(story: story) {
                                    selectedStory = story
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }
                }
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationTitle("All Stories")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.theme) var theme

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isSelected ? .white : theme.accentColor)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? theme.accentColor : Color.clear)
                        .overlay(
                            Capsule()
                                .strokeBorder(theme.accentColor, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

struct ParentStoryRow: View {
    let story: Story
    let action: () -> Void
    @Environment(\.theme) var theme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Thumbnail
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [story.storytellerColor.opacity(0.6), story.storytellerColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                // Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(story.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(theme.textColor)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Circle()
                            .fill(story.storytellerColor)
                            .frame(width: 8, height: 8)

                        Text(story.storyteller)
                            .font(.system(size: 14))
                            .foregroundColor(theme.secondaryTextColor)

                        Text("•")
                            .font(.system(size: 12))
                            .foregroundColor(theme.secondaryTextColor)

                        Text(story.timestamp, style: .relative)
                            .font(.system(size: 13))
                            .foregroundColor(theme.secondaryTextColor.opacity(0.7))
                    }
                }
                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.secondaryTextColor)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.cardBackgroundColor)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Child Stories View (Playful Cards)

struct ChildStoriesView: View {
    let stories: [Story]
    @Binding var selectedStory: Story?
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("All My Stories!")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundColor(theme.textColor)
                Spacer()
                Image(systemName: "sparkles")
                    .font(.system(size: 28))
                    .foregroundColor(theme.accentColor)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)

            if stories.isEmpty {
                StoriesEmptyState(theme: theme)
            } else {
                // Stories as playable cards
                ScrollView {
                    LazyVStack(spacing: 24) {
                        ForEach(stories) { story in
                            Button {
                                selectedStory = story
                            } label: {
                                ChildStoryCard(story: story, theme: theme)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
            }
        }
        .background(theme.backgroundColor.ignoresSafeArea())
    }
}

// MARK: - Elder Stories View (Simple List)

struct ElderStoriesView: View {
    let stories: [Story]
    @Binding var selectedStory: Story?
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("All Stories")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(theme.textColor)
                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)

            Divider()

            if stories.isEmpty {
                StoriesEmptyState(theme: theme)
            } else {
                // Simple list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(stories) { story in
                            ElderStoryRow(story: story) {
                                selectedStory = story
                            }
                        }
                    }
                }
            }
        }
        .background(theme.backgroundColor.ignoresSafeArea())
    }
}

struct ElderStoryRow: View {
    let story: Story
    let action: () -> Void
    @Environment(\.theme) var theme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                // Large thumbnail
                Rectangle()
                    .fill(story.storytellerColor.opacity(0.6))
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                // Info
                VStack(alignment: .leading, spacing: 12) {
                    Text(story.title)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(theme.textColor)
                        .lineLimit(2)

                    Text("By \(story.storyteller)")
                        .font(.system(size: 20))
                        .foregroundColor(story.storytellerColor)

                    Text(story.timestamp, style: .date)
                        .font(.system(size: 18))
                        .foregroundColor(theme.secondaryTextColor)
                }
                Spacer()

                // Large play button
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(theme.accentColor)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.cardBackgroundColor)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty State

struct StoriesEmptyState: View {
    let theme: PersonaTheme

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "book.closed")
                .font(.system(size: 80))
                .foregroundColor(theme.secondaryTextColor.opacity(0.5))

            VStack(spacing: 16) {
                Text("No Stories Yet")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(theme.textColor)

                Text("Start recording to build\nyour family's story collection")
                    .font(.system(size: 18))
                    .foregroundColor(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }

            Spacer()
        }
        .padding(40)
    }
}

// MARK: - Preview

struct StoriesView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StoriesView()
                .themed(TeenTheme())
                .previewDisplayName("Teen Stories")

            StoriesView()
                .themed(ParentTheme())
                .previewDisplayName("Parent Stories")

            StoriesView()
                .themed(ChildTheme())
                .previewDisplayName("Child Stories")

            StoriesView()
                .themed(ElderTheme())
                .previewDisplayName("Elder Stories")
        }
    }
}

// MARK: - Preview

struct StudioView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StudioView()
                .themed(TeenTheme())
                .previewDisplayName("Teen Studio")

            StudioView()
                .themed(ParentTheme())
                .previewDisplayName("Parent Studio")

            StudioView()
                .themed(ChildTheme())
                .previewDisplayName("Child Studio")

            StudioView()
                .themed(ElderTheme())
                .previewDisplayName("Elder Studio")
        }
    }
}
