//
//  PublicStoryView.swift
//  StoryRide
//
//  Public view for shared stories/collections - NO LOGIN REQUIRED
//  Transforms app from "social network" to "value extraction tool"
//  Viewers can experience family stories without creating accounts
//

import SwiftUI
import AVKit

// MARK: - Public Story View

struct PublicStoryView: View {
    @State private var shareToken: String
    @State private var loadingState: LoadingState<PublicContent> = .loading
    @State private var currentSegment: PublicSegment?
    @State private var isPlaying = false
    @State private var showWatermark = true

    init(shareToken: String) {
        self._shareToken = State(initialValue: shareToken)
    }

    var body: some View {
        Group {
            switch loadingState {
            case .loading:
                loadingView
            case .loaded(let content):
                contentView(content: content)
            case .empty:
                emptyView
            case .error(let message):
                errorView(message: message)
            }
        }
        .task {
            await loadPublicContent()
        }
        .statusBar(hidden: true)
    }

    private var loadingView: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("Loading story...")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }

    private var emptyView: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "eye.slash.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.white.opacity(0.5))

                Text("Content Not Available")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)

                Text("This story may have been removed or the link expired")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }

    private func errorView(message: String) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.orange)

                Text("Couldn't Load Story")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)

                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }

    private func contentView(content: PublicContent) -> some View {
        ZStack {
            // Background image with overlay
            Group {
                if let coverUrl = content.coverImageUrl {
                    AsyncImage(url: URL(string: coverUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.black
                    }
                } else {
                    Color.black
                }
            }
            .ignoresSafeArea()

            // Dark overlay for readability
            Rectangle()
                .fill(Color.black.opacity(0.6))
                .ignoresSafeArea()

            // Content
            VStack(spacing: 0) {
                // Watermark (if enabled)
                if showWatermark, let watermark = content.watermarkText {
                    watermarkView(text: watermark)
                        .padding(.top, 60)
                        .transition(.opacity)
                }

                Spacer()

                // Story content
                storyContentView(content: content)

                Spacer()

                // Player controls
                if let segment = currentSegment {
                    playerControls(segment: segment)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                }
            }

            // Download disabled notice
            if !content.permissions.download {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                        Text("Download disabled")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 20)
                }
            }
        }
    }

    private func watermarkView(text: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "drop.seal.fill")
                .font(.system(size: 24))
                .foregroundColor(.white.opacity(0.3))

            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }

    private func storyContentView(content: PublicContent) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Title
                Text(content.title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // Summary
                if let summary = content.summary {
                    Text(summary)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 40)
                }

                // Story panels (visual narrative)
                if !content.panels.isEmpty {
                    panelsView(panels: content.panels)
                }
            }
            .padding(.vertical, 32)
        }
    }

    private func panelsView(panels: [PublicPanel]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(panels) { panel in
                    VStack(spacing: 12) {
                        AsyncImage(url: URL(string: panel.imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                        }
                        .frame(width: 280, height: 200)
                        .cornerRadius(16)
                        .clipped()

                        Text(panel.caption)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .frame(width: 260)
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private func playerControls(segment: PublicSegment) -> some View {
        VStack(spacing: 16) {
            // Progress bar
            VStack(spacing: 8) {
                if let duration = segment.duration {
                    HStack {
                        Text(formatTime(currentTime ?? 0))
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))

                        Spacer()

                        Text(formatTime(duration))
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 4)

                            Rectangle()
                                .fill(.white)
                                .frame(width: progressWidth(in: geometry.size.width), height: 4)
                        }
                        .cornerRadius(2)
                    }
                    .frame(height: 4)
                }
            }

            // Controls
            HStack(spacing: 24) {
                Button(action: {
                    // Skip back
                }) {
                    Image(systemName: "gobackward.15")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }

                Button(action: {
                    isPlaying.toggle()
                }) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.white)
                }

                Button(action: {
                    // Skip forward
                }) {
                    Image(systemName: "goforward.15")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }

            // Speaker info
            if let speaker = segment.speaker {
                HStack(spacing: 8) {
                    Image(systemName: "person.wave.2.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))

                    Text(speaker)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.15))
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var currentTime: TimeInterval? {
        // Mock current time - in production this would track actual playback
        return isPlaying ? 30.0 : 0.0
    }

    private func progressWidth(in totalWidth: CGFloat) -> CGFloat {
        guard let current = currentTime,
              let duration = currentSegment?.duration else { return 0 }
        return (current / duration) * totalWidth
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    private func loadPublicContent() async {
        do {
            // Mock data - in production, this would call GET /api/public/s/:token
            let mockContent = PublicContent(
                title: "The Summer Road Trip of 1968",
                summary: "Grandma Rose tells the story of how the family station wagon broke down in the middle of nowhere, and how a kind stranger helped them continue their journey to California.",
                coverImageUrl: nil,
                watermarkText: "Shared by Rodriguez Family",
                showWatermark: true,
                permissions: SharePermissionsPublic(view: true, download: false, comment: false),
                panels: [
                    PublicPanel(
                        id: "1",
                        imageUrl: "https://picsum.photos/280/200?random=1",
                        caption: "The old station wagon"
                    ),
                    PublicPanel(
                        id: "2",
                        imageUrl: "https://picsum.photos/280/200?random=2",
                        caption: "Somewhere in Arizona"
                    ),
                    PublicPanel(
                        id: "3",
                        imageUrl: "https://picsum.photos/280/200?random=3",
                        caption: "Finally reaching California"
                    )
                ],
                segments: [
                    PublicSegment(
                        id: "1",
                        audioUrl: nil,
                        transcription: "So there we were, in the middle of the desert with smoke coming from the engine...",
                        speaker: "Grandma Rose",
                        duration: 180.0
                    )
                ]
            )

            await MainActor.run {
                loadingState = .loaded(mockContent)
                currentSegment = mockContent.segments.first
                showWatermark = mockContent.showWatermark
            }
        } catch {
            await MainActor.run {
                loadingState = .error("Failed to load story. Please check your link and try again.")
            }
        }
    }
}

// MARK: - Models

struct PublicContent {
    let title: String
    let summary: String?
    let coverImageUrl: String?
    let watermarkText: String?
    let showWatermark: Bool
    let permissions: SharePermissionsPublic
    let panels: [PublicPanel]
    let segments: [PublicSegment]
}

struct PublicPanel: Identifiable {
    let id: String
    let imageUrl: String
    let caption: String
}

struct PublicSegment: Identifiable {
    let id: String
    let audioUrl: String?
    let transcription: String
    let speaker: String?
    let duration: TimeInterval?
}

struct SharePermissionsPublic {
    let view: Bool
    let download: Bool
    let comment: Bool
}

// MARK: - Preview

struct PublicStoryView_Previews: PreviewProvider {
    static var previews: some View {
        PublicStoryView(shareToken: "abc123xy")
            .previewDisplayName("Public Story View")
    }
}
