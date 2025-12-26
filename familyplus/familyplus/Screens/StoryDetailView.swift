//
//  StoryDetailView.swift
//  StoryRide
//
//  Story Detail - Shared moment with multiplayer timeline
//

import SwiftUI

// MARK: - Audio Waveform Visualizer

struct AudioWaveformView: View {
    let isPlaying: Bool
    let color: Color
    let barCount: Int

    @State private var animationPhases: [Double] = []

    init(isPlaying: Bool, color: Color, barCount: Int = 40) {
        self.isPlaying = isPlaying
        self.color = color
        self.barCount = barCount
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<barCount, id: \.self) { index in
                WaveformBar(
                    isPlaying: isPlaying,
                    color: color,
                    phase: Double(index) / Double(barCount)
                )
            }
        }
    }
}

struct WaveformBar: View {
    let isPlaying: Bool
    let color: Color
    let phase: Double

    @State private var height: CGFloat = 0.3

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: 3, height: isPlaying ? height * 40 : 8)
            .animation(
                isPlaying ?
                    .easeInOut(duration: 0.3 + phase * 0.3)
                    .repeatForever(autoreverses: true)
                    .delay(phase * 0.1)
                : .easeOut(duration: 0.3),
                value: isPlaying
            )
            .onAppear {
                height = CGFloat.random(in: 0.3...1.0)
            }
            .onChange(of: isPlaying) { playing in
                if playing {
                    withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
                        height = CGFloat.random(in: 0.3...1.0)
                    }
                }
            }
    }
}

// MARK: - Mini Waveform (for timeline segments)

struct MiniWaveformView: View {
    let segment: StorySegment
    let isActive: Bool

    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<20, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(segment.color.opacity(isActive ? 1.0 : 0.6))
                    .frame(width: 2, height: CGFloat.random(in: 3...12))
            }
        }
    }
}

// MARK: - Story Segment (Multiplayer Voices)

struct StorySegment: Identifiable {
    let id = UUID()
    let storyteller: String
    let role: PersonaRole
    let text: String
    let audioURL: String?
    let duration: TimeInterval
    let startTime: TimeInterval

    var color: Color {
        switch role {
        case .elder:
            return .storytellerOrange
        case .parent:
            return .storytellerBlue
        case .teen:
            return .storytellerPurple
        case .child:
            return .storytellerGreen
        }
    }
}

// MARK: - Reaction

enum Reaction: String, CaseIterable {
    case heart = "❤️"
    case fire = "🔥"
    case clap = "👏"
    case laugh = "😂"
    case wow = "😮"

    var accessibilityLabel: String {
        switch self {
        case .heart: return "Heart"
        case .fire: return "Fire"
        case .clap: return "Clapping"
        case .laugh: return "Laughing"
        case .wow: return "Wow"
        }
    }
}

// MARK: - Story Detail View

struct StoryDetailView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    let story: Story
    @State private var segments: [StorySegment] = StorySegment.sampleSegments
    @State private var currentTime: TimeInterval = 0
    @State private var isPlaying = false
    @State private var selectedReaction: Reaction?
    @State private var showReactionPicker = false

    var totalDuration: TimeInterval {
        (segments.last?.startTime ?? 0) + (segments.last?.duration ?? 0)
    }

    var currentSegment: StorySegment? {
        segments.first { segment in
            currentTime >= segment.startTime &&
            currentTime < segment.startTime + segment.duration
        }
    }

    var body: some View {
        Group {
            switch theme.role {
            case .teen, .parent:
                FullStoryDetail(
                    story: story,
                    segments: segments,
                    currentTime: $currentTime,
                    isPlaying: $isPlaying,
                    selectedReaction: $selectedReaction,
                    showReactionPicker: $showReactionPicker,
                    currentSegment: currentSegment
                )
            case .child:
                ChildStoryDetail(
                    story: story,
                    segments: segments,
                    isPlaying: $isPlaying
                )
            case .elder:
                ElderStoryDetail(story: story)
            }
        }
    }
}

// MARK: - Full Story Detail (Teen/Parent)

struct FullStoryDetail: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    let story: Story
    let segments: [StorySegment]
    @Binding var currentTime: TimeInterval
    @Binding var isPlaying: Bool
    @Binding var selectedReaction: Reaction?
    @Binding var showReactionPicker: Bool
    let currentSegment: StorySegment?

    // MARK: - Multiplayer Perspectives State
    @State private var responses: [StorySegmentData] = []
    @State private var isLoadingResponses = false
    @State private var showAddPerspective = false
    @State private var replyingTo: StorySegmentData? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background extends edge-to-edge
            theme.backgroundColor.ignoresSafeArea()

            // SCROLLABLE content (hero + perspectives)
            ScrollView {
                VStack(spacing: 0) {
                    // Hero image with title overlay - extends to top edge
                    ZStack(alignment: .bottomLeading) {
                        // Background image/color
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        currentSegment?.color.opacity(0.4) ?? .gray.opacity(0.4),
                                        currentSegment?.color.opacity(0.6) ?? .gray.opacity(0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 300)
                            .ignoresSafeArea(edges: .top)

                        // Gradient overlay for text visibility
                        LinearGradient(
                            colors: [.clear, theme.backgroundColor.opacity(0.95)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 200)

                        // Title and info overlay
                        VStack(alignment: .leading, spacing: 12) {
                            Text(story.title)
                                .font(theme.headlineFont)
                                .foregroundColor(theme.textColor)
                                .lineLimit(3)
                                .shadow(color: .black.opacity(0.2), radius: 4)
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 30, trailing: 0))

                            HStack(spacing: 12) {
                                Circle()
                                    .fill(currentSegment?.color ?? story.storytellerColor)
                                    .frame(width: 12, height: 12)

                                Text(currentSegment?.storyteller ?? story.storyteller)
                                    .font(.subheadline)
                                    .foregroundColor(theme.secondaryTextColor)

                                if segments.count > 1 {
                                    Text("+ \(segments.count - 1) more")
                                        .font(.caption)
                                        .foregroundColor(theme.secondaryTextColor)
                                }
                            }
                        }
                        .padding(.horizontal, theme.screenPadding)
                        .padding(.bottom, 60)
                    }
                    .safeAreaPadding([.top, .bottom])

                    // Perspectives Section
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Perspectives")
                                    .font(theme.headlineFont)
                                    .foregroundColor(theme.textColor)

                                Spacer()

                                Text("\(responses.count) voices")
                                    .font(.caption)
                                    .foregroundColor(theme.secondaryTextColor)
                            }
                            .padding(.horizontal, 20)

                            if isLoadingResponses {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding(40)
                            } else if responses.isEmpty {
                                EmptyPerspectivesView {
                                    replyingTo = nil
                                    showAddPerspective = true
                                }
                            } else {
                                ChronologicalThreadedTimelineView(
                                    responses: responses,
                                    onReplyToResponse: { response in
                                        replyingTo = response
                                        showAddPerspective = true
                                    },
                                    onPlayResponse: { response in
                                        playResponse(response)
                                    }
                                )
                            }
                        }

                        // Add perspective button
                        Button(action: {
                            replyingTo = nil
                            showAddPerspective = true
                        }) {
                            HStack {
                                Image(systemName: "plus.bubble")
                                Text("Add Your Perspective")
                            }
                            .font(.headline)
                            .foregroundColor(theme.accentColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: theme.buttonHeight)
                            .background(
                                RoundedRectangle(cornerRadius: theme.cardRadius)
                                    .strokeBorder(theme.accentColor, lineWidth: 2)
                            )
                        }

                        // Extra padding at bottom so content doesn't get hidden by player
                        Color.clear.frame(height: 140)
                    }
                    .padding(theme.screenPadding)
                }
            }

            // STICKY Player controls - fixed at bottom of screen
            VStack(spacing: 0) {
                StoryPlayerControls(
                    segments: segments,
                    currentTime: $currentTime,
                    isPlaying: $isPlaying,
                    showReactionPicker: $showReactionPicker
                )
                .padding(.horizontal)
                .padding(.top)
                .padding(.bottom, 12)
                .background(
                    theme.backgroundColor
                        .shadow(color: .black.opacity(0.15), radius: 12, y: -4)
                        .ignoresSafeArea(edges: .bottom)
                )
            }

            // Sticky gradient overlay at top (stays visible during scroll)
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [
                        currentSegment?.color.opacity(0.3) ?? .gray.opacity(0.3),
                        currentSegment?.color.opacity(0.15) ?? .gray.opacity(0.15),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 150)
                .ignoresSafeArea(edges: .top)

                Spacer()
            }

            // Custom back button (below status bar in safe area)
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 44, height: 44)

                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 50)

                Spacer()
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(.all, edges: .top)
        .sheet(isPresented: $showReactionPicker) {
            ReactionPickerView(selectedReaction: $selectedReaction)
                .presentationDetents([.height(200)])
        }
        .sheet(isPresented: $showAddPerspective) {
            AddPerspectiveView(
                story: StoryData(
                    id: story.id.uuidString,
                    promptId: nil,
                    familyId: "family-123",  // TODO: Get from actual family context
                    title: story.title,
                    summaryText: nil,
                    coverImageUrl: nil,
                    voiceCount: story.voiceCount,
                    isCompleted: false,
                    createdAt: ISO8601DateFormatter().string(from: Date()),
                    promptText: story.title,
                    promptCategory: nil
                ),
                replyingTo: replyingTo
            )
        }
        .onAppear {
            loadResponses()
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Multiplayer Perspectives Functions

    // Backend API Integration Points:
    //
    // 1. GET /api/stories/{storyId}/detail
    //    Response: { story: {...}, responses: [StorySegmentData] }
    //    Used in: loadResponses()
    //
    // 2. POST /api/stories/{storyId}/responses
    //    Body: { mediaUrl, durationSeconds, replyToResponseId }
    //    Used in: AddPerspectiveView after upload
    //    Returns: New StorySegmentData with threading link
    //
    // 3. Real-time updates (future):
    //    WebSocket connection for live perspective additions

    private func loadResponses() {
        isLoadingResponses = true

        Task {
            do {
                // TODO: Replace with actual API call when backend ready
                // let detail = try await APIService.shared.getStoryDetail(storyId: story.id)
                // responses = detail.responses

                let mockResponses = createMockResponses()

                await MainActor.run {
                    responses = mockResponses
                    isLoadingResponses = false
                }
            } catch {
                print("Failed to load responses: \(error)")
                await MainActor.run {
                    isLoadingResponses = false
                }
            }
        }
    }

    private func createMockResponses() -> [StorySegmentData] {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let baseTime = Date()
        let now = formatter.string(from: baseTime)
        let min5Ago = formatter.string(from: baseTime.addingTimeInterval(-300))
        let min10Ago = formatter.string(from: baseTime.addingTimeInterval(-600))
        let min20Ago = formatter.string(from: baseTime.addingTimeInterval(-1200))
        let hour1Ago = formatter.string(from: baseTime.addingTimeInterval(-3600))
        let hour3Ago = formatter.string(from: baseTime.addingTimeInterval(-10800))
        let hour6Ago = formatter.string(from: baseTime.addingTimeInterval(-21600))
        let oneDayAgo = formatter.string(from: baseTime.addingTimeInterval(-86400))
        let twoDaysAgo = formatter.string(from: baseTime.addingTimeInterval(-172800))

        return [
            // ROOT: Grandma starts the story
            StorySegmentData(
                id: "resp-1",
                userId: "user-1",
                source: "app",
                mediaUrl: "https://example.com/audio1.m4a",
                transcriptionText: "In the summer of '68, your grandfather and I drove across the country in our old Chevy. We were so young and full of dreams. The whole trip was an adventure!",
                durationSeconds: 45,
                createdAt: twoDaysAgo,
                fullName: "Grandma Rose",
                role: "elder",
                avatarUrl: nil,
                replyToResponseId: nil
            ),

            // THREAD 1: Mom's memory
            StorySegmentData(
                id: "resp-2",
                userId: "user-2",
                source: "app",
                mediaUrl: "https://example.com/audio2.m4a",
                transcriptionText: "Mom, I remember you telling me about the flat tire in Nevada! Didn't you say it was actually a Ford, not a Chevy?",
                durationSeconds: 30,
                createdAt: oneDayAgo,
                fullName: "Mom",
                role: "parent",
                avatarUrl: nil,
                replyToResponseId: "resp-1"
            ),

            // THREAD 1.1: Grandma clarifies
            StorySegmentData(
                id: "resp-3",
                userId: "user-1",
                source: "app",
                mediaUrl: "https://example.com/audio3.m4a",
                transcriptionText: "You're absolutely right dear! It was a '65 Ford Mustang. My memory isn't what it used to be!",
                durationSeconds: 22,
                createdAt: hour6Ago,
                fullName: "Grandma Rose",
                role: "elder",
                avatarUrl: nil,
                replyToResponseId: "resp-2"
            ),

            // THREAD 1.1.1: Leo chimes in (max depth)
            StorySegmentData(
                id: "resp-4",
                userId: "user-4",
                source: "app",
                mediaUrl: "https://example.com/audio4.m4a",
                transcriptionText: "A '65 Mustang?! That's such a cool car! I wish we still had it.",
                durationSeconds: 18,
                createdAt: hour3Ago,
                fullName: "Leo",
                role: "teen",
                avatarUrl: nil,
                replyToResponseId: "resp-3"
            ),

            // THREAD 2: Uncle Joe's separate memory
            StorySegmentData(
                id: "resp-5",
                userId: "user-3",
                source: "app",
                mediaUrl: "https://example.com/audio5.m4a",
                transcriptionText: "I remember Dad telling me about that trip! He said you guys slept under the stars in Arizona.",
                durationSeconds: 28,
                createdAt: hour1Ago,
                fullName: "Uncle Joe",
                role: "parent",
                avatarUrl: nil,
                replyToResponseId: "resp-1"
            ),

            // THREAD 2.1: Grandma confirms
            StorySegmentData(
                id: "resp-6",
                userId: "user-1",
                source: "app",
                mediaUrl: "https://example.com/audio6.m4a",
                transcriptionText: "Yes! The Grand Canyon at sunset was breathtaking. We didn't have much money for hotels, so we made it an adventure.",
                durationSeconds: 35,
                createdAt: min20Ago,
                fullName: "Grandma Rose",
                role: "elder",
                avatarUrl: nil,
                replyToResponseId: "resp-5"
            ),

            // THREAD 2.2: Dad adds his perspective
            StorySegmentData(
                id: "resp-7",
                userId: "user-5",
                source: "app",
                mediaUrl: "https://example.com/audio7.m4a",
                transcriptionText: "Dad used to show me photos from that trip. He always had the biggest smile when he talked about it.",
                durationSeconds: 26,
                createdAt: min10Ago,
                fullName: "Dad",
                role: "parent",
                avatarUrl: nil,
                replyToResponseId: "resp-5"
            ),

            // THREAD 3: Sophie (child) asks a question
            StorySegmentData(
                id: "resp-8",
                userId: "user-6",
                source: "app",
                mediaUrl: "https://example.com/audio8.m4a",
                transcriptionText: "Grandma! Did you take pictures? I wanna see!",
                durationSeconds: 15,
                createdAt: min5Ago,
                fullName: "Sophie",
                role: "child",
                avatarUrl: nil,
                replyToResponseId: "resp-1"
            ),

            // THREAD 3.1: Mom responds to Sophie
            StorySegmentData(
                id: "resp-9",
                userId: "user-2",
                source: "app",
                mediaUrl: "https://example.com/audio9.m4a",
                transcriptionText: "We have an old photo album in the attic! Let's look at it together this weekend.",
                durationSeconds: 20,
                createdAt: now,
                fullName: "Mom",
                role: "parent",
                avatarUrl: nil,
                replyToResponseId: "resp-8"
            )
        ]
    }

    private func playResponse(_ response: StorySegmentData) {
        guard let audioURL = response.mediaUrl,
              let url = URL(string: audioURL) else {
            print("⚠️ Invalid audio URL for response: \(response.id)")
            return
        }

        // Play in main bottom player
        isPlaying = true
        print("🎵 Playing response: \(response.fullName) - \(response.transcriptionText ?? "")")
    }
}

// MARK: - Playback Speed

enum PlaybackSpeed: Double, CaseIterable {
    case slow = 0.5
    case normal = 1.0
    case fast = 1.5
    case faster = 2.0

    var label: String {
        switch self {
        case .slow: return "0.5×"
        case .normal: return "1×"
        case .fast: return "1.5×"
        case .faster: return "2×"
        }
    }

    var next: PlaybackSpeed {
        switch self {
        case .slow: return .normal
        case .normal: return .fast
        case .fast: return .faster
        case .faster: return .slow
        }
    }
}

// MARK: - Story Player Controls

struct StoryPlayerControls: View {
    @Environment(\.theme) var theme
    let segments: [StorySegment]
    @Binding var currentTime: TimeInterval
    @Binding var isPlaying: Bool
    @Binding var showReactionPicker: Bool

    @State private var playbackSpeed: PlaybackSpeed = .normal
    @State private var isDragging = false
    @GestureState private var dragOffset: CGFloat = 0

    var totalDuration: TimeInterval {
        let last = segments.last
        let start = last?.startTime ?? 0
        let duration = last?.duration ?? 0
        return max(start + duration, 1) // Prevent division by zero
    }

    var currentSegment: StorySegment? {
        segments.first { segment in
            currentTime >= segment.startTime &&
            currentTime < segment.startTime + segment.duration
        }
    }

    // Format time as M:SS
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Current speaker indicator + duration + speed (compact inline layout)
            if let segment = currentSegment {
                HStack(spacing: 8) {
                    Circle()
                        .fill(segment.color)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(segment.color.opacity(0.5), lineWidth: 2)
                                .scaleEffect(isPlaying ? 1.5 : 1.0)
                                .opacity(isPlaying ? 0 : 1)
                                .animation(
                                    isPlaying ? .easeOut(duration: 1).repeatForever(autoreverses: false) : .default,
                                    value: isPlaying
                                )
                        )

                    Text(segment.storyteller)
                        .font(.caption)
                        .foregroundColor(segment.color)
                        .lineLimit(1)

                    Spacer()

                    // Duration
                    Text(formatTime(totalDuration))
                        .font(.caption.monospacedDigit())
                        .foregroundColor(theme.secondaryTextColor)

                    // Speed button
                    Button(action: { playbackSpeed = playbackSpeed.next }) {
                        Text(playbackSpeed.label)
                            .font(.caption.bold())
                            .foregroundColor(theme.secondaryTextColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.gray.opacity(0.2))
                            )
                    }
                    .accessibilityLabel("Playback speed \(playbackSpeed.label)")
                }
                .padding(.horizontal, 4)
            }

            // Timeline with inline current time (compact layout)
            HStack(spacing: 8) {
                // Current time
                Text(formatTime(currentTime))
                    .font(.caption.monospacedDigit())
                    .foregroundColor(theme.secondaryTextColor)
                    .frame(width: 40, alignment: .trailing)

                // Timeline with segments (scrubbable)
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track (reduced height)
                        Capsule()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 6)

                        // Segments (reduced height)
                        ForEach(segments) { segment in
                            let startX = geometry.size.width * (segment.startTime / totalDuration)
                            let width = geometry.size.width * (segment.duration / totalDuration)

                            Capsule()
                                .fill(segment.color)
                                .frame(width: max(width, 4), height: 6)
                                .offset(x: startX)
                        }

                        // Playhead (reduced size)
                        Circle()
                            .fill(.white)
                            .frame(width: isDragging ? 16 : 14, height: isDragging ? 16 : 14)
                            .shadow(color: .black.opacity(0.3), radius: 4)
                            .overlay(
                                Circle()
                                    .stroke(theme.accentColor, lineWidth: isDragging ? 3 : 0)
                            )
                            .offset(x: geometry.size.width * (currentTime / totalDuration) - (isDragging ? 8 : 7))
                            .animation(.spring(response: 0.3), value: isDragging)
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                isDragging = true
                                let percentage = max(0, min(1, value.location.x / geometry.size.width))
                                currentTime = percentage * totalDuration
                            }
                            .onEnded { _ in
                                isDragging = false
                            }
                    )
                }
                .frame(height: 16)
                .accessibilityLabel("Story timeline")
                .accessibilityValue("\(formatTime(currentTime)) of \(formatTime(totalDuration))")
            }

            // Controls (compact layout with reduced spacing and sizes)
            HStack(spacing: 16) {
                // Reaction button
                Button(action: { showReactionPicker = true }) {
                    Image(systemName: "face.smiling")
                        .font(.title3)
                        .foregroundColor(theme.textColor)
                }
                .accessibilityLabel("Add reaction")

                Spacer()

                // Skip backward 15s
                Button(action: {
                    currentTime = max(0, currentTime - 15)
                }) {
                    Image(systemName: "gobackward.15")
                        .font(.title3)
                        .foregroundColor(theme.textColor)
                }
                .accessibilityLabel("Skip back 15 seconds")

                // Play/Pause (reduced size)
                Button(action: { isPlaying.toggle() }) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(theme.accentColor)
                }
                .accessibilityLabel(isPlaying ? "Pause" : "Play")

                // Skip forward 15s
                Button(action: {
                    currentTime = min(totalDuration, currentTime + 15)
                }) {
                    Image(systemName: "goforward.15")
                        .font(.title3)
                        .foregroundColor(theme.textColor)
                }
                .accessibilityLabel("Skip forward 15 seconds")

                Spacer()

                // Share button
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                        .foregroundColor(theme.textColor)
                }
                .accessibilityLabel("Share story")
            }
        }
    }
}

// MARK: - Child Story Detail (Audio-First)

struct ChildStoryDetail: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    let story: Story
    let segments: [StorySegment]
    @Binding var isPlaying: Bool

    @State private var currentSegmentIndex: Int = 0
    @State private var showConfetti = false

    var currentSegment: StorySegment? {
        guard currentSegmentIndex < segments.count else { return nil }
        return segments[currentSegmentIndex]
    }

    var body: some View {
        ZStack {
            // Background gradient based on current speaker
            LinearGradient(
                colors: [
                    (currentSegment?.color ?? theme.accentColor).opacity(0.1),
                    theme.backgroundColor
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                // Back button
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 56))
                            .foregroundColor(theme.accentColor)
                    }
                    .accessibilityLabel("Go back")

                    Spacer()

                    // Voice count badge
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.title3)
                        Text("\(segments.count)")
                            .font(.title2.bold())
                    }
                    .foregroundColor(theme.accentColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(theme.accentColor.opacity(0.15))
                    )
                }
                .padding(.horizontal, theme.screenPadding)

                Spacer()

                // Large animated story image
                ZStack {
                    // Background glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    (currentSegment?.color ?? story.storytellerColor).opacity(0.4),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 50,
                                endRadius: 150
                            )
                        )
                        .frame(width: 280, height: 280)
                        .scaleEffect(isPlaying ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isPlaying)

                    // Story image placeholder
                    RoundedRectangle(cornerRadius: 40)
                        .fill(
                            LinearGradient(
                                colors: [
                                    currentSegment?.color ?? story.storytellerColor,
                                    (currentSegment?.color ?? story.storytellerColor).opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 220, height: 220)
                        .shadow(color: (currentSegment?.color ?? story.storytellerColor).opacity(0.5), radius: 30)
                        .overlay(
                            // Waveform inside
                            AudioWaveformView(
                                isPlaying: isPlaying,
                                color: .white.opacity(0.9),
                                barCount: 30
                            )
                            .frame(height: 60)
                        )
                }

                // Current speaker
                if let segment = currentSegment {
                    VStack(spacing: 8) {
                        Text(segment.storyteller)
                            .font(.title.bold())
                            .foregroundColor(segment.color)

                        Text("is telling the story")
                            .font(theme.bodyFont)
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }

                // Title
                Text(story.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, theme.screenPadding)

                Spacer()

                // Navigation between segments (for kids to tap through)
                HStack(spacing: 16) {
                    // Previous speaker
                    Button(action: {
                        if currentSegmentIndex > 0 {
                            currentSegmentIndex -= 1
                        }
                    }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(currentSegmentIndex > 0 ? theme.textColor : .gray.opacity(0.3))
                    }
                    .disabled(currentSegmentIndex == 0)
                    .accessibilityLabel("Previous speaker")

                    // Giant play button
                    Button(action: {
                        isPlaying.toggle()
                    }) {
                        ZStack {
                            // Outer ring pulse
                            Circle()
                                .stroke(theme.accentColor.opacity(0.3), lineWidth: 4)
                                .frame(width: 140, height: 140)
                                .scaleEffect(isPlaying ? 1.2 : 1.0)
                                .opacity(isPlaying ? 0 : 1)
                                .animation(.easeOut(duration: 1).repeatForever(autoreverses: false), value: isPlaying)

                            Circle()
                                .fill(theme.accentColor)
                                .frame(width: 120, height: 120)
                                .shadow(color: theme.accentColor.opacity(0.5), radius: isPlaying ? 30 : 15)

                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.white)
                                .offset(x: isPlaying ? 0 : 4) // Optical center for play icon
                        }
                    }
                    .accessibilityLabel(isPlaying ? "Pause story" : "Play story")

                    // Next speaker
                    Button(action: {
                        if currentSegmentIndex < segments.count - 1 {
                            currentSegmentIndex += 1
                        }
                    }) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(currentSegmentIndex < segments.count - 1 ? theme.textColor : .gray.opacity(0.3))
                    }
                    .disabled(currentSegmentIndex >= segments.count - 1)
                    .accessibilityLabel("Next speaker")
                }

                // Speaker dots
                HStack(spacing: 12) {
                    ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                        Circle()
                            .fill(index == currentSegmentIndex ? segment.color : segment.color.opacity(0.3))
                            .frame(width: index == currentSegmentIndex ? 16 : 10, height: index == currentSegmentIndex ? 16 : 10)
                            .animation(.spring(response: 0.3), value: currentSegmentIndex)
                    }
                }
                .padding(.bottom, 40)
            }
            .safeAreaPadding([.top, .bottom])
        }
    }
}

// MARK: - Elder Story Detail

struct ElderStoryDetail: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    let story: Story

    @State private var isPlaying = false

    var body: some View {
        ZStack {
            // Warm background
            theme.backgroundColor.ignoresSafeArea()

            VStack(spacing: 32) {
                // Large back button
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.left.circle.fill")
                                .font(.system(size: 40))
                            Text("Back")
                                .font(.title2.bold())
                        }
                        .foregroundColor(theme.accentColor)
                    }
                    .accessibilityLabel("Go back")

                    Spacer()
                }
                .padding(.horizontal, theme.screenPadding)

                Spacer()

                // Simple waveform visualization
                ZStack {
                    // Soft glow background
                    Circle()
                        .fill(theme.accentColor.opacity(0.1))
                        .frame(width: 200, height: 200)

                    // Waveform
                    AudioWaveformView(
                        isPlaying: isPlaying,
                        color: theme.accentColor,
                        barCount: 25
                    )
                    .frame(width: 160, height: 80)
                }

                // Story info - large and clear
                VStack(spacing: 20) {
                    Text(story.title)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(theme.textColor)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)

                    // Storyteller
                    HStack(spacing: 12) {
                        Circle()
                            .fill(story.storytellerColor)
                            .frame(width: 16, height: 16)

                        Text("By \(story.storyteller)")
                            .font(.title3)
                            .foregroundColor(theme.secondaryTextColor)
                    }

                    // Duration indicator
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                        Text("\(story.voiceCount) voices • 2 minutes")
                    }
                    .font(.title3)
                    .foregroundColor(theme.secondaryTextColor)
                }
                .padding(.horizontal, theme.screenPadding)
                .safeAreaPadding(.top)

                Spacer()

                // Simple play/pause - ONE button, very large
                VStack(spacing: 20) {
                    Button(action: { isPlaying.toggle() }) {
                        HStack(spacing: 16) {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 32))

                            Text(isPlaying ? "Pause" : "Listen Now")
                                .font(.title.bold())
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                        .background(theme.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: theme.accentColor.opacity(0.3), radius: 10)
                    }
                    .accessibilityLabel(isPlaying ? "Pause the story" : "Listen to this story")

                    // Status text
                    if isPlaying {
                        Text("Playing... Tap to pause")
                            .font(.title3)
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }
                .padding(.horizontal, theme.screenPadding)
                .padding(.bottom, 60)
                .safeAreaPadding(.bottom)
            }
        }
    }
}

// MARK: - Reaction Picker

struct ReactionPickerView: View {
    @Binding var selectedReaction: Reaction?
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 24) {
            Text("React to this story")
                .font(.headline)
                .padding(.top)

            HStack(spacing: 20) {
                ForEach(Reaction.allCases, id: \.self) { reaction in
                    Button(action: {
                        selectedReaction = reaction
                        dismiss()
                    }) {
                        Text(reaction.rawValue)
                            .font(.system(size: 48))
                    }
                    .accessibilityLabel(reaction.accessibilityLabel)
                }
            }
            .padding()

            Spacer()
        }
    }
}

// MARK: - Sample Data

extension StorySegment {
    static let sampleSegments: [StorySegment] = [
        StorySegment(
            storyteller: "Grandma Rose",
            role: .elder,
            text: "In the summer of 1968, your grandfather and I drove across the country in our Chevy. We were so young and full of dreams.",
            audioURL: nil,
            duration: 15,
            startTime: 0
        ),
        StorySegment(
            storyteller: "Dad",
            role: .parent,
            text: "Actually Mom, I remember you saying it was a Ford, not a Chevy. And you had a flat tire in Nevada!",
            audioURL: nil,
            duration: 10,
            startTime: 15
        ),
        StorySegment(
            storyteller: "Leo",
            role: .teen,
            text: "That's so cool! I can't believe you drove all that way without GPS.",
            audioURL: nil,
            duration: 8,
            startTime: 25
        )
    ]
}

// MARK: - Empty Perspectives View

struct EmptyPerspectivesView: View {
    @Environment(\.theme) var theme
    let onAddFirst: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(theme.secondaryTextColor.opacity(0.3))

            Text("No perspectives yet")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(theme.textColor)

            Text("Be the first to share your story!")
                .font(.subheadline)
                .foregroundColor(theme.secondaryTextColor)

            Button(action: onAddFirst) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add First Perspective")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(theme.accentColor)
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}

// MARK: - Preview

struct StoryDetailView_Previews: PreviewProvider {
    static let sampleStory = Story.sampleStories[0]

    static var previews: some View {
        Group {
            StoryDetailView(story: sampleStory)
                .themed(TeenTheme())
                .previewDisplayName("Teen Detail")

            StoryDetailView(story: sampleStory)
                .themed(ParentTheme())
                .previewDisplayName("Parent Detail")

            StoryDetailView(story: sampleStory)
                .themed(ChildTheme())
                .previewDisplayName("Child Detail")

            StoryDetailView(story: sampleStory)
                .themed(ElderTheme())
                .previewDisplayName("Elder Detail")
        }
    }
}
