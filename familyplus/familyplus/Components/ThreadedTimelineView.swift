//
//  ThreadedTimelineView.swift
//  StoryRide
//
//  Visualizes story responses as a threaded conversation timeline
//

import SwiftUI

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

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(threadedResponses) { node in
                    ThreadNodeView(
                        node: node,
                        depth: 0,
                        onReply: onReplyToResponse,
                        onPlay: onPlayResponse
                    )
                }
            }
            .padding(.vertical, 16)
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

            if let parentId = response.replyToResponseId,
               let parentNode = nodeMap[parentId] {
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

    private let indentWidth: CGFloat = 32
    private let maxDepth: Int = 3 // Prevent too much nesting

    var effectiveDepth: Int {
        min(depth, maxDepth)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // The response card
            HStack(spacing: 0) {
                // Indentation for threading
                if effectiveDepth > 0 {
                    HStack(spacing: 0) {
                        ForEach(0..<effectiveDepth, id: \.self) { level in
                            Rectangle()
                                .fill(node.response.storytellerColor.opacity(0.2))
                                .frame(width: 2)
                                .padding(.leading, level == 0 ? 8 : indentWidth - 2)
                        }
                    }
                }

                // Response content
                ResponseCard(
                    response: node.response,
                    isThreaded: effectiveDepth > 0,
                    onReply: { onReply(node.response) },
                    onPlay: { onPlay(node.response) }
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
                        onPlay: onPlay
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
    let onReply: () -> Void
    let onPlay: () -> Void

    @State private var isExpanded = false

    var formattedDuration: String {
        guard let duration = response.durationSeconds else { return "0:00" }
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Avatar + Name + Time
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
                    .frame(width: isThreaded ? 36 : 44, height: isThreaded ? 36 : 44)
                    .overlay(
                        Text(String(response.fullName.prefix(1)))
                            .font(.system(size: isThreaded ? 16 : 18, weight: .bold))
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(response.fullName)
                        .font(.system(size: isThreaded ? 15 : 17, weight: .semibold))
                        .foregroundColor(theme.textColor)

                    Text(response.createdAtDate, style: .relative)
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
                )
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
                }

                // Reply button
                Button(action: onReply) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrowshape.turn.up.left.fill")
                            .font(.system(size: 16))
                        Text("Reply")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(theme.secondaryTextColor)
                }

                Spacer()

                // More options
                Menu {
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
        }
        .padding(isThreaded ? 12 : 16)
        .background(
            RoundedRectangle(cornerRadius: isThreaded ? 12 : 16)
                .fill(theme.cardBackgroundColor)
                .shadow(
                    color: .black.opacity(isThreaded ? 0.03 : 0.05),
                    radius: isThreaded ? 4 : 8,
                    y: isThreaded ? 2 : 4
                )
        )
        .padding(.vertical, 6)
    }
}

// MARK: - Chronological Threaded Timeline (Chronological Order + Threading Indicators)

struct ChronologicalThreadedTimelineView: View {
    @Environment(\.theme) var theme

    let responses: [StorySegmentData]
    let onReplyToResponse: (StorySegmentData) -> Void
    let onPlayResponse: (StorySegmentData) -> Void

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
                        onPlay: onPlayResponse
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

    @State private var isExpanded = false
    @State private var animationProgress: CGFloat = 0
    @State private var textExpanded = false

    // Calculate thread depth for visual indicators
    private var threadDepth: Int {
        var depth = 0
        var currentId = response.replyToResponseId

        while let parentId = currentId {
            depth += 1
            currentId = allResponses.first { $0.id == parentId }?.replyToResponseId
        }

        return depth
    }

    // Find parent response for context label
    private var parentResponse: StorySegmentData? {
        guard let parentId = response.replyToResponseId else { return nil }
        return allResponses.first { $0.id == parentId }
    }

    private let indentWidth: CGFloat = 20
    private let maxDepth: Int = 3

    var effectiveDepth: Int {
        min(threadDepth, maxDepth)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                // Threading indicators (strengthened colored bars)
                if effectiveDepth > 0 {
                    HStack(spacing: 0) {
                        ForEach(0..<effectiveDepth, id: \.self) { level in
                            Rectangle()
                                .fill(response.storytellerColor.opacity(0.4))
                                .frame(width: 3)
                                .padding(.leading, level == 0 ? 8 : indentWidth - 3)
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
                            onReply: { onReply(response) }
                        )
                    } else {
                        CollapsedContent(
                            response: response,
                            parentResponse: parentResponse,
                            onPlay: { onPlay(response) }
                        )
                    }
                }
                .padding(.leading, effectiveDepth > 0 ? 16 : 0)
            }
            .background(response.storytellerColor.opacity(isExpanded ? 0.06 : 0.03))
            .clipShape(RoundedRectangle(cornerRadius: isExpanded ? 16 : 12))
            .overlay(
                // Animated curved connector to parent (overlay so it doesn't break layout)
                Group {
                    if let parent = parentResponse, effectiveDepth > 0 {
                        GeometryReader { geometry in
                            Path { path in
                                // Start from left edge at current response
                                let startX: CGFloat = 16 + 8
                                let startY: CGFloat = 16

                                // Curve up to connect visually to parent
                                let endX = startX + CGFloat(effectiveDepth) * indentWidth
                                let endY: CGFloat = -20

                                path.move(to: CGPoint(x: startX, y: startY))
                                path.addQuadCurve(
                                    to: CGPoint(x: endX, y: endY),
                                    control: CGPoint(x: startX, y: endY + 10)
                                )
                            }
                            .trim(from: 0, to: animationProgress)
                            .stroke(response.storytellerColor.opacity(0.5), lineWidth: 2.5)
                            .onAppear {
                                withAnimation(.easeOut(duration: 0.4)) {
                                    animationProgress = 1.0
                                }
                            }
                        }
                    }
                }
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
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

                if let parent = parentResponse {
                    HStack(spacing: 4) {
                        Image(systemName: "arrowshape.turn.up.left")
                            .font(.caption2)
                        Text(parent.fullName)
                            .font(.caption2)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                    Text(response.fullName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.textColor)

                    Text(response.createdAtDate, style: .relative)
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
                }

                Button(action: onReply) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrowshape.turn.up.left.fill")
                            .font(.system(size: 16))
                        Text("Reply")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(theme.secondaryTextColor)
                }

                Spacer()
            }
            .padding(.top, 4)
        }
        .padding(16)
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
        [
            StorySegmentData(
                id: "1",
                userId: "user1",
                source: "app",
                mediaUrl: "https://example.com/1.m4a",
                transcriptionText: "I remember playing in the backyard every summer...",
                durationSeconds: 45,
                createdAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3600)),
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
                createdAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3000)),
                fullName: "Mom",
                role: "parent",
                avatarUrl: nil,
                replyToResponseId: "1"
            ),
            StorySegmentData(
                id: "3",
                userId: "user3",
                source: "app",
                mediaUrl: "https://example.com/3.m4a",
                transcriptionText: "Yes! We built it together that one summer.",
                durationSeconds: 25,
                createdAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-2500)),
                fullName: "Grandma",
                role: "elder",
                avatarUrl: nil,
                replyToResponseId: "2"
            )
        ]
    }

    static var previews: some View {
        ThreadedTimelineView(
            responses: sampleResponses,
            onReplyToResponse: { _ in },
            onPlayResponse: { _ in }
        )
        .themed(ParentTheme())
        .previewDisplayName("Threaded Timeline")
    }
}
