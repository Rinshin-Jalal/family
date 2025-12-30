//
//  HubView.swift
//  StoryRide
//
//  Living Memory Dashboard - Home screen showing what's alive in the family
//

import SwiftUI

// MARK: - Dashboard Data Models

struct DailyPrompt: Identifiable, Codable {
    let id: String
    let question: String
    let category: PromptCategory
    let icon: String
    let validUntil: Date
    let responseCount: Int?  // How many family members answered

    enum PromptCategory: String, Codable {
        case memory = "Memory"
        case tradition = "Tradition"
        case milestone = "Milestone"
        case wisdom = "Wisdom"
        case fun = "Fun"
    }
}

struct RecentActivity: Identifiable {
    let id = UUID()
    let type: ActivityType
    let title: String
    let subtitle: String
    let timestamp: Date
    let storyId: String?
    let duration: TimeInterval?  // Duration in seconds for stories
    let hasListened: Bool        // Whether user has listened to this

    enum ActivityType {
        case newStory        // 🎙️
        case newPerspective  // 🧵
        case upcomingCall    // 📞
    }
}

struct ActiveStory: Identifiable {
    let id = UUID()
    let story: Story
    let lastActivity: Date
    let isEvolving: Bool  // Still receiving new perspectives
    let emotionalHint: String?  // Why should I open this story?
    let freshnessText: String?  // When was it last updated
}

struct UnheardVoice: Identifiable {
    let id = UUID()
    let storyteller: String
    let storyTitle: String
    let role: AppTheme
    let duration: TimeInterval
    let recordedDate: Date
}

// MARK: - Hub View (Dashboard)

struct HubView: View {
    @Environment(\.theme) var theme
    @State private var loadingState: LoadingState<DashboardData> = .loading
    @State private var showCaptureSheet = false
    @State private var dailyPrompt: DailyPrompt?
    @State private var selectedPromptForCapture: PromptData?

    var body: some View {
        UnifiedDashboard(
            loadingState: loadingState,
            onShowCapture: { prompt in
                selectedPromptForCapture = prompt
                showCaptureSheet = true
            },
            dailyPrompt: dailyPrompt
        )
        .animation(theme.animation, value: theme.role)
        .sheet(isPresented: $showCaptureSheet) {
            CaptureMemorySheet(initialPrompt: selectedPromptForCapture)
                .onDisappear {
                    selectedPromptForCapture = nil
                }
        }
        .onAppear {
            loadDashboard()
            loadDailyPrompt()
        }
    }

    private func loadDashboard() {
        loadingState = .loading

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            let data = DashboardData.mock
            loadingState = .loaded(data)
        }
    }

    private func loadDailyPrompt() {
        // TODO: Replace with actual API call
        // GET /api/prompts/daily
        dailyPrompt = DailyPrompt(
            id: UUID().uuidString,
            question: "What memory would you like to capture today?",
            category: .memory,
            icon: "lightbulb.fill",
            validUntil: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
            responseCount: nil
        )
    }
}

// MARK: - Dashboard Data

struct DashboardData {
    let recentActivities: [RecentActivity]
    let activeStories: [ActiveStory]
    let unheardVoices: [UnheardVoice]
    let totalVoices: Int
    let totalStories: Int

    static let mock = DashboardData(
        recentActivities: [
            RecentActivity(
                type: .newStory,
                title: "Grandpa shared a new story",
                subtitle: "The Summer of 1968",
                timestamp: Date().addingTimeInterval(-86400),
                storyId: "story-1",
                duration: 180,  // 3 minutes
                hasListened: false
            ),
            RecentActivity(
                type: .newPerspective,
                title: "A new perspective was added",
                subtitle: "to 'Our First Home' by Mom",
                timestamp: Date().addingTimeInterval(-172800),
                storyId: "story-2",
                duration: 120,  // 2 minutes
                hasListened: false
            ),
            RecentActivity(
                type: .upcomingCall,
                title: "Next call with Grandma",
                subtitle: "Tomorrow, 6 PM",
                timestamp: Date().addingTimeInterval(82800),
                storyId: nil,
                duration: nil,
                hasListened: false
            )
        ],
        activeStories: [
            ActiveStory(
                story: Story.sampleStories[0],
                lastActivity: Date().addingTimeInterval(-259200),  // 3 days ago
                isEvolving: true,
                emotionalHint: "Remembered very differently by each person",
                freshnessText: "New perspective 3 days ago"
            ),
            ActiveStory(
                story: Story.sampleStories[1],
                lastActivity: Date().addingTimeInterval(-604800),  // 1 week ago
                isEvolving: false,
                emotionalHint: "A joyful memory for everyone",
                freshnessText: "Last updated 1 week ago"
            ),
            ActiveStory(
                story: Story.sampleStories[2],
                lastActivity: Date().addingTimeInterval(-1209600),  // 2 weeks ago
                isEvolving: true,
                emotionalHint: "The last trip before everything changed",
                freshnessText: "Still evolving"
            )
        ],
        unheardVoices: [
            UnheardVoice(
                storyteller: "Grandma Rose",
                storyTitle: "When I Met Your Grandfather",
                role: .light,
                duration: 180,
                recordedDate: Date().addingTimeInterval(-432000)
            ),
            UnheardVoice(
                storyteller: "Dad",
                storyTitle: "My First Day at School",
                role: .light,
                duration: 120,
                recordedDate: Date().addingTimeInterval(-259200)
            )
        ],
        totalVoices: 23,
        totalStories: 12
    )
}

// MARK: - Unified dark/light Dashboard

struct UnifieddarklightDashboard: View {
    let loadingState: LoadingState<DashboardData>
    let onShowCapture: (PromptData?) -> Void
    let dailyPrompt: DailyPrompt?
    @Environment(\.theme) var theme

    var body: some View {
        NavigationStack {
            Group {
                switch loadingState {
                case .loading:
                    DashboardSkeleton()
                case .empty:
                    UnifiedEmptyState(onCreateStory: { onShowCapture(nil) })
                case .loaded(let data):
                    UnifiedDashboardContent(data: data, onShowCapture: onShowCapture, dailyPrompt: dailyPrompt)
                case .error(let message):
                    ErrorStateView(message: message, onRetry: {})
                }
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}


struct UnifiedDashboardContent: View {
    let data: DashboardData
    let onShowCapture: (PromptData?) -> Void
    let dailyPrompt: DailyPrompt?
    @Environment(\.theme) var theme

    var body: some View {
        ZStack {
            // MARK: - StoryDetailView-Style Background
            // Layer 1: Base
            theme.backgroundColor.ignoresSafeArea()

            // Layer 2: Hero-style diagonal gradient (StoryDetailView pattern)
            LinearGradient(
                colors: [
                    theme.accentColor.opacity(0.35),
                    complementaryColor.opacity(0.45),
                    theme.backgroundColor.opacity(0.70),
                    theme.backgroundColor
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Layer 3: Text visibility gradient (StoryDetailView pattern)
            LinearGradient(
                colors: [.clear, theme.backgroundColor.opacity(0.90)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 200)
            .ignoresSafeArea(edges: .top)

            // Layer 4: Sticky gradient overlay (StoryDetailView pattern)
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [
                        theme.accentColor.opacity(theme.role == .dark ? 0.15 : 0.35),
                        complementaryColor.opacity(theme.role == .dark ? 0.08 : 0.20),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
                .ignoresSafeArea(edges: .top)
                Spacer()
            }

            // Layer 5: Content
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Daily Prompt Card
                    if let prompt = dailyPrompt {
                        PromptHeroCard(prompt: prompt, onTap: {
                            let promptData = PromptData(
                                id: prompt.id,
                                text: prompt.question,
                                category: prompt.category.rawValue.lowercased(),
                                isCustom: false,
                                createdAt: ISO8601DateFormatter().string(from: Date())
                            )
                            onShowCapture(promptData)
                        })
                    }

                    // MARK: - Hero Section: What's New
                    HeroSection(activities: data.recentActivities)

                    // MARK: - Active Stories (Grid Layout)
                    ActiveStoriesGridSection(stories: data.activeStories)

                    // MARK: - Unheard Voices
                    if !data.unheardVoices.isEmpty {
                        UnheardVoicesSection(voices: data.unheardVoices)
                    }

                    // MARK: - Bottom padding for FAB
                    Color.clear.frame(height: 100)
                }
                .padding(theme.screenPadding)
            }
        }
        .overlay(alignment: .bottom) {
            CaptureMemoryButton(
                action: { onShowCapture(nil) },
                hasUnlistenedContent: !data.unheardVoices.isEmpty || data.recentActivities.contains(where: { !$0.hasListened })
            )
        }
    }

    private var complementaryColor: Color {
        switch theme.role {
        case .dark: return Color(red: 0.4, green: 0.7, blue: 1.0) // Sky blue
        case .light: return Color.storytellerBlue
        }
    }

    private var tertiaryColor: Color {
        switch theme.role {
        case .dark: return Color.storytellerBlue
        case .light: return Color.storytellerOrange
        }
    }
}

// MARK: - Unified Empty State

struct UnifiedEmptyState: View {
    let onCreateStory: () -> Void
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(theme.accentColor.opacity(0.6))
            VStack(spacing: 12) {
                Text("No Stories Yet")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(theme.textColor)
                Text("Start capturing your family memories")
                    .font(.system(size: 16))
                    .foregroundColor(theme.secondaryTextColor)
            }
            Button(action: onCreateStory) {
                Text("Record Your First Story")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(theme.accentColor))
            }
            Spacer()
        }
        .padding(theme.screenPadding)
    }
}

// MARK: - Unified Dashboard

struct UnifiedDashboard: View {
    let loadingState: LoadingState<DashboardData>
    let onShowCapture: (PromptData?) -> Void
    let dailyPrompt: DailyPrompt?
    @Environment(\.theme) var theme

    var body: some View {
        NavigationStack {
            Group {
                switch loadingState {
                case .loading:
                    DashboardSkeleton()
                case .empty:
                    UnifiedEmptyState(onCreateStory: { onShowCapture(nil) })
                case .loaded(let data):
                    UnifiedDashboardContent(data: data, onShowCapture: onShowCapture, dailyPrompt: dailyPrompt)
                case .error(let message):
                    ErrorStateView(message: message, onRetry: {})
                }
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Hero Section (What's New)

struct HeroSection: View {
    let activities: [RecentActivity]
    @Environment(\.theme) var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Show only the most important activity (first one)
            if let primaryActivity = activities.first {
                ActivityCard(activity: primaryActivity, theme: theme, isPrimary: true)
            }

            // "See all updates" link if there are more activities
            if activities.count > 1 {
                Button(action: {
                    // TODO: Navigate to all updates view
                }) {
                    HStack(spacing: 4) {
                        Text("See all updates")
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(theme.accentColor)
                }
            }
        }
    }
}

struct ActivityCard: View {
    let activity: RecentActivity
    let theme: PersonaTheme
    var isPrimary: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            // Colored icon circle
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [activityColor, activityColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: activityIcon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.textColor)

                Text(activity.subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(theme.secondaryTextColor)

                // Meta info
                HStack(spacing: 8) {
                    if let duration = activity.duration {
                        Text(durationText(duration))
                            .font(.system(size: 12))
                            .foregroundColor(theme.secondaryTextColor.opacity(0.7))
                    }

                    Text(timeAgoText)
                        .font(.system(size: 12))
                        .foregroundColor(theme.secondaryTextColor.opacity(0.7))
                }
            }

            Spacer()

            // Arrow
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.secondaryTextColor.opacity(0.4))
        }
        .padding(14)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.15), radius: 16, y: 8)
    }

    private var activityIcon: String {
        switch activity.type {
        case .newStory: return "waveform"
        case .newPerspective: return "bubble.left.and.bubble.right"
        case .upcomingCall: return "phone"
        }
    }

    private var activityColor: Color {
        switch activity.type {
        case .newStory: return .storytellerOrange
        case .newPerspective: return .storytellerBlue
        case .upcomingCall: return .storytellerPurple
        }
    }

    private var timeAgoText: String {
        let now = Date()
        let interval = now.timeIntervalSince(activity.timestamp)

        if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else if interval < 172800 {
            return "Yesterday"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }

    private func durationText(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        if minutes == 0 {
            return "\(Int(duration))s"
        }
        return "\(minutes) min"
    }
}

// MARK: - Active Stories Section

struct ActiveStoriesSection: View {
    let stories: [ActiveStory]
    @Environment(\.theme) var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stories")
                .font(theme.headlineFont)
                .foregroundColor(theme.textColor)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(stories, id: \.story.id) { activeStory in
                        NavigationLink(destination: StoryDetailView(story: activeStory.story)) {
                            ActiveStoryCard(story: activeStory, theme: theme)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

struct ActiveStoryCard: View {
    let story: ActiveStory
    let theme: PersonaTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Gradient header - more prominent
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            .storytellerPurple,
                            .storytellerPurple.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                ).clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 12,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 12
                    )
                )
                .frame(height: 50)
                .overlay(alignment: .bottomLeading) {
                    // Voice count badge
                    if story.story.voiceCount > 1 {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 10))
                            Text("\(story.story.voiceCount)")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .glassEffect()
                        .padding(8)
                    }
                }

            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(story.story.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.textColor)
                    .lineLimit(2)

                Text(story.story.storyteller)
                    .font(.system(size: 12))
                    .foregroundColor(.storytellerPurple)
            }
            .padding(12)
        }
        .frame(width: 160)
        .glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.15), radius: 16, y: 8)
    }
}

// MARK: - Active Stories Grid Section

struct ActiveStoriesGridSection: View {
    let stories: [ActiveStory]
    @Environment(\.theme) var theme

    // Adaptive grid that adjusts columns based on screen width
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stories")
                .font(theme.headlineFont)
                .foregroundColor(theme.textColor)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(stories, id: \.story.id) { activeStory in
                    NavigationLink(destination: StoryDetailView(story: activeStory.story)) {
                        ActiveStoryCard(story: activeStory, theme: theme)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Unheard Voices Section

struct UnheardVoicesSection: View {
    let voices: [UnheardVoice]
    @Environment(\.theme) var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Unheard")
                .font(theme.headlineFont)
                .foregroundColor(theme.textColor)

            VStack(spacing: 8) {
                ForEach(voices) { voice in
                    UnheardVoiceCard(voice: voice, theme: theme)
                }
            }
        }
    }
}

struct UnheardVoiceCard: View {
    let voice: UnheardVoice
    let theme: PersonaTheme

    var body: some View {
        HStack(spacing: 14) {
            // Colored initial circle
            Text(String(voice.storyteller.prefix(1)).uppercased())
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    storytellerColor,
                                    storytellerColor.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(voice.storyTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.textColor)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(voice.storyteller)
                        .font(.system(size: 13))
                        .foregroundColor(storytellerColor)

                    Text("·")
                        .foregroundColor(theme.secondaryTextColor.opacity(0.5))

                    Text(durationText)
                        .font(.system(size: 13))
                        .foregroundColor(theme.secondaryTextColor)
                }
            }

            Spacer()

            // Arrow
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(theme.secondaryTextColor.opacity(0.4))
        }
        .padding(14)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.15), radius: 16, y: 8)
    }

    private var storytellerColor: Color {
        switch voice.role {
        case .light: return .storytellerBlue
        case .dark: return .storytellerPurple
        }
    }

    private var durationText: String {
        let minutes = Int(voice.duration / 60)
        return "\(minutes) min"
    }
}

// MARK: - Prompt Hero Card

struct PromptHeroCard: View {
    let prompt: DailyPrompt
    let onTap: () -> Void
    @Environment(\.theme) var theme

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                // Prompt question
                Text(prompt.question)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .padding(24)
            .frame(maxWidth: .infinity,minHeight: 200)

            .glassEffect(.regular.tint(.accentColor), in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: theme.accentColor.opacity(0.3), radius: 20, y: 12)
        }
    }

    private var complementaryColor: Color {
        switch theme.role {
        case .dark: return Color(red: 0.4, green: 0.7, blue: 1.0)
        case .light: return Color.storytellerBlue
        }
    }
}

// MARK: - Capture Memory Button

struct CaptureMemoryButton: View {
    let action: () -> Void
    let hasUnlistenedContent: Bool
    @Environment(\.theme) var theme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: hasUnlistenedContent ? "plus.circle" : "plus.circle.fill")
                    .font(.system(size: hasUnlistenedContent ? 18 : 20))

                Text(buttonText)
                    .font(.system(size: hasUnlistenedContent ? 15 : 16, weight: hasUnlistenedContent ? .medium : .semibold))
            }
            .foregroundColor(hasUnlistenedContent ? theme.accentColor : .white)
            .padding(.horizontal, hasUnlistenedContent ? 18 : 20)
            .padding(.vertical, hasUnlistenedContent ? 12 : 14)
            .background(
                Capsule()
                    .fill(hasUnlistenedContent ? Color.clear : theme.accentColor)
            )
        }.buttonStyle(.glassProminent).tint(theme.accentColor.opacity(0.2))
        .padding(.bottom, 24)
    }

    private var buttonText: String {
        if hasUnlistenedContent {
            return "Record when ready"
        } else {
            return "Capture a Memory"
        }
    }
}

// MARK: - Dashboard Skeleton

struct DashboardSkeleton: View {
    @Environment(\.theme) var theme

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero skeleton
                VStack(alignment: .leading, spacing: 12) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.secondaryTextColor.opacity(0.1))
                        .frame(height: 24)
                        .frame(maxWidth: 200)

                    VStack(spacing: 8) {
                        ForEach(0..<2) { _ in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(theme.secondaryTextColor.opacity(0.1))
                                    .frame(width: 44, height: 44)
                                VStack(alignment: .leading, spacing: 4) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(theme.secondaryTextColor.opacity(0.1))
                                        .frame(height: 14)
                                        .frame(maxWidth: 180)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(theme.secondaryTextColor.opacity(0.1))
                                        .frame(height: 12)
                                        .frame(maxWidth: 140)
                                }
                                Spacer()
                            }
                        }
                    }
                }
                .padding(theme.screenPadding)

                // Active stories skeleton
                VStack(alignment: .leading, spacing: 12) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.secondaryTextColor.opacity(0.1))
                        .frame(height: 24)
                        .frame(maxWidth: 150)

                    HStack(spacing: 12) {
                        ForEach(0..<2) { _ in
                            RoundedRectangle(cornerRadius: 12)
                                .fill(theme.secondaryTextColor.opacity(0.1))
                                .frame(width: 200, height: 260)
                        }
                    }
                }
                .padding(theme.screenPadding)
            }
        }
        .background(theme.backgroundColor.ignoresSafeArea())
    }
}

// MARK: - Preview

struct HubView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HubView()
                .themed(DarkTheme())
                .previewDisplayName("dark Dashboard")

            HubView()
                .themed(LightTheme())
                .previewDisplayName("light Dashboard")
        }
    }
}
