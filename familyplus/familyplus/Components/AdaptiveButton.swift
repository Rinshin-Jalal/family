//
//  AdaptiveButton.swift
//  StoryRide
//
//  Buttons that adapt to persona themes
//

import SwiftUI

// MARK: - Record Button

struct RecordButton: View {
    @Environment(\.theme) var theme
    let isRecording: Bool
    let action: () -> Void

    @State private var isPulsing = false

    var body: some View {
        Button(action: {
            // Haptic feedback based on theme
            if theme.enableHaptics {
                let impact = theme.role == .child ?
                    UIImpactFeedbackGenerator(style: .heavy) :
                    UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
            }
            action()
        }) {
            ZStack {
                switch theme.role {
                case .teen:
                    // Ghost button - thin outline circle
                    Circle()
                        .strokeBorder(
                            isRecording ? theme.accentColor : theme.textColor.opacity(0.5),
                            lineWidth: 2
                        )
                        .frame(width: theme.buttonHeight, height: theme.buttonHeight)
                        .background(
                            Circle()
                                .fill(isRecording ? theme.accentColor.opacity(0.2) : Color.clear)
                        )

                case .parent:
                    // Solid circle with shadow
                    Circle()
                        .fill(isRecording ? Color.alertRed : theme.accentColor)
                        .frame(width: theme.buttonHeight, height: theme.buttonHeight)
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)

                case .child:
                    // Giant pulsing circle
                    Circle()
                        .fill(isRecording ? Color.alertRed : theme.accentColor)
                        .frame(width: theme.buttonHeight, height: theme.buttonHeight)
                        .scaleEffect(isPulsing && isRecording ? 1.1 : 1.0)
                        .shadow(color: theme.accentColor.opacity(0.5), radius: 20)

                case .elder:
                    // Elder uses phone - minimal button
                    Circle()
                        .fill(theme.accentColor)
                        .frame(width: theme.buttonHeight, height: theme.buttonHeight)
                }

                // Microphone icon
                Image(systemName: "mic.fill")
                    .font(.system(size: theme.role == .child ? 40 : 24))
                    .foregroundColor(theme.role == .teen && !isRecording ? theme.textColor : .white)
            }
        }
        .onAppear {
            if theme.role == .child && isRecording {
                withAnimation(
                    Animation.easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true)
                ) {
                    isPulsing = true
                }
            }
        }
        .accessibilityLabel(isRecording ? "Stop Recording" : "Start Recording")
        .accessibilityHint("Double tap to \(isRecording ? "stop" : "start") recording your story")
    }
}

// MARK: - Primary Action Button

struct AdaptiveButton: View {
    @Environment(\.theme) var theme
    let title: String
    let icon: String?
    let action: () -> Void

    var body: some View {
        Button(action: {
            if theme.enableHaptics {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
            }
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: theme.role == .child ? 28 : 17, weight: .semibold))
                }
                Text(title)
                    .font(theme.bodyFont)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: theme.buttonHeight)
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: theme.cardRadius)
                    .fill(theme.accentColor)
            )
            .shadow(
                color: theme.accentColor.opacity(0.3),
                radius: theme.role == .child ? 12 : 8,
                y: 4
            )
        }
        .accessibilityLabel(title)
    }
}

// MARK: - Secondary Button

struct SecondaryButton: View {
    @Environment(\.theme) var theme
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(theme.bodyFont)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .frame(height: theme.buttonHeight)
                .foregroundColor(theme.accentColor)
                .background(
                    RoundedRectangle(cornerRadius: theme.cardRadius)
                        .strokeBorder(theme.accentColor, lineWidth: 2)
                )
        }
        .accessibilityLabel(title)
    }
}

// MARK: - Listen Button (Child Mode)

struct ListenButton: View {
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 48))
                .foregroundColor(.white)

            Text("Listen")
                .font(theme.headlineFont)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(
            RoundedRectangle(cornerRadius: theme.cardRadius)
                .fill(theme.accentColor)
        )
        .shadow(color: theme.accentColor.opacity(0.4), radius: 20)
        .accessibilityLabel("Listen to story")
        .accessibilityHint("Double tap to hear the story read aloud")
    }
}

// MARK: - Preview

struct AdaptiveButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack(spacing: 20) {
                RecordButton(isRecording: false) {}
                RecordButton(isRecording: true) {}
                AdaptiveButton(title: "Continue", icon: "arrow.right") {}
                SecondaryButton(title: "Cancel") {}
            }
            .padding()
            .themed(TeenTheme())
            .previewDisplayName("Teen Theme")

            VStack(spacing: 20) {
                RecordButton(isRecording: false) {}
                AdaptiveButton(title: "Share Story", icon: "square.and.arrow.up") {}
                ListenButton()
            }
            .padding()
            .themed(ChildTheme())
            .previewDisplayName("Child Theme")
        }
    }
}
