//
//  HubView.swift
//  StoryRide
//
//  The Hub - Home Feed with adaptive layouts per persona
//

import SwiftUI

// MARK: - Hub View

struct HubView: View {
    @Environment(\.theme) var theme
    @State private var loadingState: LoadingState<[Story]> = .loading
    @State private var showStudio = false

    var body: some View {
        Group {
            switch theme.role {
            case .teen:
                TeenHub(
                    loadingState: loadingState,
                    showStudio: $showStudio
                )
            case .parent:
                ParentHub(
                    loadingState: loadingState,
                    showStudio: $showStudio
                )
            case .child:
                ChildHub(
                    loadingState: loadingState,
                    showStudio: $showStudio
                )
            case .elder:
                ElderHub(
                    loadingState: loadingState,
                    showStudio: $showStudio
                )
            }
        }
        .animation(theme.animation, value: theme.role)
        .sheet(isPresented: $showStudio) {
            NavigationStack {
                StudioView()
            }
        }
        .onAppear {
            loadStories()
        }
    }

    private func loadStories() {
        // Simulate network loading - replace with real API call later
        loadingState = .loading

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // For demo: toggle between states to test UI
            // In production: loadingState = .loaded(fetchedStories)
            let stories = Story.sampleStories

            if stories.isEmpty {
                loadingState = .empty
            } else {
                loadingState = .loaded(stories)
            }
        }
    }
}

// MARK: - Teen Hub (Card-Based Scroll)

struct TeenHub: View {
    let loadingState: LoadingState<[Story]>
    @Binding var showStudio: Bool
    @Environment(\.theme) var theme

    var body: some View {
        NavigationStack {
            Group {
                switch loadingState {
                case .loading:
                    // Skeleton loading state
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(0..<3, id: \.self) { _ in
                                TeenFeedCardSkeleton()
                            }
                        }
                        .padding(.horizontal, theme.screenPadding)
                        .padding(.vertical, 12)
                    }

                case .empty:
                    TeenEmptyState(onCreateStory: { showStudio = true })

                case .loaded(let stories):
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(stories) { story in
                                NavigationLink(destination: StoryDetailView(story: story)) {
                                    TeenFeedCard(story: story)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, theme.screenPadding)
                        .padding(.vertical, 12)
                    }

                case .error(let message):
                    ErrorStateView(message: message, onRetry: {})
                }
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationTitle("StoryRide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showStudio = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(theme.accentColor)
                    }
                }
            }
        }
        .accessibilityLabel("Stories feed")
    }
}

// MARK: - Teen Feed Card

struct TeenFeedCard: View {
    @Environment(\.theme) var theme
    let story: Story

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
                // Image section
                ZStack(alignment: .topTrailing) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    story.storytellerColor.opacity(0.6),
                                    story.storytellerColor
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 400)

                    // Voice count badge
                    if story.voiceCount > 1 {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.caption2)
                            Text("\(story.voiceCount)")
                                .font(.caption.bold())
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(.black.opacity(0.7))
                        )
                        .padding(12)
                    }
                }

                // Text section
                VStack(alignment: .leading, spacing: 10) {
                    Text(story.title)
                        .font(theme.headlineFont)
                        .foregroundColor(theme.textColor)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 8) {
                        Circle()
                            .fill(story.storytellerColor)
                            .frame(width: 10, height: 10)

                        Text(story.storyteller)
                            .font(.subheadline)
                            .foregroundColor(theme.secondaryTextColor)

                        Spacer()

                        Text(story.timestamp, style: .relative)
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor.opacity(0.7))
                    }
                }
                .padding(16)
                .background(theme.cardBackgroundColor)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
        .accessibilityLabel("\(story.title) by \(story.storyteller)")
    }
}

// MARK: - Parent Hub (Masonry Grid - Pinterest Style)

struct ParentHub: View {
    let loadingState: LoadingState<[Story]>
    @Binding var showStudio: Bool
    @Environment(\.theme) var theme

    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            Group {
                switch loadingState {
                case .loading:
                    ScrollView {
                        VStack(spacing: 20) {
                            // Skeleton progress banner
                            ProgressBannerSkeleton()

                            // Skeleton grid
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(0..<6, id: \.self) { index in
                                    ParentGridCardSkeleton(isLarge: index % 3 == 0)
                                }
                            }
                        }
                        .padding(theme.screenPadding)
                    }

                case .empty:
                    ParentEmptyState(
                        onCreateStory: { showStudio = true },
                        onInviteFamily: { /* TODO: Invite flow */ }
                    )

                case .loaded(let stories):
                    ScrollView {
                        VStack(spacing: 20) {
                            // Progress banner
                            HStack(spacing: 16) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.orange)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("This Week")
                                        .font(.headline)
                                        .foregroundColor(theme.textColor)

                                    Text("\(stories.prefix(3).count) Stories captured")
                                        .font(.subheadline)
                                        .foregroundColor(theme.secondaryTextColor)
                                }

                                Spacer()

                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.green)
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(theme.cardBackgroundColor)
                            )
                            .shadow(color: .black.opacity(0.06), radius: 8, y: 2)

                            // Masonry grid with staggered heights
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(Array(stories.enumerated()), id: \.element.id) { index, story in
                                    NavigationLink(destination: StoryDetailView(story: story)) {
                                        ParentGridCard(
                                            story: story,
                                            isLarge: index % 3 == 0
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(theme.screenPadding)
                    }

                case .error(let message):
                    ErrorStateView(message: message, onRetry: {})
                }
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationTitle("Family Stories")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showStudio = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(theme.accentColor)
                    }
                }
            }
        }
    }
}

// MARK: - Parent Grid Card (Pinterest Style)

struct ParentGridCard: View {
    @Environment(\.theme) var theme
    let story: Story
    let isLarge: Bool

    var cardHeight: CGFloat {
        isLarge ? 280 : 220
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image section
            ZStack(alignment: .topTrailing) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                story.storytellerColor.opacity(0.3),
                                story.storytellerColor.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: cardHeight * 0.6)

                // Voice count badge
                if story.voiceCount > 1 {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption2)
                        Text("\(story.voiceCount)")
                            .font(.caption.bold())
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(story.storytellerColor.opacity(0.9))
                    )
                    .padding(8)
                }
            }

            // Text section
            VStack(alignment: .leading, spacing: 8) {
                Text(story.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.textColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 6) {
                    Circle()
                        .fill(story.storytellerColor)
                        .frame(width: 8, height: 8)

                    Text(story.storyteller)
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                        .lineLimit(1)
                }

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(story.timestamp, style: .relative)
                        .font(.caption2)
                }
                .foregroundColor(theme.secondaryTextColor.opacity(0.7))
            }
            .padding(12)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
        .accessibilityLabel("\(story.title) by \(story.storyteller)")
    }
}

// MARK: - Child Hub (Storybook Mode - Single Card)

struct ChildHub: View {
    let loadingState: LoadingState<[Story]>
    @Binding var showStudio: Bool
    @Environment(\.theme) var theme
    @State private var currentIndex = 0
    @State private var isPlaying = false

    var body: some View {
        Group {
            switch loadingState {
            case .loading:
                ChildCardSkeleton()

            case .empty:
                ChildEmptyState(onRecordStory: { showStudio = true })

            case .loaded(let stories):
                ChildHubContent(
                    stories: stories,
                    showStudio: $showStudio,
                    currentIndex: $currentIndex
                )

            case .error(let message):
                ErrorStateView(message: message, onRetry: {})
            }
        }
        .background(theme.backgroundColor.ignoresSafeArea())
        .safeAreaInset(edge: .top, alignment: .trailing) {
            Button(action: { showStudio = true }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(theme.accentColor)
            }
            .padding(.trailing, 20)
            .padding(.top, 8)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Story viewer")
    }
}

// MARK: - Child Hub Content (Loaded State)

struct ChildHubContent: View {
    let stories: [Story]
    @Binding var showStudio: Bool
    @Binding var currentIndex: Int
    @Environment(\.theme) var theme

    var currentStory: Story {
        stories[currentIndex]
    }

    var body: some View {
        VStack(spacing: 24) {
            // Story counter
            Text("Story \(currentIndex + 1) of \(stories.count)")
                .font(theme.bodyFont)
                .foregroundColor(theme.secondaryTextColor)
                .padding(.top, theme.screenPadding)

            Spacer()

            // Single centered card with navigation
            NavigationLink(destination: StoryDetailView(story: currentStory)) {
                VStack(spacing: theme.screenPadding) {
                    StoryCard(story: currentStory)
                        .frame(maxHeight: 500)

                    // Giant Listen button
                    ListenButton()
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, theme.screenPadding)

            Spacer()

            // Navigation arrows
            HStack(spacing: 60) {
                Button(action: {
                    if currentIndex > 0 {
                        withAnimation(theme.animation) {
                            currentIndex -= 1
                        }
                    }
                }) {
                    Image(systemName: "arrow.left.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(currentIndex > 0 ? theme.accentColor : theme.secondaryTextColor)
                }
                .disabled(currentIndex == 0)

                Button(action: {
                    if currentIndex < stories.count - 1 {
                        withAnimation(theme.animation) {
                            currentIndex += 1
                        }
                    }
                }) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(currentIndex < stories.count - 1 ? theme.accentColor : theme.secondaryTextColor)
                }
                .disabled(currentIndex == stories.count - 1)
            }
            .padding(.bottom, theme.screenPadding)
        }
    }
}

// MARK: - Elder Hub (Voice Home - Minimal UI)

struct ElderHub: View {
    let loadingState: LoadingState<[Story]>
    @Binding var showStudio: Bool
    @Environment(\.theme) var theme
    @State private var isListening = false

    var body: some View {
        Group {
            switch loadingState {
            case .loading:
                ElderSkeleton()

            case .empty:
                ElderEmptyState(onCallMe: { isListening = true })

            case .loaded:
                ElderHubContent(
                    isListening: $isListening,
                    showStudio: $showStudio
                )

            case .error(let message):
                ErrorStateView(message: message, onRetry: {})
            }
        }
        .background(theme.backgroundColor.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityLabel(isListening ? "Currently listening" : "Welcome screen")
    }
}

// MARK: - Elder Hub Content (Loaded State)

struct ElderHubContent: View {
    @Binding var isListening: Bool
    @Binding var showStudio: Bool
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Large icon
            Image(systemName: isListening ? "waveform" : "phone.fill")
                .font(.system(size: 100))
                .foregroundColor(theme.accentColor)
                .symbolEffect(.variableColor, isActive: isListening)

            // Large text
            VStack(spacing: 16) {
                Text(isListening ? "Listening..." : "Welcome")
                    .font(theme.headlineFont)
                    .foregroundColor(theme.textColor)

                Text(isListening ?
                     "I'm ready to hear your story" :
                     "Tap the button to start"
                )
                    .font(theme.bodyFont)
                    .foregroundColor(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, theme.screenPadding)
            }

            Spacer()

            // Giant start button
            Button(action: {
                isListening.toggle()
                // Initiate phone call or voice interaction
            }) {
                Text(isListening ? "End Call" : "Start")
                    .font(theme.headlineFont)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: theme.buttonHeight)
                    .background(
                        RoundedRectangle(cornerRadius: theme.cardRadius)
                            .fill(isListening ? Color.alertRed : theme.accentColor)
                    )
                    .shadow(color: theme.accentColor.opacity(0.3), radius: 12)
            }
            .padding(.horizontal, theme.screenPadding)
            .padding(.bottom, 60)
        }
    }
}

// MARK: - Sample Data Extension

extension Story {
    static let sampleStories: [Story] = [
        Story(
            title: "The Summer Road Trip of '68",
            storyteller: "Grandma Rose",
            imageURL: nil,
            voiceCount: 3,
            timestamp: Date().addingTimeInterval(-3600),
            storytellerRole: .elder
        ),
        Story(
            title: "My First Day at School",
            storyteller: "Dad",
            imageURL: nil,
            voiceCount: 2,
            timestamp: Date().addingTimeInterval(-7200),
            storytellerRole: .parent
        ),
        Story(
            title: "The Best Birthday Ever",
            storyteller: "Mia",
            imageURL: nil,
            voiceCount: 1,
            timestamp: Date().addingTimeInterval(-10800),
            storytellerRole: .child
        ),
        Story(
            title: "When I Met Your Grandfather",
            storyteller: "Grandma Rose",
            imageURL: nil,
            voiceCount: 4,
            timestamp: Date().addingTimeInterval(-14400),
            storytellerRole: .elder
        ),
        Story(
            title: "My Favorite Toy",
            storyteller: "Leo",
            imageURL: nil,
            voiceCount: 1,
            timestamp: Date().addingTimeInterval(-18000),
            storytellerRole: .teen
        )
    ]
}

// MARK: - Preview

struct HubView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HubView()
                .themed(TeenTheme())
                .previewDisplayName("Teen Hub")

            HubView()
                .themed(ParentTheme())
                .previewDisplayName("Parent Hub")

            HubView()
                .themed(ChildTheme())
                .previewDisplayName("Child Hub")

            HubView()
                .themed(ElderTheme())
                .previewDisplayName("Elder Hub")
        }
    }
}
