//
//  ThreadedTimelineView.swift
//  StoryRide
//
//  Visualizes story responses as a threaded conversation timeline
//

import SwiftUI
import Combine

// MARK: - Waveform Preview Component

struct WaveformPreviewView: View {
    let color: Color
    let isPlaying: Bool

    @State private var barHeights: [CGFloat] = []

    init(color: Color, isPlaying: Bool) {
        self.color = color
        self.isPlaying = isPlaying
    }

    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<20, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(color.opacity(isPlaying ? 1.0 : 0.5))
                    .frame(width: 2, height: barHeights.isEmpty ? 8 : barHeights[index])
            }
        }
        .frame(height: 12)
        .onAppear {
            generateWaveform()
        }
    }

    private func generateWaveform() {
        barHeights = (0..<20).map { _ in CGFloat.random(in: 4...12) }
    }
}

// MARK: - Threaded Timeline View

struct ThreadedTimelineView: View {
    @Environment(\.theme) var theme

    let responses: [StorySegmentData]
    let onReplyToResponse: (StorySegmentData) -> Void
    let onPlayResponse: (StorySegmentData) -> Void

    // Organized by thread hierarchy
    private var threadedResponses: [ThreadNode] {
        buildThreadTree(from: responses)
    }

    // Memory context panel state
    @State private var showMemoryContext = false
    @State private var contextForResponse: StorySegmentData?

    // Memory resonance state
    @State private var showResonance = false
    @State private var resonanceForResponse: StorySegmentData?
    @ObservedObject private var audioPlayer = AudioPlayerService.shared

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(threadedResponses) { node in
                    ThreadNodeView(
                        node: node,
                        depth: 0,
                        onReply: onReplyToResponse,
                        onPlay: onPlayResponse,
                        onShowMemoryContext: { response in
                            contextForResponse = response
                            showMemoryContext = true
                        }
                    )
                }
            }
            .padding(.vertical, 16)
        }
        .sheet(isPresented: $showMemoryContext) {
            if let response = contextForResponse {
                MemoryContextPanel(
                    context: generateMemoryContext(for: response, allResponses: responses)
                )
            }
        }
        .sheet(isPresented: $showResonance) {
            if let response = resonanceForResponse {
                MemoryResonanceView(
                    response: response,
                    onResponseShared: {
                        // Refresh or post-processing after sharing
                        showResonance = false
                        audioPlayer.shouldShowResonance = false
                    }
                )
            }
        }
        .onChange(of: audioPlayer.shouldShowResonance) { shouldShow in
            if shouldShow, let responseId = audioPlayer.currentResponseId,
               let response = responses.first(where: { $0.id == responseId }) {
                resonanceForResponse = response
                showResonance = true
            }
        }
    }

    // Build thread tree from flat list of responses
    private func buildThreadTree(from responses: [StorySegmentData]) -> [ThreadNode] {
        var nodeMap: [String: ThreadNode] = [:]
        var rootNodes: [ThreadNode] = []

        // First pass: Create all nodes
        for response in responses {
            nodeMap[response.id] = ThreadNode(response: response, children: [])
        }

        // Second pass: Build parent-child relationships
        for response in responses {
            guard let node = nodeMap[response.id] else { continue }

            if let replyId = response.replyToResponseId,
               let parentNode = nodeMap[replyId] {
                // This is a reply - add to parent's children
                parentNode.children.append(node)
            } else {
                // This is a root response
                rootNodes.append(node)
            }
        }

        // Sort by creation date (oldest first for chronological story)
        return rootNodes.sorted { $0.response.createdAtDate < $1.response.createdAtDate }
    }

    // Generate memory context data for the panel
    private func generateMemoryContext(for response: StorySegmentData, allResponses: [StorySegmentData]) -> MemoryContextData {
        // Find all responses in the same thread
        let threadResponses = findAllResponsesInThread(startingFrom: response, allResponses: allResponses)

        // Contributors: Get unique contributors
        let uniqueContributors = Array(Set(threadResponses.map { response in
            MemoryContextData.Contributor(
                name: response.fullName,
                avatarColor: response.storytellerColor
            )
        }))

        // Years spanned: Calculate from response dates
        let dates = threadResponses.compactMap { ISO8601DateFormatter().date(from: $0.createdAt) }
        let years = dates.map { Calendar.current.component(.year, from: $0) }
        let minYear = years.min() ?? Calendar.current.component(.year, from: Date())
        let maxYear = years.max()

        let yearsSpan = MemoryContextData.YearsSpan(
            startYear: minYear,
            endYear: maxYear,
            displayString: maxYear == nil ? "\(minYear)" : "\(minYear)-\(maxYear!)"
        )

        // Related prompts (mock for now - would need backend API)
        let relatedPrompts = [
            MemoryContextData.RelatedPrompt(id: "1", title: "What was your favorite holiday tradition?", responseCount: 5),
            MemoryContextData.RelatedPrompt(id: "2", title: "Tell us about a memorable family trip", responseCount: 3)
        ]

        // Emotional tags (mock for now - would be AI-detected from transcriptions)
        let emotionalTags = [
            MemoryContextData.EmotionalTag(emoji: "❤️", name: "Love", count: 12),
            MemoryContextData.EmotionalTag(emoji: "😂", name: "Humor", count: 5),
            MemoryContextData.EmotionalTag(emoji: "🎉", name: "Celebration", count: 3)
        ]

        return MemoryContextData(
            contributors: uniqueContributors.sorted { $0.name < $1.name },
            yearsSpanned: yearsSpan,
            relatedPrompts: relatedPrompts,
            emotionalTags: emotionalTags
        )
    }

    // Helper to find all responses in a thread
    private func findAllResponsesInThread(startingFrom response: StorySegmentData, allResponses: [StorySegmentData]) -> [StorySegmentData] {
        var threadResponses: [StorySegmentData] = [response]
        var processedIds: Set<String> = [response.id]

        // Find all replies to this response
        func addReplies(to responseId: String) {
            for resp in allResponses where resp.replyToResponseId == responseId {
                if !processedIds.contains(resp.id) {
                    processedIds.insert(resp.id)
                    threadResponses.append(resp)
                    addReplies(to: resp.id)
                }
            }
        }

        addReplies(to: response.id)
        return threadResponses
    }
}

// MARK: - Thread Node (Tree Structure)

class ThreadNode: Identifiable {
    let id: String
    let response: StorySegmentData
    var children: [ThreadNode]

    init(response: StorySegmentData, children: [ThreadNode] = []) {
        self.id = response.id
        self.response = response
        self.children = children.sorted { $0.response.createdAtDate < $1.response.createdAtDate }
    }
}

// MARK: - Thread Node View

struct ThreadNodeView: View {
    @Environment(\.theme) var theme

    let node: ThreadNode
    let depth: Int // Indentation level
    let onReply: (StorySegmentData) -> Void
    let onPlay: (StorySegmentData) -> Void
    let onShowMemoryContext: (StorySegmentData) -> Void

    private let indentWidth: CGFloat = 32
    private let maxDepth: Int = 3 // Prevent too much nesting

    var effectiveDepth: Int {
        min(depth, maxDepth)
    }

    // Visual hierarchy based on depth
    var isRootCard: Bool {
        effectiveDepth == 0
    }

    var isDeepReply: Bool {
        effectiveDepth >= 2
    }

    var barWidth: CGFloat {
        if isRootCard { return 4 }      // Thicker for root
        else if isDeepReply { return 1 } // Very thin for deep
        else { return 2 }                // Medium for replies
    }

    var barOpacity: Double {
        if isRootCard { return 0.4 }      // Warmer/fuller for root
        else if isDeepReply { return 0.12 } // Softer/faded for deep
        else { return 0.25 }              // Medium for replies
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // The response card
            HStack(spacing: 0) {
                // Indentation for threading with hierarchy
                if effectiveDepth > 0 {
                    HStack(spacing: 0) {
                        ForEach(0..<effectiveDepth, id: \.self) { level in
                            // Use different styles for different depths
                            if level >= effectiveDepth - 1 && isDeepReply {
                                // Deep thread: very soft, dotted effect
                                RoundedRectangle(cornerRadius: 0.5)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                node.response.storytellerColor.opacity(barOpacity),
                                                node.response.storytellerColor.opacity(barOpacity * 0.5),
                                                node.response.storytellerColor.opacity(barOpacity)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: barWidth)
                                    .padding(.leading, level == 0 ? 8 : indentWidth - barWidth)
                            } else {
                                Rectangle()
                                    .fill(node.response.storytellerColor.opacity(barOpacity))
                                    .frame(width: barWidth)
                                    .padding(.leading, level == 0 ? 8 : indentWidth - barWidth)
                            }
                        }
                    }
                }

                // Response content
                ResponseCard(
                    response: node.response,
                    isThreaded: effectiveDepth > 0,
                    isDeepReply: isDeepReply,
                    onReply: { onReply(node.response) },
                    onPlay: { onPlay(node.response) },
                    onShowMemoryContext: { onShowMemoryContext(node.response) }
                )
                .padding(.leading, effectiveDepth > 0 ? 16 : 0)
            }
            .padding(.horizontal, 16)

            // Render children (recursive)
            if !node.children.isEmpty {
                ForEach(node.children) { childNode in
                    ThreadNodeView(
                        node: childNode,
                        depth: depth + 1,
                        onReply: onReply,
                        onPlay: onPlay,
                        onShowMemoryContext: onShowMemoryContext
                    )
                }
            }
        }
    }
}

// MARK: - Response Card

struct ResponseCard: View {
    @Environment(\.theme) var theme

    let response: StorySegmentData
    let isThreaded: Bool
    let isDeepReply: Bool
    let onReply: () -> Void
    let onPlay: () -> Void
    let onShowMemoryContext: () -> Void

    @State private var isExpanded = false
    @State private var pulseAnimation = false

    // Shared player state for playing indicator
    @ObservedObject private var playerState = TimelinePlayerState.shared

    var isCurrentlyPlaying: Bool {
        playerState.isPlaying(response.id)
    }

    // Visual hierarchy adjustments
    var cardPadding: CGFloat {
        isDeepReply ? 10 : (isThreaded ? 12 : 16)
    }

    var cardRadius: CGFloat {
        isDeepReply ? 10 : (isThreaded ? 12 : 16)
    }

    var shadowOpacity: Double {
        if isCurrentlyPlaying { return 0.12 }
        return isDeepReply ? 0.02 : (isThreaded ? 0.03 : 0.05)
    }

    var shadowRadius: CGFloat {
        if isCurrentlyPlaying { return 12 }
        return isDeepReply ? 3 : (isThreaded ? 4 : 8)
    }

    // Avatar sizing based on hierarchy
    var avatarSize: CGFloat {
        isDeepReply ? 28 : (isThreaded ? 36 : 44)
    }

    var avatarFontSize: CGFloat {
        isDeepReply ? 13 : (isThreaded ? 16 : 18)
    }

    var nameFontSize: CGFloat {
        isDeepReply ? 14 : (isThreaded ? 15 : 17)
    }

    // Legacy timestamp formatting (e.g., "Recorded in 2019")
    var legacyTimestamp: String {
        guard let date = ISO8601DateFormatter().date(from: response.createdAt) else {
            return "Recently"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return "Recorded in \(formatter.string(from: date))"
    }

    var formattedDuration: String {
        guard let duration = response.durationSeconds else { return "0:00" }
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Avatar + Name + Time + Playing Indicator
            HStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                response.storytellerColor,
                                response.storytellerColor.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: avatarSize, height: avatarSize)
                    .overlay(
                        Text(String(response.fullName.prefix(1)))
                            .font(.system(size: avatarFontSize, weight: .bold))
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(response.fullName)
                            .font(.system(size: nameFontSize, weight: .semibold))
                            .foregroundColor(theme.textColor)

                        // Playing indicator (pulsing dot + text)
                        if isCurrentlyPlaying {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(response.storytellerColor)
                                    .frame(width: 8, height: 8)
                                    .opacity(pulseAnimation ? 0.5 : 1)

                                Text("Playing")
                                    .font(.caption)
                                    .foregroundColor(response.storytellerColor)
                            }
                        }
                    }

                    Text(legacyTimestamp)
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }

                Spacer()

                // Duration badge
                HStack(spacing: 4) {
                    Image(systemName: "waveform")
                        .font(.caption2)
                    Text(formattedDuration)
                        .font(.caption)
                        .monospacedDigit()
                }
                .foregroundColor(response.storytellerColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(response.storytellerColor.opacity(0.15))
                ).glassEffect()
            }

            // Transcription (if available)
            if let transcription = response.transcriptionText, !transcription.isEmpty {
                Text(transcription)
                    .font(.system(size: isThreaded ? 14 : 15))
                    .foregroundColor(theme.textColor)
                    .lineLimit(isExpanded ? nil : 3)
                    .onTapGesture {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }
            }

            // Action Buttons
            HStack(spacing: 16) {
                // Play button
                Button(action: onPlay) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 18))
                        Text("Play")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(response.storytellerColor)
                }.buttonStyle(.glass)

                // Reply button
                Button(action: onReply) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrowshape.turn.up.left.fill")
                            .font(.system(size: 16))
                        Text("Reply")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(theme.secondaryTextColor)
                }.buttonStyle(.glass)

                Spacer()

                // More options
                Menu {
                    Button(action: onShowMemoryContext) {
                        Label("Memory Context", systemImage: "info.circle")
                    }
                    Button(action: {}) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    Button(action: {}) {
                        Label("Report", systemImage: "exclamationmark.triangle")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16))
                        .foregroundColor(theme.secondaryTextColor.opacity(0.6))
                }
            }
            .padding(.top, 4)

            // Silent Listener indicator (shows personal listening stats)
            SilentListenerIndicator(
                listenCount: SilentListenerService.shared.listenCount(for: response.id),
                totalListenTime: SilentListenerService.shared.totalListenTime(for: response.id),
                theme: theme
            )
        }
        .padding(cardPadding)
        .background(
            ZStack {
    

                // Enhanced highlight when playing
                if isCurrentlyPlaying {
                    RoundedRectangle(cornerRadius: cardRadius)
                        .fill(response.storytellerColor.opacity(0.12))
                        .animation(.easeInOut(duration: 0.3), value: isCurrentlyPlaying)
                }
            }
            .shadow(
                color: .black.opacity(shadowOpacity),
                radius: shadowRadius,
                y: isCurrentlyPlaying ? 6 : (isDeepReply ? 1 : (isThreaded ? 2 : 4))
            )
        )
        .padding(.vertical, 6)
        .onAppear {
            // Start pulse animation when playing
            if isCurrentlyPlaying {
                startPulseAnimation()
            }
        }
        .onChange(of: isCurrentlyPlaying) { newValue in
            if newValue {
                startPulseAnimation()
            } else {
                pulseAnimation = false
            }
        }
    }

    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
    }
}

// MARK: - Chronological Threaded Timeline (Chronological Order + Threading Indicators)

struct ChronologicalThreadedTimelineView: View {
    @Environment(\.theme) var theme

    let responses: [StorySegmentData]
    let onReplyToResponse: (StorySegmentData) -> Void
    let onPlayResponse: (StorySegmentData) -> Void
    let onShowMemoryContext: (StorySegmentData) -> Void

    // Sort chronologically
    private var sortedResponses: [StorySegmentData] {
        responses.sorted { $0.createdAtDate < $1.createdAtDate }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(sortedResponses) { response in
                    ChronologicalResponseCard(
                        response: response,
                        allResponses: responses,
                        onReply: onReplyToResponse,
                        onPlay: onPlayResponse,
                        onShowMemoryContext: onShowMemoryContext
                    )
                }
            }
            .padding(.vertical, 16)
        }
    }
}

struct ChronologicalResponseCard: View {
    @Environment(\.theme) var theme

    let response: StorySegmentData
    let allResponses: [StorySegmentData]
    let onReply: (StorySegmentData) -> Void
    let onPlay: (StorySegmentData) -> Void
    let onShowMemoryContext: (StorySegmentData) -> Void

    @State private var isExpanded = false
    @State private var animationProgress: CGFloat = 0
    @State private var textExpanded = false

    // Calculate thread depth for visual indicators
    private var threadDepth: Int {
        var depth = 0
        var currentId = response.replyToResponseId

        while let lightId = currentId {
            depth += 1
            currentId = allResponses.first { $0.id == lightId }?.replyToResponseId
        }

        return depth
    }

    // Visual hierarchy based on depth
    var isRootCard: Bool {
        threadDepth == 0
    }

    var isDeepReply: Bool {
        threadDepth >= 2
    }

    var barWidth: CGFloat {
        if isRootCard { return 4 }
        else if isDeepReply { return 1 }
        else { return 2 }
    }

    var barOpacity: Double {
        if isRootCard { return 0.4 }
        else if isDeepReply { return 0.12 }
        else { return 0.25 }
    }

    // Find parent response for context label
    private var parentResponse: StorySegmentData? {
        guard let replyId = response.replyToResponseId else { return nil }
        return allResponses.first { $0.id == replyId }
    }

    private let indentWidth: CGFloat = 20
    private let maxDepth: Int = 3

    var effectiveDepth: Int {
        min(threadDepth, maxDepth)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                // Threading indicators with hierarchy-based styling
                if effectiveDepth > 0 {
                    HStack(spacing: 0) {
                        ForEach(0..<effectiveDepth, id: \.self) { level in
                            // Use different styles for different depths
                            if level >= effectiveDepth - 1 && isDeepReply {
                                // Deep thread: very soft, gradient effect
                                RoundedRectangle(cornerRadius: 0.5)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                response.storytellerColor.opacity(barOpacity),
                                                response.storytellerColor.opacity(barOpacity * 0.5),
                                                response.storytellerColor.opacity(barOpacity)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: barWidth)
                                    .padding(.leading, level == 0 ? 8 : indentWidth - barWidth)
                                    
                            } else {
                                Rectangle()
                                    .fill(response.storytellerColor.opacity(barOpacity))
                                    .frame(width: barWidth)
                                    .padding(.leading, level == 0 ? 8 : indentWidth - barWidth)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 0) {
                    if isExpanded {
                        ExpandedContent(
                            response: response,
                            parentResponse: parentResponse,
                            textExpanded: $textExpanded,
                            onPlay: { onPlay(response) },
                            onReply: { onReply(response) },
                            onShowMemoryContext: onShowMemoryContext
                        )
                    } else {
                        CollapsedContent(
                            response: response,
                            parentResponse: parentResponse,
                            onPlay: { onPlay(response) }
                        ).glassEffect(.regular.tint(response.storytellerColor.opacity( 0.03)))
                    }
                }
                .padding(.leading, effectiveDepth > 0 ? 16 : 0)
            }
            
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .onTapGesture {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isExpanded.toggle()
                if !isExpanded {
                    textExpanded = false
                }
            }
        }
    }

    private func formatDuration(_ duration: Int) -> String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Collapsed Perspective Content

struct CollapsedContent: View {
    @Environment(\.theme) var theme

    let response: StorySegmentData
    let parentResponse: StorySegmentData?
    let onPlay: () -> Void

    @State private var pulseAnimation = false
    @ObservedObject private var playerState = TimelinePlayerState.shared

    var isCurrentlyPlaying: Bool {
        playerState.isPlaying(response.id)
    }

    // Legacy timestamp formatting
    var legacyTimestamp: String {
        guard let date = ISO8601DateFormatter().date(from: response.createdAt) else {
            return "Recently"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return "Recorded in \(formatter.string(from: date))"
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(response.storytellerColor)
                .frame(width: 32, height: 32)
                .overlay(
                    Text(String(response.fullName.prefix(1)))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(response.fullName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.textColor)

                    if isCurrentlyPlaying {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(response.storytellerColor)
                                .frame(width: 6, height: 6)
                                .opacity(pulseAnimation ? 0.5 : 1)

                            Text("Playing")
                                .font(.caption2)
                                .foregroundColor(response.storytellerColor)
                        }
                    }

                    if let duration = response.durationSeconds {
                        Text(formatDuration(duration))
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }

                if let transcription = response.transcriptionText, !transcription.isEmpty {
                    Text(transcription)
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                        .lineLimit(1)
                }

                if let parentResponse = parentResponse {
                    HStack(spacing: 4) {
                        Image(systemName: "arrowshape.turn.up.left")
                            .font(.caption2)
//                        Text(parent.fullName)
//                            .font(.caption2)
                    }
                    .foregroundColor(response.storytellerColor)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(theme.secondaryTextColor.opacity(0.5))
        }
        .padding(12)
        .background(
            isCurrentlyPlaying ?
                response.storytellerColor.opacity(0.08) : Color.clear
        )
        .onAppear {
            if isCurrentlyPlaying {
                startPulseAnimation()
            }
        }
        .onChange(of: isCurrentlyPlaying) { newValue in
            if newValue {
                startPulseAnimation()
            } else {
                pulseAnimation = false
            }
        }
    }

    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
    }

    private func formatDuration(_ duration: Int) -> String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Expanded Perspective Content

struct ExpandedContent: View {
    @Environment(\.theme) var theme

    let response: StorySegmentData
    let parentResponse: StorySegmentData?
    @Binding var textExpanded: Bool
    let onPlay: () -> Void
    let onReply: () -> Void
    let onShowMemoryContext: (StorySegmentData) -> Void

    @State private var pulseAnimation = false
    @ObservedObject private var playerState = TimelinePlayerState.shared

    var isCurrentlyPlaying: Bool {
        playerState.isPlaying(response.id)
    }

    // Legacy timestamp formatting
    var legacyTimestamp: String {
        guard let date = ISO8601DateFormatter().date(from: response.createdAt) else {
            return "Recently"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return "Recorded in \(formatter.string(from: date))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let parent = parentResponse {
                HStack(spacing: 6) {
                    Image(systemName: "arrowshape.turn.up.left.fill")
                        .font(.caption2)
                        .foregroundColor(response.storytellerColor)

                    Text("Replying to ")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                    + Text(parent.fullName)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(response.storytellerColor)
                }
            }

            HStack(spacing: 12) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                response.storytellerColor,
                                response.storytellerColor.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(response.fullName.prefix(1)))
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(response.fullName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.textColor)

                        // Playing indicator
                        if isCurrentlyPlaying {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(response.storytellerColor)
                                    .frame(width: 8, height: 8)
                                    .opacity(pulseAnimation ? 0.5 : 1)

                                Text("Playing")
                                    .font(.caption)
                                    .foregroundColor(response.storytellerColor)
                            }
                        }
                    }

                    Text(legacyTimestamp)
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }

                Spacer()

                if let duration = response.durationSeconds {
                    HStack(spacing: 4) {
                        Image(systemName: "waveform")
                            .font(.caption2)
                        Text(formatDuration(duration))
                            .font(.caption)
                            .monospacedDigit()
                    }
                    .foregroundColor(response.storytellerColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(response.storytellerColor.opacity(0.15))
                    )
                }
            }

            if let transcription = response.transcriptionText, !transcription.isEmpty {
                Text(transcription)
                    .font(.system(size: 15))
                    .foregroundColor(theme.textColor)
                    .lineLimit(textExpanded ? nil : 3)
                    .onTapGesture {
                        withAnimation {
                            textExpanded.toggle()
                        }
                    }
            }

            HStack(spacing: 16) {
                Button(action: onPlay) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 18))
                        Text("Play")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(response.storytellerColor)
                }.buttonStyle(.glass)

                Button(action: onReply) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrowshape.turn.up.left.fill")
                            .font(.system(size: 16))
                        Text("Reply")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(theme.secondaryTextColor)
                }.buttonStyle(.glass)

                Spacer()

                // Memory Context button
                Button(action: { onShowMemoryContext(response) }) {
                    Image(systemName: "info")
                        .font(.system(size: 16))
                        .foregroundColor(theme.secondaryTextColor.opacity(0.6))
                }.buttonStyle(.glass)
            }
            .padding(.top, 4)
        }

        .padding(16)
        .glassEffect(.regular.tint(response.storytellerColor.opacity(0.05)),in: RoundedRectangle(cornerRadius: 20))
 
        .onAppear {
            if isCurrentlyPlaying {
                startPulseAnimation()
            }
        }
        .onChange(of: isCurrentlyPlaying) { newValue in
            if newValue {
                startPulseAnimation()
            } else {
                pulseAnimation = false
            }
        }

    }

    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
    }

    private func formatDuration(_ duration: Int) -> String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Compact Timeline (for smaller views)

struct CompactThreadedTimelineView: View {
    @Environment(\.theme) var theme

    let responses: [StorySegmentData]
    let onTapResponse: (StorySegmentData) -> Void

    var rootResponses: [StorySegmentData] {
        responses.filter { $0.isRootResponse }
            .sorted { $0.createdAtDate < $1.createdAtDate }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(rootResponses) { response in
                CompactResponseRow(
                    response: response,
                    replyCount: countReplies(to: response.id),
                    onTap: { onTapResponse(response) }
                )
            }
        }
    }

    private func countReplies(to responseId: String) -> Int {
        responses.filter { $0.replyToResponseId == responseId }.count
    }
}

// MARK: - Compact Response Row

struct CompactResponseRow: View {
    @Environment(\.theme) var theme

    let response: StorySegmentData
    let replyCount: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(response.storytellerColor)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(String(response.fullName.prefix(1)))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(response.fullName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.textColor)

                    if let transcription = response.transcriptionText?.prefix(40) {
                        Text(transcription)
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if replyCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.caption2)
                        Text("\(replyCount)")
                            .font(.caption2)
                            .monospacedDigit()
                    }
                    .foregroundColor(theme.accentColor)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor.opacity(0.5))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.cardBackgroundColor)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

struct ThreadedTimelineView_Previews: PreviewProvider {
    static var sampleResponses: [StorySegmentData] {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let baseTime = Date()
        let twoDaysAgo = formatter.string(from: baseTime.addingTimeInterval(-172800))
        let oneDayAgo = formatter.string(from: baseTime.addingTimeInterval(-86400))
        let hour6Ago = formatter.string(from: baseTime.addingTimeInterval(-21600))
        let hour3Ago = formatter.string(from: baseTime.addingTimeInterval(-10800))
        let hour1Ago = formatter.string(from: baseTime.addingTimeInterval(-3600))
        let min20Ago = formatter.string(from: baseTime.addingTimeInterval(-1200))
        let min5Ago = formatter.string(from: baseTime.addingTimeInterval(-300))
        let now = formatter.string(from: baseTime)

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
                role: "light",
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
                role: "dark",
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
                role: "light",
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

            // THREAD 3: Sophie asks a question
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
                role: "light",
                avatarUrl: nil,
                replyToResponseId: "resp-8"
            )
        ]
    }

    static var simpleResponses: [StorySegmentData] {
        let formatter = ISO8601DateFormatter()
        return [
            StorySegmentData(
                id: "1",
                userId: "user1",
                source: "app",
                mediaUrl: "https://example.com/1.m4a",
                transcriptionText: "I remember playing in the backyard every summer...",
                durationSeconds: 45,
                createdAt: formatter.string(from: Date().addingTimeInterval(-3600)),
                fullName: "Grandma",
                role: "elder",
                avatarUrl: nil,
                replyToResponseId: nil
            ),
            StorySegmentData(
                id: "2",
                userId: "user2",
                source: "app",
                mediaUrl: "https://example.com/2.m4a",
                transcriptionText: "I loved those summers too! Remember the treehouse?",
                durationSeconds: 30,
                createdAt: formatter.string(from: Date().addingTimeInterval(-3000)),
                fullName: "Mom",
                role: "light",
                avatarUrl: nil,
                replyToResponseId: "1"
            )
        ]
    }

    static var previews: some View {
        Group {
            // ⭐️ USED IN STORYDETAILVIEW - Chronological with threading indicators
            ChronologicalThreadedTimelineView(
                responses: sampleResponses,
                onReplyToResponse: { _ in },
                onPlayResponse: { _ in },
                onShowMemoryContext: { _ in }
            )
            .themed(LightTheme())
            .previewDisplayName("⭐️ Chronological (StoryDetailView)")

            // Chronological - dark Theme
            ChronologicalThreadedTimelineView(
                responses: sampleResponses,
                onReplyToResponse: { _ in },
                onPlayResponse: { _ in },
                onShowMemoryContext: { _ in }
            )
            .themed(DarkTheme())
            .previewDisplayName("⭐️ Chronological - dark")

            // Chronological - Dark Mode
            ChronologicalThreadedTimelineView(
                responses: sampleResponses,
                onReplyToResponse: { _ in },
                onPlayResponse: { _ in },
                onShowMemoryContext: { _ in }
            )
            .themed(LightTheme())
            .preferredColorScheme(.dark)
            .previewDisplayName("⭐️ Chronological - Dark")

            // Hierarchical Threading (alternative view)
            ThreadedTimelineView(
                responses: sampleResponses,
                onReplyToResponse: { _ in },
                onPlayResponse: { _ in }
            )
            .themed(LightTheme())
            .previewDisplayName("Hierarchical Threading")

            // Compact Timeline
            CompactThreadedTimelineView(
                responses: sampleResponses,
                onTapResponse: { _ in }
            )
            .themed(LightTheme())
            .previewDisplayName("Compact Timeline")

            // Simple 2-response thread
            ChronologicalThreadedTimelineView(
                responses: simpleResponses,
                onReplyToResponse: { _ in },
                onPlayResponse: { _ in },
                onShowMemoryContext: { _ in }
            )
            .themed(LightTheme())
            .previewDisplayName("Simple Thread (2 responses)")

            // Light Theme
            ChronologicalThreadedTimelineView(
                responses: sampleResponses,
                onReplyToResponse: { _ in },
                onPlayResponse: { _ in },
                onShowMemoryContext: { _ in }
            )
            .themed(LightTheme())
            .previewDisplayName("⭐️ Chronological - Light")
        }
    }
}
