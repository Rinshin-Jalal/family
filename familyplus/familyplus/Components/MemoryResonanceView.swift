//
//  MemoryResonanceView.swift
//  StoryRide
//
//  Post-listening flow that gently invites users to connect their own memories
//

import SwiftUI
import Combine

// MARK: - Memory Resonance State

@MainActor
class MemoryResonanceViewModel: ObservableObject {
    @Published var isShowingResonance: Bool = false
    @Published var currentResponse: StorySegmentData?
    @Published var resonanceLevel: ResonanceLevel = .none
    @Published var userMemory: String = ""
    @Published var isSubmitting: Bool = false

    enum ResonanceLevel: String, CaseIterable {
        case none = "none"
        case familiar = "familiar"
        case connected = "connected"
        case deeplyMoved = "deeplyMoved"

        var displayName: String {
            switch self {
            case .none: return "No resonance"
            case .familiar: return "Sounds familiar"
            case .connected: return "I've lived this"
            case .deeplyMoved: return "Deeply moved"
            }
        }

        var icon: String {
            switch self {
            case .none: return "circle"
            case .familiar: return "sparkles"
            case .connected: return "heart.fill"
            case .deeplyMoved: return "hands.sparkles.fill"
            }
        }

        var color: Color {
            switch self {
            case .none: return .gray
            case .familiar: return .blue
            case .connected: return .purple
            case .deeplyMoved: return .pink
            }
        }

        var placeholder: String {
            switch self {
            case .none: return ""
            case .familiar: return "What felt familiar about this memory?"
            case .connected: return "Tell us about a similar experience you've had..."
            case .deeplyMoved: return "Share what moved you about this memory..."
            }
        }
    }

    func showResonance(for response: StorySegmentData) {
        self.currentResponse = response
        self.resonanceLevel = .none
        self.userMemory = ""
        self.isShowingResonance = true
    }

    func dismiss() {
        isShowingResonance = false
        currentResponse = nil
    }

    func submitResonance() async -> Bool {
        guard currentResponse != nil,
              resonanceLevel != .none else { return false }

        isSubmitting = true

        // TODO: Submit to backend
        // - responseId (from currentResponse?.id)
        // - resonanceLevel
        // - userMemory text
        // - timestamp

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        isSubmitting = false
        dismiss()
        return true
    }
}

// MARK: - Memory Resonance Sheet

struct MemoryResonanceView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = MemoryResonanceViewModel()

    let response: StorySegmentData
    let onResponseShared: (() -> Void)?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // MARK: - Header
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: "hands.sparkles")
                            .font(.system(size: 32))
                            .foregroundColor(.pink)

                        Text("Did this memory resonate?")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(theme.textColor)

                        Text("Sometimes hearing a family story sparks a memory of your own. Sharing these connections weaves our family tapestry richer.")
                            .font(.system(size: 15))
                            .foregroundColor(theme.secondaryTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.bottom, 8)

                    // MARK: - Original Memory Context
                    VStack(alignment: .leading, spacing: 16) {
                        Text("You just heard:")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(theme.secondaryTextColor)

                        HStack(spacing: 12) {
                            // Storyteller avatar
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [response.storytellerColor, response.storytellerColor.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Text(String(response.fullName.prefix(1)))
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(response.fullName)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(theme.textColor)

                                Text(resonanceTimestamp(response.createdAt))
                                    .font(.caption)
                                    .foregroundColor(theme.secondaryTextColor)
                            }

                            Spacer()
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(theme.cardBackgroundColor)
                        )

                        // Transcription preview
                        if let transcription = response.transcriptionText {
                            Text(transcription)
                                .font(.system(size: 14))
                                .foregroundColor(theme.secondaryTextColor)
                                .lineLimit(3)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(theme.cardBackgroundColor)
                                )
                        }
                    }

                    // MARK: - Resonance Level Selector
                    VStack(alignment: .leading, spacing: 16) {
                        Text("How much does this resonate?")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(theme.secondaryTextColor)
                            
                        VStack(spacing: 12) {
                            ForEach([MemoryResonanceViewModel.ResonanceLevel.familiar,
                                    .connected,
                                    .deeplyMoved], id: \.self) { level in
                                ResonanceLevelButton(
                                    level: level,
                                    isSelected: viewModel.resonanceLevel == level,
                                    theme: theme
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        viewModel.resonanceLevel = level
                                    }
                                }
                            }

                            // No resonance option
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    viewModel.resonanceLevel = .none
                                }
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "circle")
                                        .font(.system(size: 20))
                                        .foregroundColor(viewModel.resonanceLevel == .none ? .gray : .gray.opacity(0.5))
                                        .frame(width: 28)

                                    Text("This doesn't resonate with me")
                                        .font(.system(size: 15))
                                        .foregroundColor(viewModel.resonanceLevel == .none ? theme.textColor : theme.secondaryTextColor)

                                    Spacer()

                                    if viewModel.resonanceLevel == .none {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(viewModel.resonanceLevel == .none ? Color.gray.opacity(0.1) : theme.cardBackgroundColor)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    // MARK: - Share Your Memory (conditional)
                    if viewModel.resonanceLevel != .none {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Share your connection")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(theme.secondaryTextColor)
                                
                            TextEditor(text: $viewModel.userMemory)
                                .font(.system(size: 15))
                                .foregroundColor(theme.textColor)
                                .padding(12)
                                .frame(minHeight: 100)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(theme.cardBackgroundColor)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(viewModel.resonanceLevel.color.opacity(0.3), lineWidth: 1)
                                )

                            if viewModel.userMemory.isEmpty {
                                Text(viewModel.resonanceLevel.placeholder)
                                    .font(.system(size: 14))
                                    .foregroundColor(theme.secondaryTextColor.opacity(0.6))
                                    .allowsHitTesting(false)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 24)
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // MARK: - Action Buttons
                    VStack(spacing: 12) {
                        if viewModel.resonanceLevel != .none {
                            Button(action: {
                                Task {
                                    _ = await viewModel.submitResonance()
                                    onResponseShared?()
                                }
                            }) {
                                HStack {
                                    if viewModel.isSubmitting {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.9)
                                    } else {
                                        Text("Share My Memory")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    Capsule()
                                        .fill(viewModel.resonanceLevel.color)
                                )
                                .foregroundColor(.white)
                            }
                            .disabled(viewModel.userMemory.isEmpty || viewModel.isSubmitting)
                            .opacity(viewModel.userMemory.isEmpty ? 0.5 : 1)
                        }

                        Button(action: {
                            dismiss()
                        }) {
                            Text(viewModel.resonanceLevel == .none ? "Maybe Later" : "Skip for Now")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(theme.secondaryTextColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                    }
                }
                .padding(20)
            }
            .background(theme.backgroundColor)
            .navigationTitle("Memory Resonance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        dismiss()
                    }
                    .foregroundColor(theme.secondaryTextColor)
                    .font(.system(size: 15))
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(viewModel.resonanceLevel != .none && !viewModel.userMemory.isEmpty)
    }

    private func resonanceTimestamp(_ isoDate: String) -> String {
        guard let date = ISO8601DateFormatter().date(from: isoDate) else {
            return "Recently"
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Resonance Level Button

struct ResonanceLevelButton: View {
    let level: MemoryResonanceViewModel.ResonanceLevel
    let isSelected: Bool
    let theme: PersonaTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(level.color.opacity(isSelected ? 0.2 : 0.1))
                        .frame(width: 40, height: 40)

                    Image(systemName: level.icon)
                        .font(.system(size: 18))
                        .foregroundColor(level.color.opacity(isSelected ? 1 : 0.6))
                }

                // Label
                VStack(alignment: .leading, spacing: 2) {
                    Text(level.displayName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(isSelected ? theme.textColor : theme.secondaryTextColor)

                    Text(levelDescription(for: level))
                        .font(.system(size: 12))
                        .foregroundColor(theme.secondaryTextColor)
                }

                Spacer()

                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(level.color)
                        .font(.system(size: 20))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? level.color.opacity(0.1) : theme.cardBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? level.color.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func levelDescription(for level: MemoryResonanceViewModel.ResonanceLevel) -> String {
        switch level {
        case .familiar: return "I've heard something like this before"
        case .connected: return "I have a similar memory"
        case .deeplyMoved: return "This touches my heart deeply"
        case .none: return ""
        }
    }
}

// MARK: - Gentle Resonance Invitation (mini prompt)

struct GentleResonanceInvitation: View {
    let response: StorySegmentData
    let onTap: () -> Void
    let theme: PersonaTheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Pulsing glow icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.pink.opacity(0.2), .purple.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)

                    Image(systemName: "hands.sparkles")
                        .font(.system(size: 18))
                        .foregroundColor(.pink)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Did this spark a memory?")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.textColor)

                    Text("Gently share what resonated")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.pink.opacity(0.6))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.cardBackgroundColor,
                                .pink.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [.pink.opacity(0.2), .purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

struct MemoryResonanceView_Previews: PreviewProvider {
    static var previews: some View {
        MemoryResonanceView(
            response: StorySegmentData(
                id: "1",
                userId: "user1",
                source: "preview",
                mediaUrl: nil,
                transcriptionText: "I remember the summer of 1965 when we all gathered at the lake house. The air smelled of pine needles and fresh water...",
                durationSeconds: 45,
                createdAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400 * 30)),
                fullName: "Grandma Rose",
                role: "elder",
                avatarUrl: nil,
                replyToResponseId: nil
            ),
            onResponseShared: nil
        )
        .themed(LightTheme())
        .previewDisplayName("Memory Resonance")

        GentleResonanceInvitation(
            response: StorySegmentData(
                id: "1",
                userId: "user1",
                source: "preview",
                mediaUrl: nil,
                transcriptionText: "I remember...",
                durationSeconds: 45,
                createdAt: ISO8601DateFormatter().string(from: Date()),
                fullName: "Grandma Rose",
                role: "elder",
                avatarUrl: nil,
                replyToResponseId: nil
            ),
            onTap: {},
            theme: LightTheme()
        )
        .padding()
        .previewDisplayName("Gentle Invitation")
    }
}
