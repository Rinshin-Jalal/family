//
//  InlinePerspectiveInput.swift
//  StoryRide
//
//  Compact, WhatsApp-inspired input component for adding perspectives
//  Based on mobile UX best practices: press-and-hold recording, icon-only buttons
//

import SwiftUI
import AVFoundation

// MARK: - Inline Perspective Input (Redesigned)

struct InlinePerspectiveInput: View {
    @Environment(\.theme) var theme
    @Binding var inputText: String
    @Binding var isRecording: Bool
    @Binding var isParentRecordingMode: Bool
    @State private var recordingDuration: TimeInterval = 0
    @State private var recordingTimer: Timer?
    @State private var dragOffset: CGFloat = 0
    @State private var amplitudes: [CGFloat] = Array(repeating: 0.3, count: 20)

    let onSend: (String) -> Void
    let onRecordingStart: () -> Void
    let onRecordingUpdate: (TimeInterval) -> Void
    let onRecordingComplete: (TimeInterval) -> Void
    let onCancel: () -> Void

    private var recordingState: RecordingState {
        if isParentRecordingMode { return .parentControlled }
        if isRecording { return .recording }
        return .idle
    }

    private enum RecordingState {
        case idle, recording, parentControlled
    }

    var body: some View {
        VStack(spacing: 0) {
            switch recordingState {
            case .recording:
                recordingBarView
            case .idle, .parentControlled:
                inputBarView
            }
        }
        .padding(.horizontal, 8)
        .glassEffect()
        .padding(.horizontal,10)
        .padding(.top, 12)
        .padding(.bottom, 12 + safeAreaBottom)
    }

    private var safeAreaBottom: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .first?
            .safeAreaInsets
            .bottom ?? 34
    }

    // MARK: - Recording Bar (WhatsApp-style)

    private var recordingBarView: some View {
        HStack(spacing: 12) {
            // Cancel slide area
            ZStack {
                if dragOffset < -60 {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Cancel")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.red))
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: 80)

            // Waveform + Timer
            HStack(spacing: 8) {
                // Compact waveform
                HStack(spacing: 2) {
                    ForEach(0..<20, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(theme.accentColor)
                            .frame(width: 3, height: 6 + amplitudes[index] * 14)
                    }
                }
                .frame(height: 24)

                // Timer
                Text(formattedDuration)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(theme.accentColor)
            }
            .frame(maxWidth: .infinity)

            // Stop button
            Button(action: { stopRecording() }) {
                ZStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 50, height: 50)

                    Image(systemName: "stop.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    dragOffset = value.translation.width
                    if dragOffset < -100 {
                        // Cancel threshold reached
                        cancelRecording()
                        dragOffset = 0
                    }
                }
                .onEnded { _ in
                    dragOffset = 0
                }
        )
        .onAppear {
            startWaveformAnimation()
        }
        .onDisappear {
            stopWaveformAnimation()
        }
    }

    // MARK: - Input Bar (Always Visible)

    private var inputBarView: some View {
        HStack(spacing: 12) {
            // Attachment button (icon-only)
            Button(action: {}) {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(theme.secondaryTextColor)
            }
            .buttonStyle(.glass)

            // Text input
            HStack(spacing: 8) {
                TextField("", text: $inputText, axis: .vertical)
                    .font(.system(size: 16))
                    .foregroundColor(theme.textColor)
                    .textFieldStyle(.plain)
                    .lineLimit(1...4)
                    .frame(height: 36)

                // Conditional send button (appears when has content)
                if !inputText.isEmpty {
                    Button(action: {
                        onSend(inputText)
                        inputText = ""
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(theme.accentColor)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
    

            // Mic button (press-and-hold to record)
            Button(action: {}) {
                ZStack {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.accentColor)
                }
            }
            .buttonStyle(.glass)
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0)
                    .onChanged { isPressing in
                        if isPressing && !isRecording {
                            startRecording()
                        }
                    }
                    .onEnded { _ in
                        if isRecording && recordingDuration > 0.5 {
                            stopRecording()
                        }
                    }
            )
        }
    }

    // MARK: - Helper Functions

    private var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func startRecording() {
        onRecordingStart()
        isRecording = true
        recordingDuration = 0

        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            recordingDuration += 0.1
            onRecordingUpdate(recordingDuration)
        }
    }

    private func stopRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        isRecording = false
        onRecordingComplete(recordingDuration)
        recordingDuration = 0
        stopWaveformAnimation()
    }

    private func cancelRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        isRecording = false
        onCancel()
        recordingDuration = 0
        stopWaveformAnimation()
    }

    private func startWaveformAnimation() {
        for index in 0..<20 {
            withAnimation(
                .easeInOut(duration: 0.2 + Double(index) * 0.02)
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.03)
            ) {
                amplitudes[index] = CGFloat.random(in: 0.3...1.0)
            }
        }
    }

    private func stopWaveformAnimation() {
        amplitudes = Array(repeating: 0.3, count: 20)
    }
}

// MARK: - Legacy Recording Interface (Kept for compatibility)

struct InlineRecordingInterface: View {
    @Environment(\.theme) var theme
    let duration: TimeInterval
    let isRecording: Bool
    let onStop: () -> Void
    let onCancel: () -> Void

    @State private var amplitudes: [CGFloat] = Array(repeating: 0.5, count: 30)

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Recording...")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.textColor)
                Spacer()
                Text(formattedDuration)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.red)
            }

            // Animated waveform
            HStack(spacing: 3) {
                ForEach(0..<30, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.accentColor)
                        .frame(width: 4, height: 8 + amplitudes[index] * 24)
                }
            }
            .frame(height: 40)
            .onAppear {
                startAnimation()
            }

            // Control buttons (icon-only)
            HStack(spacing: 16) {
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(theme.secondaryTextColor)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: onStop) {
                    Image(systemName: "stop.circle.fill")
                        .font(.title)
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.cardBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.3), lineWidth: 2)
                )
        )
    }

    private func startAnimation() {
        for index in 0..<30 {
            withAnimation(
                .easeInOut(duration: 0.5 + Double(index) * 0.03)
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.05)
            ) {
                amplitudes[index] = CGFloat.random(in: 0.2...1.0)
            }
        }
    }
}

// MARK: - Compact Variant (Minimalist, icon-only)

struct CompactPerspectiveInput: View {
    @Environment(\.theme) var theme
    @Binding var inputText: String
    @State private var isRecording = false

    let onSend: (String) -> Void
    let onRecord: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            // Text input (no placeholder, cleaner look)
            HStack(spacing: 6) {
                TextField("", text: $inputText)
                    .font(.system(size: 15))
                    .foregroundColor(theme.textColor)
                    .textFieldStyle(.plain)
                    .lineLimit(1...3)

                // Conditional send button
                if !inputText.isEmpty {
                    Button(action: {
                        onSend(inputText)
                        inputText = ""
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(theme.accentColor)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        

            // Mic button (press-and-hold)
            Button(action: onRecord) {
                ZStack {
                    Circle()
                        .fill(isRecording ? Color.red : theme.accentColor.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isRecording ? .white : theme.accentColor)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(theme.cardBackgroundColor)
        .overlay(
            Rectangle()
                .fill(Color.black.opacity(0.1))
                .frame(height: 0.5),
            alignment: .top
        )
    }
}

// MARK: - Child-Friendly Variant (Fun, large, playful)

struct ChildPerspectiveInput: View {
    @Environment(\.theme) var theme
    @Binding var inputText: String
    @State private var isRecording = false

    let onSend: (String) -> Void
    let onRecord: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Big fun record button
            Button(action: onRecord) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: isRecording ? [Color.red, Color.red.opacity(0.8)] : [theme.accentColor, theme.accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 100, height: 100)
                        .shadow(color: (isRecording ? Color.red : theme.accentColor).opacity(0.4), radius: 15)

                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(isRecording ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isRecording)
            }
            .buttonStyle(.plain)

            // Or type option (compact)
            Button(action: {
                // TODO: Show text input
            }) {
                Image(systemName: "keyboard")
                    .font(.title2)
                    .foregroundColor(theme.secondaryTextColor)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(theme.cardBackgroundColor)
                .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

// MARK: - Elder-Friendly Variant (Large, accessible, clear)

struct ElderPerspectiveInput: View {
    @Environment(\.theme) var theme
    @Binding var inputText: String
    @State private var isRecording = false

    let onSend: (String) -> Void
    let onRecord: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Large accessible record button
            Button(action: onRecord) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(isRecording ? Color.red : theme.accentColor)
                            .frame(width: 72, height: 72)
                            .shadow(color: (isRecording ? Color.red : theme.accentColor).opacity(0.3), radius: 10)

                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(isRecording ? "Recording..." : "Record")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(theme.textColor)
                        Text(isRecording ? "Tap to stop" : "Tap to start")
                            .font(.system(size: 15))
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(theme.cardBackgroundColor)
                        .shadow(color: .black.opacity(0.08), radius: 8)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(theme.backgroundColor)
    }
}

// MARK: - Preview

struct InlinePerspectiveInput_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Main redesigned component
            VStack {
                Spacer()
                InlinePerspectiveInput(
                    inputText: .constant(""),
                    isRecording: .constant(false),
                    isParentRecordingMode: .constant(false),
                    onSend: { _ in },
                    onRecordingStart: {},
                    onRecordingUpdate: { _ in },
                    onRecordingComplete: { _ in },
                    onCancel: {}
                )
            }
            .themed(TeenTheme())
            .previewDisplayName("Teen - Redesigned (WhatsApp-style)")

            // Compact variant
            VStack {
                Spacer()
                CompactPerspectiveInput(
                    inputText: .constant(""),
                    onSend: { _ in },
                    onRecord: {}
                )
            }
            .themed(ParentTheme())
            .previewDisplayName("Parent - Compact (Icon-only)")

            // Child variant
            VStack {
                Spacer()
                ChildPerspectiveInput(
                    inputText: .constant(""),
                    onSend: { _ in },
                    onRecord: {}
                )
            }
            .themed(ChildTheme())
            .previewDisplayName("Child - Fun & Large")

            // Elder variant
            VStack {
                Spacer()
                ElderPerspectiveInput(
                    inputText: .constant(""),
                    onSend: { _ in },
                    onRecord: {}
                )
            }
            .themed(ElderTheme())
            .previewDisplayName("Elder - Accessible")
        }
    }
}
