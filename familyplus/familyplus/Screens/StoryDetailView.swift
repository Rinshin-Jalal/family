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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: 3, height: isPlaying ? height * 40 : 8)
            .animation(
                isPlaying ?
                    (reduceMotion ? .none : .easeInOut(duration: 0.25)
                        .repeatForever(autoreverses: true)
                        .delay(phase * 0.05))
                : .easeOut(duration: 0.25),
                value: isPlaying
            )
            .onAppear {
                height = CGFloat.random(in: 0.3...1.0)
            }
            .onChange(of: isPlaying) { playing in
                if playing {
                    withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.25).repeatForever(autoreverses: true)) {
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
    let color: Color  // Direct color instead of PersonaRole
    let text: String
    let audioURL: String?
    let duration: TimeInterval
    let startTime: TimeInterval
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

// MARK: - Reaction Picker Sheet

struct ReactionPickerSheet: View {
    @Environment(\.theme) var theme
    @Binding var selectedReaction: Reaction?
    let onReactionSelected: (Reaction) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Reaction")
                .font(.headline)

            HStack(spacing: 20) {
                ForEach(Reaction.allCases, id: \.self) { reaction in
                    Button(action: { onReactionSelected(reaction) }) {
                        Text(reaction.rawValue)
                            .font(.system(size: 40))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(reaction.accessibilityLabel)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Story Detail View

struct StoryDetailView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    let story: Story
    @State private var segments: [StorySegment] = []
    @State private var currentTime: TimeInterval = 0
    @State private var isPlaying = false
    // selectedReaction REMOVED - social feature de-emphasized

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
        // Unified story detail for both dark and light themes
        FullStoryDetail(
            story: story,
            segments: segments,
            currentTime: $currentTime,
            isPlaying: $isPlaying,
            currentSegment: currentSegment
        )
    }
}

// MARK: - Full Story Detail (dark/light)

struct FullStoryDetail: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let story: Story
    let segments: [StorySegment]
    @Binding var currentTime: TimeInterval
    @Binding var isPlaying: Bool
    // selectedReaction binding REMOVED - social feature de-emphasized
    let currentSegment: StorySegment?

    // MARK: - Audio Services
    @ObservedObject private var audioPlayer = AudioPlayerService.shared
    @StateObject private var audioRecorder = AudioRecorderService()

    // MARK: - Multiplayer Perspectives State
    @State private var responses: [StorySegmentData] = []
    @State private var isLoadingResponses = false
    @State private var replyingTo: StorySegmentData? = nil
    @State private var storyPromptText: String? = nil  // Store the story's prompt

    // MARK: - Podcast Generation State
    @State private var isGeneratingPodcast = false
    @State private var showPodcastAlert = false
    @State private var podcastAlertMessage = ""

    // MARK: - Story Quotes State
    @State private var storyQuotes: [QuoteCardData] = []
    @State private var isLoadingQuotes = false

    // Memory context panel state
    @State private var showMemoryContext = false
    @State private var contextForResponse: StorySegmentData?

    // Capture memory modal state
    @State private var showCaptureSheet = false
    @State private var captureInitialMode: InputMode = .recording

    // REACTION STATE REMOVED - social feature de-emphasized
    // showReactionPicker REMOVED

    // Check if there's any audio content to play
    private var hasAudioContent: Bool {
        responses.contains { $0.hasAudio }
    }

    // MARK: - Haptic Feedback Helper
    private func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        if theme.enableHaptics {
            let impact = UIImpactFeedbackGenerator(style: style)
            impact.impactOccurred()
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background extends edge-to-edge
            theme.backgroundColor.ignoresSafeArea()

            // SCROLLABLE content (hero + perspectives) - with pull-to-refresh
            ScrollView {
                VStack(spacing: 0) {
                    // Story Prompt Header - Clean and Simple
                    VStack(alignment: .leading, spacing: 16) {
                        // Story prompt (main focus)
                        if let promptText = storyPromptText {
                            Text(promptText)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(theme.textColor)
                                .lineLimit(4)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            Text(story.title)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(theme.textColor)
                                .lineLimit(3)
                        }
                        
                        // Voice count badge
                        HStack(spacing: 8) {
                            Image(systemName: "person.2.fill")
                                .font(.caption)
                            Text("\(responses.count) \(responses.count == 1 ? "perspective" : "perspectives")")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(theme.secondaryTextColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(theme.secondaryTextColor.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, theme.screenPadding)
                    .padding(.top, 80)  // Space for back button
                    .padding(.bottom, 24)

                    // Perspectives Section
                    VStack(alignment: .leading, spacing: 24) {
                        // MARK: - Compact Story Metadata
                        VStack(alignment: .leading, spacing: 16) {
                            // Category + Stats in one compact row
                            HStack(spacing: 12) {
                                // Category badge
                                HStack(spacing: 6) {
                                    Image(systemName: PromptCategory.story.icon)
                                        .font(.caption)
                                    Text(PromptCategory.story.rawValue)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(PromptCategory.story.color.opacity(0.9))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .glassEffect(.regular.tint(PromptCategory.story.color.opacity(0.12)))

                                // Voice count
                                HStack(spacing: 4) {
                                    Image(systemName: "person.2.fill")
                                        .font(.caption)
                                    Text("\(responses.count)")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(theme.secondaryTextColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .glassEffect(.regular.tint(theme.secondaryTextColor.opacity(0.12)))

                                // Listened count (mock for now)
                                if !responses.isEmpty {
                                    HStack(spacing: 4) {
                                        Image(systemName: "headphones")
                                            .font(.caption)
                                        Text("\(Int.random(in: 10...99))")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(theme.secondaryTextColor)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .glassEffect(.clear.tint(theme.secondaryTextColor.opacity(0.12)))
                                    
                                }

                                Spacer()
                            }
                            .padding(.horizontal, 20)

                            // Perspectives header
                            CozySectionHeader(icon: "person.2.fill", title: "Perspectives")

                            if isLoadingResponses {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding(40)
                            } else if responses.isEmpty {
                                EmptyPerspectivesView {
                                    replyingTo = nil
                                }
                            } else {
                                ChronologicalThreadedTimelineView(
                                    responses: responses,
                                    onReplyToResponse: { response in
                                        replyingTo = response
                                        // Open capture sheet for reply
                                        captureInitialMode = .recording
                                        showCaptureSheet = true
                                    },
                                    onPlayResponse: { response in
                                        playResponse(response)
                                    },
                                    onShowMemoryContext: { response in
                                        contextForResponse = response
                                        showMemoryContext = true
                                    }
                                )
                            }
                        }
                        
                        Button(action: {
                            captureInitialMode = .recording
                            showCaptureSheet = true
                        }) {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [theme.accentColor, theme.accentColor.opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 48, height: 48)

                                    Image(systemName: "mic.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Add Your Perspective")
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.white)

                                    Text("Record or write your story")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.8))
                                }

                                Spacer()

                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .padding(16)
                            .background(
                                LinearGradient(
                                    colors: [theme.accentColor, theme.accentColor.opacity(0.85)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(20)
                            .shadow(color: theme.accentColor.opacity(0.3), radius: 8, y: 4)
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 8)

                        if !responses.isEmpty {
                            Button(action: {
                                generatePodcast()
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: isGeneratingPodcast ? "waveform.circle" : "waveform.circle")
                                        .font(.system(size: 18))
                                        .foregroundColor(theme.secondaryTextColor)

                                    Text(isGeneratingPodcast ? "Generating..." : "Generate Podcast")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(theme.secondaryTextColor)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(theme.secondaryTextColor.opacity(0.6))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(theme.secondaryTextColor.opacity(0.2), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.vertical, 4)
                        }

                        // Story Quotes Section
                        if !storyQuotes.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    Image(systemName: "quote.bubble.fill")
                                        .font(.caption)
                                        .foregroundColor(theme.accentColor)
                                    Text("Family Wisdom")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(theme.secondaryTextColor)
                                }

                                VStack(alignment: .leading, spacing: 16) {
                                    ForEach(storyQuotes.prefix(3)) { quote in
                                        StoryQuoteItem(
                                            quoteText: quote.quoteText,
                                            authorName: quote.authorName,
                                            authorRole: quote.authorRole
                                        )

                                        if quote.id != storyQuotes.prefix(3).last?.id {
                                            Divider()
                                        }
                                    }
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(theme.cardBackgroundColor)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(theme.accentColor.opacity(0.1), lineWidth: 1)
                                        )
                                )
                            }
                            .padding(.vertical, 8)
                        }

                        // Reply indicator (shows when replying to someone)
                        if let replyTo = replyingTo {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrowshape.turn.up.left.fill")
                                            .font(.caption2)
                                        Text("Replying to \(replyTo.fullName)")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(theme.accentColor)
                                    
                                    if let text = replyTo.transcriptionText {
                                        Text(text)
                                            .font(.caption2)
                                            .foregroundColor(theme.secondaryTextColor)
                                            .lineLimit(1)
                                    }
                                }
                                
                                Spacer()
                                
                                Button(action: { replyingTo = nil }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(theme.secondaryTextColor)
                                }
                            }
                            .padding(12)
                            .background(theme.accentColor.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal, theme.screenPadding)
                        }

                        Color.clear.frame(height: 140)
                    }
                    .padding(theme.screenPadding)
                }
            }
            .refreshable {
                await refreshStoryData()
            }

            // STICKY Player controls - fixed at bottom of screen (only show if there's audio)
            if hasAudioContent {
                VStack(spacing: 0) {
                    StoryPlayerControls(
                        segments: segments,
                        currentTime: $currentTime,
                        isPlaying: $isPlaying
                        // selectedReaction REMOVED - social feature de-emphasized
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
                    Button(action: {
                        if theme.enableHaptics {
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                        }
                        dismiss()
                    }) {
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
        .sheet(isPresented: $showMemoryContext) {
            if let response = contextForResponse {
                MemoryContextPanel(
                    context: generateMemoryContext(for: response, allResponses: responses)
                )
            }
        }
        .sheet(isPresented: $showCaptureSheet) {
            CaptureMemorySheet(
                initialPromptText: storyPromptText,  // Pass the story's prompt text directly
                initialMode: captureInitialMode,
                storyId: UUID(uuidString: story.id),
                replyToResponseId: replyingTo?.id,
                replyToName: replyingTo?.fullName,
                replyToText: replyingTo?.transcriptionText,
                hidePromptSection: replyingTo != nil  // Hide prompt when replying
            )
            .onDisappear {
                // Refresh responses after capture
                loadResponses()
                // Clear reply state
                replyingTo = nil
            }
        }
        .alert("Podcast Generation", isPresented: $showPodcastAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(podcastAlertMessage)
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
    //    Returns: New StorySegmentData with threading link
    //
    // 3. Real-time updates (future):
    //    WebSocket connection for live perspective additions

    private func loadResponses() {
        isLoadingResponses = true

        Task {
            await fetchResponses()
            await fetchQuotes()
        }
    }

    /// Refreshes story data when user pulls to refresh
    @MainActor
    private func refreshStoryData() async {
        // Haptic feedback for refresh start
        if theme.enableHaptics {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }

        await fetchResponses()
        await fetchQuotes()

        // Haptic feedback for refresh complete
        if theme.enableHaptics {
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
        }
    }

    /// Fetches responses from the API
    @MainActor
    private func fetchResponses() async {
        do {
            // Convert string ID to UUID for API call
            guard let storyUUID = UUID(uuidString: story.id) else {
                print("Invalid story ID: \(story.id)")
                isLoadingResponses = false
                return
            }

            // Fetch story details using the story ID
            let storyDetail = try await APIService.shared.getStory(id: storyUUID)

            self.responses = storyDetail.responses
            self.storyPromptText = storyDetail.story.promptText  // Store prompt text
            isLoadingResponses = false
        } catch {
            print("Failed to load responses: \(error)")
            isLoadingResponses = false
        }
    }

    /// Fetches quotes from the API
    @MainActor
    private func fetchQuotes() async {
        isLoadingQuotes = true

        do {
            guard let storyUUID = UUID(uuidString: story.id) else {
                print("Invalid story ID: \(story.id)")
                isLoadingQuotes = false
                return
            }

            let quotesResponse = try await APIService.shared.getStoryQuotes(storyId: storyUUID)
            self.storyQuotes = quotesResponse.quotes
            isLoadingQuotes = false
        } catch {
            print("Failed to load quotes: \(error)")
            isLoadingQuotes = false
        }
    }

    private func playResponse(_ response: StorySegmentData) {
        // Safety check: only play if response has actual audio
        guard response.hasAudio else {
            print("⚠️ Cannot play response - no audio content (media_url: \(response.mediaUrl ?? "nil"))")
            return
        }

        // Use the AudioPlayerService to play from this response onwards
        // The service will auto-advance through the chronological list
        audioPlayer.playFromHere(responses, startId: response.id)
        print("▶️ Playing from: \(response.fullName) - \(response.transcriptionText ?? "")")
    }

    // MARK: - Podcast Generation

    private func generatePodcast() {
        guard !isGeneratingPodcast else { return }

        isGeneratingPodcast = true

        Task {
            do {
                try await APIService.shared.generatePodcast(storyId: UUID(uuidString: story.id) ?? UUID())

                await MainActor.run {
                    isGeneratingPodcast = false
                    podcastAlertMessage = "Podcast generation started! It will be ready in a few minutes."
                    showPodcastAlert = true
                }
            } catch {
                await MainActor.run {
                    isGeneratingPodcast = false
                    podcastAlertMessage = "Failed to generate podcast. Please try again."
                    showPodcastAlert = true
                }
            }
        }
    }

    // MARK: - Memory Context Generation

    private func generateMemoryContext(for response: StorySegmentData, allResponses: [StorySegmentData]) -> MemoryContextData {
        let threadResponses = findAllResponsesInThread(startingFrom: response, allResponses: allResponses)

        // Find unique contributors
        let contributors = Set(threadResponses.map { $0.fullName })
            .map { name -> MemoryContextData.Contributor in
                let response = threadResponses.first { $0.fullName == name }!
                return MemoryContextData.Contributor(
                    name: name,
                    avatarColor: response.storytellerColor
                )
            }
            .sorted { $0.name < $1.name }

        // Calculate years spanned
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let dates = threadResponses.compactMap { formatter.date(from: $0.createdAt) }
        let calendar = Calendar.current

        var startYear = 2020
        var endYear: Int? = nil

        if let earliestDate = dates.min(), let latestDate = dates.max() {
            startYear = calendar.component(.year, from: earliestDate)
            let endYearValue = calendar.component(.year, from: latestDate)
            endYear = endYearValue != startYear ? endYearValue : nil
        }

        let yearsSpan = MemoryContextData.YearsSpan(
            startYear: startYear,
            endYear: endYear,
            displayString: endYear == nil ? "\(startYear)" : "\(startYear)-\(endYear!)"
        )

        // TODO: Replace with real data from backend API
        let relatedPrompts: [MemoryContextData.RelatedPrompt] = [
            MemoryContextData.RelatedPrompt(id: "1", title: "What was your favorite holiday tradition?", responseCount: 5),
            MemoryContextData.RelatedPrompt(id: "2", title: "Tell us about a memorable family trip", responseCount: 3),
            MemoryContextData.RelatedPrompt(id: "3", title: "What's your earliest childhood memory?", responseCount: 7)
        ]

        // TODO: Replace with AI-detected emotional tags from backend
        let emotionalTags: [MemoryContextData.EmotionalTag] = [
            MemoryContextData.EmotionalTag(emoji: "❤️", name: "Love", count: 12),
            MemoryContextData.EmotionalTag(emoji: "🎉", name: "Celebration", count: 8),
            MemoryContextData.EmotionalTag(emoji: "😂", name: "Humor", count: 5),
            MemoryContextData.EmotionalTag(emoji: "😢", name: "Nostalgia", count: 3)
        ]

        return MemoryContextData(
            contributors: contributors,
            yearsSpanned: yearsSpan,
            relatedPrompts: relatedPrompts,
            emotionalTags: emotionalTags
        )
    }

    private func findAllResponsesInThread(startingFrom response: StorySegmentData, allResponses: [StorySegmentData]) -> [StorySegmentData] {
        var threadResponses: [StorySegmentData] = []
        var toProcess: [StorySegmentData] = [response]
        var processedIds = Set<String>()

        while !toProcess.isEmpty {
            let current = toProcess.removeFirst()

            guard !processedIds.contains(current.id) else { continue }
            processedIds.insert(current.id)
            threadResponses.append(current)

            // Find all direct replies to this response
            let replies = allResponses.filter { $0.replyToResponseId == current.id }
            toProcess.append(contentsOf: replies)
        }

        return threadResponses
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
    // selectedReaction binding REMOVED - social feature de-emphasized

    @State private var playbackSpeed: PlaybackSpeed = .normal
    @State private var isDragging = false
    @GestureState private var dragOffset: CGFloat = 0
    // showReactionPicker REMOVED - social feature de-emphasized

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

    // MARK: - Haptic Feedback Helper
    private func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        if theme.enableHaptics {
            let impact = UIImpactFeedbackGenerator(style: style)
            impact.impactOccurred()
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            if let segment = currentSegment {
                HStack(spacing: 10) {
                    Circle()
                        .fill(segment.color)
                        .frame(width: 10, height: 10)
                        .overlay(
                            Circle()
                                .stroke(segment.color.opacity(0.5), lineWidth: 2)
                                .scaleEffect(isPlaying ? 1.8 : 1.0)
                                .opacity(isPlaying ? 0 : 1)
                                .animation(
                                    isPlaying ? .easeOut(duration: 1).repeatForever(autoreverses: false) : .default,
                                    value: isPlaying
                                )
                        )

                    Text(segment.storyteller)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(segment.color)
                        .lineLimit(1)

                    Spacer()

                    Text(formatTime(totalDuration))
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(theme.secondaryTextColor)

                    Button(action: { playbackSpeed = playbackSpeed.next }) {
                        Text(playbackSpeed.label)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(theme.secondaryTextColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(Color.gray.opacity(0.2))
                            )
                    }
                    .accessibilityLabel("Playback speed \(playbackSpeed.label)")
                }
                .padding(.horizontal, 4)
            }

            HStack(spacing: 10) {
                Text(formatTime(currentTime))
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(theme.secondaryTextColor)
                    .frame(width: 44, alignment: .trailing)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.25))
                            .frame(height: 10)

                        ForEach(segments) { segment in
                            let startX = geometry.size.width * (segment.startTime / totalDuration)
                            let width = geometry.size.width * (segment.duration / totalDuration)

                            Capsule()
                                .fill(segment.color)
                                .frame(width: max(width, 4), height: 10)
                                .offset(x: startX)
                        }

                        Circle()
                            .fill(.white)
                            .frame(width: isDragging ? 22 : 18, height: isDragging ? 22 : 18)
                            .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                            .overlay(
                                Circle()
                                    .stroke(theme.accentColor, lineWidth: isDragging ? 3 : 0)
                            )
                            .offset(x: geometry.size.width * (currentTime / totalDuration) - (isDragging ? 11 : 9))
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
                .frame(height: 24)
                .accessibilityLabel("Story timeline")
                .accessibilityValue("\(formatTime(currentTime)) of \(formatTime(totalDuration))")
            }

            // Controls (compact layout with reduced spacing and sizes) - All buttons 44x44 minimum per Apple HIG
            HStack(spacing: 16) {
                // REACTION BUTTON REMOVED - social feature de-emphasized in favor of value extraction
                // Users can now export/share stories instead of reacting

                Spacer()

                // Skip backward 15s - 44x44 touch target
                Button(action: {
                    triggerHaptic()
                    currentTime = max(0, currentTime - 15)
                }) {
                    Image(systemName: "gobackward.15")
                        .font(.title3)
                        .foregroundColor(theme.textColor)
                }
                .frame(width: 44, height: 44)
                .accessibilityLabel("Skip back 15 seconds")

                // Play/Pause - 44x44 touch target
                Button(action: {
                    triggerHaptic()
                    isPlaying.toggle()
                }) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(theme.accentColor)
                }
                .frame(width: 44, height: 44)
                .accessibilityLabel(isPlaying ? "Pause" : "Play")

                // Skip forward 15s - 44x44 touch target
                Button(action: {
                    triggerHaptic()
                    currentTime = min(totalDuration, currentTime + 15)
                }) {
                    Image(systemName: "goforward.15")
                        .font(.title3)
                        .foregroundColor(theme.textColor)
                }
                .frame(width: 44, height: 44)
                .accessibilityLabel("Skip forward 15 seconds")

                Spacer()

                // Share button - 44x44 touch target
                Button(action: {
                    triggerHaptic()
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                        .foregroundColor(theme.textColor)
                }
                .frame(width: 44, height: 44)
                .accessibilityLabel("Share story")
            }

        }
        // REACTION PICKER SHEET REMOVED - social feature de-emphasized
    }
}

// MARK: - Child Story Detail (Audio-First)

struct ChildStoryDetail: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
                    Button(action: {
                        if theme.enableHaptics {
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                        }
                        dismiss()
                    }) {
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let story: Story

    @State private var isPlaying = false

    var body: some View {
        ZStack {
            // Warm background
            theme.backgroundColor.ignoresSafeArea()

            VStack(spacing: 32) {
                // Large back button
                HStack {
                    Button(action: {
                        if theme.enableHaptics {
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                        }
                        dismiss()
                    }) {
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

// MARK: - Empty Perspectives View

struct EmptyPerspectivesView: View {
    @Environment(\.theme) var theme
    let onAddFirst: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(theme.accentColor.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 44))
                        .foregroundColor(theme.accentColor.opacity(0.6))
                }

                VStack(spacing: 8) {
                    Text("Start the Conversation")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(theme.textColor)

                    Text("Share your unique perspective on this story. Your voice matters!")
                        .font(.system(size: 15))
                        .foregroundColor(theme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                SuggestionRow(
                    icon: "mic.fill",
                    text: "Record a voice memory",
                    color: .storytellerOrange
                )
                SuggestionRow(
                    icon: "text.quote",
                    text: "Share a written reflection",
                    color: .storytellerBlue
                )
                SuggestionRow(
                    icon: "heart.fill",
                    text: "Add your personal connection",
                    color: .storytellerPurple
                )
            }
            .padding(.vertical, 8)

            Button(action: onAddFirst) {
                HStack(spacing: 10) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Be the First to Share")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [theme.accentColor, theme.accentColor.opacity(0.85)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: theme.accentColor.opacity(0.3), radius: 6, y: 3)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
    }
}

struct SuggestionRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Prompt Memory Header

enum PromptCategory: String, CaseIterable {
    case voiceMemory = "Voice Memory"
    case story = "Story"
    case reflection = "Reflection"

    var icon: String {
        switch self {
        case .voiceMemory: return "waveform"
        case .story: return "book.closed"
        case .reflection: return "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .voiceMemory: return .storytellerOrange
        case .story: return .storytellerBlue
        case .reflection: return .storytellerPurple
        }
    }
}

struct PromptMemoryHeader: View {
    let promptText: String
    let promptCategory: PromptCategory
    let responses: [StorySegmentData]
    let theme: PersonaTheme

    // Calculate time span from responses
    private var yearsSpanned: String? {
        guard !responses.isEmpty else { return nil }

        let dates = responses.compactMap { response -> Date? in
            ISO8601DateFormatter().date(from: response.createdAt)
        }.sorted()

        guard dates.count >= 2,
              let oldest = dates.first,
              let newest = dates.last else { return nil }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: oldest, to: newest)

        if let years = components.year, years > 0 {
            let monthStr = components.month ?? 0
            return monthStr > 0 ? "\(years)y \(monthStr)m" : "\(years)y"
        } else if let months = components.month, months > 0 {
            return "\(months)m"
        }

        return nil
    }

    // Get last added date (most recent response)
    private var lastAddedDate: Date? {
        guard !responses.isEmpty else { return nil }
        let dates = responses.compactMap { response -> Date? in
            ISO8601DateFormatter().date(from: response.createdAt)
        }.sorted()
        return dates.last
    }

    // Format legacy date (e.g., "Recorded in 2019")
    private var legacyDateString: String? {
        guard !responses.isEmpty else { return nil }

        let dates = responses.compactMap { response -> Date? in
            ISO8601DateFormatter().date(from: response.createdAt)
        }.sorted()

        guard let oldest = dates.first else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return "Recorded in \(formatter.string(from: oldest))"
    }

    // HEARD COUNT REMOVED - social proof feature de-emphasized in favor of value extraction

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Category badge + time span
            HStack(spacing: 12) {
                // Category badge
                HStack(spacing: 6) {
                    Image(systemName: promptCategory.icon)
                        .font(.caption)
                    Text(promptCategory.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(promptCategory.color.opacity(0.9))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(promptCategory.color.opacity(0.12))
                )

                // Time span badge (subtle emotional flex)
                if let spanned = yearsSpanned {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.caption2)
                        Text(spanned)
                            .font(.caption)
                            .monospacedDigit()
                    }
                    .foregroundColor(theme.secondaryTextColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(theme.secondaryTextColor.opacity(0.08))
                    )
                }

                Spacer()
            }

            // Prompt text - calm, prominent
            Text(promptText)
                .font(.system(size: 22, weight: .medium, design: .rounded))
                .foregroundColor(theme.textColor)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            // Legacy signals or empty state
            if responses.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "speaker.wave.2")
                        .font(.caption)
                    Text("Be the first to share this memory")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
            } else {
                // Legacy signals showing memory engagement (without heard count)
                LegacySignalsView(
                    voiceCount: responses.count,
                    heardCount: nil,  // REMOVED - social proof de-emphasized
                    lastAdded: lastAddedDate,
                    theme: theme
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.cardBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            promptCategory.color.opacity(0.2),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        )
    }
}

// MARK: - Story Quote Item Component

struct StoryQuoteItem: View {
    let quoteText: String
    let authorName: String
    let authorRole: String
    @Environment(\.theme) var theme

    var roleColor: Color {
        switch authorRole.lowercased() {
        case "elder": return .storytellerElder
        case "parent", "organizer": return .storytellerParent
        case "child": return .storytellerChild
        case "teen": return .storytellerTeen
        default: return .storytellerPurple
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\"\(quoteText)\"")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(theme.textColor)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Text("— \(authorName)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                Text(authorRole.capitalized)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(roleColor.opacity(0.8))
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Preview

struct StoryDetailView_Previews: PreviewProvider {
    static let sampleStory = Story(
        id: UUID().uuidString,
        title: "The Summer Road Trip of '68",
        storyteller: "Grandma Rose",
        imageURL: nil,
        voiceCount: 3,
        timestamp: Date().addingTimeInterval(-3600)
    )

    static var previews: some View {
        Group {
            StoryDetailView(story: sampleStory)
                .themed(DarkTheme())
                .previewDisplayName("dark Detail")

            StoryDetailView(story: sampleStory)
                .themed(LightTheme())
                .previewDisplayName("light Detail")

            StoryDetailView(story: sampleStory)
                .themed(LightTheme())
                .previewDisplayName("Child Detail")

            StoryDetailView(story: sampleStory)
                .themed(LightTheme())
                .previewDisplayName("Elder Detail")
        }
    }
}
