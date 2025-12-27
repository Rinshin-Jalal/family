//
//  HubView.swift
//  StoryRide
//
//  Living Memory Dashboard - Home screen showing what's alive in the family
//

import SwiftUI

// MARK: - Dashboard Data Models

struct RecentActivity: Identifiable {
    let id = UUID()
    let type: ActivityType
    let title: String
    let subtitle: String
    let timestamp: Date
    let storyId: String?

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
}

struct UnheardVoice: Identifiable {
    let id = UUID()
    let storyteller: String
    let storyTitle: String
    let role: PersonaRole
    let duration: TimeInterval
    let recordedDate: Date
}

// MARK: - Hub View (Dashboard)

struct HubView: View {
    @Environment(\.theme) var theme
    @State private var loadingState: LoadingState<DashboardData> = .loading
    @State private var showCaptureSheet = false
    @State private var selectedCaptureAction: CaptureAction? = nil
    @State private var currentProfile: UserProfile = UserProfile(name: "Leo", role: .teen, avatarEmoji: "🎸")
    @State private var profiles: [UserProfile] = [
        UserProfile(name: "Leo", role: .teen, avatarEmoji: "🎸"),
        UserProfile(name: "Mom", role: .parent, avatarEmoji: "👩"),
        UserProfile(name: "Grandma", role: .elder, avatarEmoji: "👵")
    ]

    var body: some View {
        Group {
            switch theme.role {
            case .teen:
                TeenDashboard(
                    loadingState: loadingState,
                    onShowCapture: { selectedCaptureAction = nil; showCaptureSheet = true },
                    currentProfile: $currentProfile,
                    profiles: profiles
                )
            case .parent:
                ParentDashboard(
                    loadingState: loadingState,
                    onShowCapture: { selectedCaptureAction = nil; showCaptureSheet = true },
                    currentProfile: $currentProfile,
                    profiles: profiles
                )
            case .child:
                ChildDashboard(
                    loadingState: loadingState,
                    onShowCapture: { selectedCaptureAction = nil; showCaptureSheet = true }
                )
            case .elder:
                ElderDashboard(
                    loadingState: loadingState,
                    onShowCapture: { selectedCaptureAction = nil; showCaptureSheet = true }
                )
            }
        }
        .animation(theme.animation, value: theme.role)
        .sheet(isPresented: $showCaptureSheet) {
            CaptureMemorySheet(selectedCaptureAction: $selectedCaptureAction)
        }
        .onAppear {
            loadDashboard()
        }
    }

    private func loadDashboard() {
        loadingState = .loading

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            let data = DashboardData.mock
            loadingState = .loaded(data)
        }
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
                subtitle: "about 'The Summer of 1968'",
                timestamp: Date().addingTimeInterval(-86400),
                storyId: "story-1"
            ),
            RecentActivity(
                type: .newPerspective,
                title: "A new perspective was added",
                subtitle: "to 'Our First Home' by Mom",
                timestamp: Date().addingTimeInterval(-172800),
                storyId: "story-2"
            ),
            RecentActivity(
                type: .upcomingCall,
                title: "Next call with Grandma",
                subtitle: "Tomorrow, 6 PM",
                timestamp: Date().addingTimeInterval(82800),
                storyId: nil
            )
        ],
        activeStories: Story.sampleStories.map { story in
            ActiveStory(
                story: story,
                lastActivity: story.timestamp,
                isEvolving: story.voiceCount > 2
            )
        }.prefix(3).map { $0 },
        unheardVoices: [
            UnheardVoice(
                storyteller: "Grandma Rose",
                storyTitle: "When I Met Your Grandfather",
                role: .elder,
                duration: 180,
                recordedDate: Date().addingTimeInterval(-432000)
            ),
            UnheardVoice(
                storyteller: "Dad",
                storyTitle: "My First Day at School",
                role: .parent,
                duration: 120,
                recordedDate: Date().addingTimeInterval(-259200)
            )
        ],
        totalVoices: 23,
        totalStories: 12
    )
}

// MARK: - Teen Dashboard

struct TeenDashboard: View {
    let loadingState: LoadingState<DashboardData>
    let onShowCapture: () -> Void
    @Binding var currentProfile: UserProfile
    let profiles: [UserProfile]
    @Environment(\.theme) var theme

    var body: some View {
        NavigationStack {
            Group {
                switch loadingState {
                case .loading:
                    DashboardSkeleton()

                case .empty:
                    TeenEmptyState(onCreateStory: onShowCapture)

                case .loaded(let data):
                    TeenDashboardContent(data: data, onShowCapture: onShowCapture)

                case .error(let message):
                    ErrorStateView(message: message, onRetry: {})
                }
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationTitle("Memory Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ProfileSwitcher(currentProfile: $currentProfile, profiles: profiles)
                }
            }
        }
    }
}

struct TeenDashboardContent: View {
    let data: DashboardData
    let onShowCapture: () -> Void
    @Environment(\.theme) var theme

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // MARK: - Hero Section: What's New
                HeroSection(activities: data.recentActivities.prefix(2).map { $0 })

                // MARK: - Active Stories (Horizontal Scroll)
                ActiveStoriesSection(stories: data.activeStories)

                // MARK: - Unheard Voices
                if !data.unheardVoices.isEmpty {
                    UnheardVoicesSection(voices: data.unheardVoices)
                        .padding(.top, 24)
                }

                // MARK: - Floating Action Button
                Spacer()
                    .frame(height: 100)
            }
            .padding(theme.screenPadding)
        }
        .overlay(alignment: .bottom) {
            CaptureMemoryButton(action: onShowCapture)
        }
    }
}

// MARK: - Parent Dashboard

struct ParentDashboard: View {
    let loadingState: LoadingState<DashboardData>
    let onShowCapture: () -> Void
    @Binding var currentProfile: UserProfile
    let profiles: [UserProfile]
    @Environment(\.theme) var theme

    var body: some View {
        NavigationStack {
            Group {
                switch loadingState {
                case .loading:
                    DashboardSkeleton()

                case .empty:
                    ParentEmptyState(onCreateStory: onShowCapture, onInviteFamily: {})

                case .loaded(let data):
                    ParentDashboardContent(data: data, onShowCapture: onShowCapture)

                case .error(let message):
                    ErrorStateView(message: message, onRetry: {})
                }
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationTitle("Family Memories")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ProfileSwitcher(currentProfile: $currentProfile, profiles: profiles)
                }
            }
        }
    }
}

struct ParentDashboardContent: View {
    let data: DashboardData
    let onShowCapture: () -> Void
    @Environment(\.theme) var theme

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Hero Section: What's New
                HeroSection(activities: data.recentActivities.prefix(2).map { $0 })

                // MARK: - Stats Row (Calm overview)
                StatsRow(totalVoices: data.totalVoices, totalStories: data.totalStories)

                // MARK: - Active Stories (Grid for Parents)
                ActiveStoriesGrid(stories: data.activeStories)

                // MARK: - Unheard Voices (Cards for Parents)
                if !data.unheardVoices.isEmpty {
                    UnheardVoicesSection(voices: data.unheardVoices)
                }

                // MARK: - Bottom padding for FAB
                Color.clear.frame(height: 100)
            }
            .padding(theme.screenPadding)
        }
        .overlay(alignment: .bottom) {
            CaptureMemoryButton(action: onShowCapture)
        }
    }
}

// MARK: - Child Dashboard

struct ChildDashboard: View {
    let loadingState: LoadingState<DashboardData>
    let onShowCapture: () -> Void
    @Environment(\.theme) var theme

    var body: some View {
        Group {
            switch loadingState {
            case .loading:
                ChildCardSkeleton()

            case .empty:
                ChildEmptyState(onRecordStory: onShowCapture)

            case .loaded(let data):
                ChildDashboardContent(data: data, onShowCapture: onShowCapture)

            case .error(let message):
                ErrorStateView(message: message, onRetry: {})
            }
        }
        .background(theme.backgroundColor.ignoresSafeArea())
        .safeAreaInset(edge: .top, alignment: .trailing) {
            Button(action: onShowCapture) {
                ZStack {
                    Circle()
                        .fill(theme.accentColor)
                        .frame(width: 70, height: 70)
                        .shadow(color: theme.accentColor.opacity(0.4), radius: 10)

                    Image(systemName: "plus")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(.trailing, 20)
            .padding(.top, 8)
        }
    }
}

struct ChildDashboardContent: View {
    let data: DashboardData
    let onShowCapture: () -> Void
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // MARK: - Hero: "What's New" (Giant, playful)
            ChildHeroSection(activities: data.recentActivities)

            // MARK: - Unheard Voices (Giant cards for kids)
            if !data.unheardVoices.isEmpty {
                ChildUnheardSection(voices: data.unheardVoices)
            }

            Spacer()
        }
    }
}

// MARK: - Elder Dashboard

struct ElderDashboard: View {
    let loadingState: LoadingState<DashboardData>
    let onShowCapture: () -> Void
    @Environment(\.theme) var theme

    var body: some View {
        Group {
            switch loadingState {
            case .loading:
                ElderSkeleton()

            case .empty:
                ElderEmptyState(onCallMe: onShowCapture)

            case .loaded(let data):
                ElderDashboardContent(data: data, onShowCapture: onShowCapture)

            case .error(let message):
                ErrorStateView(message: message, onRetry: {})
            }
        }
        .background(theme.backgroundColor.ignoresSafeArea())
    }
}

struct ElderDashboardContent: View {
    let data: DashboardData
    let onShowCapture: () -> Void
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // MARK: - Hero: What's New (Very large, clear)
            ElderHeroSection(activities: data.recentActivities.prefix(1).map { $0 })

            // MARK: - Upcoming Call (Primary action)
            if let upcoming = data.recentActivities.first(where: { $0.type == .upcomingCall }) {
                ElderUpcomingCallSection(activity: upcoming)
            }

            Spacer()

            // MARK: - Giant Record Button
            Button(action: onShowCapture) {
                HStack(spacing: 16) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 32))

                    Text("Record a Memory")
                        .font(.system(size: 22, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 90)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(theme.accentColor)
                )
                .shadow(color: theme.accentColor.opacity(0.3), radius: 15)
            }
            .padding(.horizontal, theme.screenPadding)
            .padding(.bottom, 60)
        }
    }
}

// MARK: - Hero Section (What's New)

struct HeroSection: View {
    let activities: [RecentActivity]
    @Environment(\.theme) var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What's New in Our Family")
                .font(theme.headlineFont)
                .foregroundColor(theme.textColor)
                .padding(.bottom, 4)

            VStack(spacing: 8) {
                ForEach(activities) { activity in
                    ActivityCard(activity: activity, theme: theme)
                }
            }
        }
        .padding(.bottom, 24)
    }
}

struct ActivityCard: View {
    let activity: RecentActivity
    let theme: PersonaTheme

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 44, height: 44)

                Text(icon)
                    .font(.system(size: 20))
            }

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(theme.textColor)

                Text(activity.subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(theme.secondaryTextColor)
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.cardBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    private var icon: String {
        switch activity.type {
        case .newStory: return "🎙️"
        case .newPerspective: return "🧵"
        case .upcomingCall: return "📞"
        }
    }

    private var backgroundColor: Color {
        switch activity.type {
        case .newStory: return .storytellerPurple.opacity(0.15)
        case .newPerspective: return .storytellerBlue.opacity(0.15)
        case .upcomingCall: return .storytellerOrange.opacity(0.15)
        }
    }

    private var borderColor: Color {
        switch activity.type {
        case .newStory: return .storytellerPurple.opacity(0.3)
        case .newPerspective: return .storytellerBlue.opacity(0.3)
        case .upcomingCall: return .storytellerOrange.opacity(0.3)
        }
    }
}

// MARK: - Active Stories Section

struct ActiveStoriesSection: View {
    let stories: [ActiveStory]
    @Environment(\.theme) var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active Stories")
                    .font(theme.headlineFont)
                    .foregroundColor(theme.textColor)

                Spacer()

                Text("\(stories.count) evolving")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(stories, id: \.story.id) { activeStory in
                        NavigationLink(destination: StoryDetailView(story: activeStory.story)) {
                            ActiveStoryCard(story: activeStory, theme: theme)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(.bottom, 24)
    }
}

struct ActiveStoryCard: View {
    let story: ActiveStory
    let theme: PersonaTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Visual indicator
            ZStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                story.story.storytellerColor.opacity(0.4),
                                story.story.storytellerColor.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 120)
                    .frame(width: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                // Evolving indicator
                if story.isEvolving {
                    VStack {
                        Spacer()
                        HStack {
                            Circle()
                                .fill(Color.white.opacity(0.9))
                                .frame(width: 6, height: 6)
                            Text("Evolving")
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.2))
                                )
                            Spacer()
                        }
                        .padding(8)
                    }
                }
            }

            // Story info
            VStack(alignment: .leading, spacing: 4) {
                Text(story.story.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(theme.textColor)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Text(story.story.storyteller)
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)

                    Text("·")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor.opacity(0.5))

                    Text("\(story.story.voiceCount) perspectives")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
            }
        }
        .frame(width: 200)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.cardBackgroundColor)
        )
        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
    }
}

// MARK: - Active Stories Grid (Parent)

struct ActiveStoriesGrid: View {
    let stories: [ActiveStory]
    @Environment(\.theme) var theme

    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Stories")
                .font(theme.headlineFont)
                .foregroundColor(theme.textColor)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(stories, id: \.story.id) { activeStory in
                    NavigationLink(destination: StoryDetailView(story: activeStory.story)) {
                        ParentActiveStoryCard(story: activeStory, theme: theme)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct ParentActiveStoryCard: View {
    let story: ActiveStory
    let theme: PersonaTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            ZStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                story.story.storytellerColor.opacity(0.3),
                                story.story.storytellerColor.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 140)

                // Voice count
                if story.story.voiceCount > 1 {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption2)
                        Text("\(story.story.voiceCount)")
                            .font(.caption2.bold())
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.5))
                    )
                    .padding(8)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(story.story.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.textColor)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Circle()
                        .fill(story.story.storytellerColor)
                        .frame(width: 6, height: 6)

                    Text(story.story.storyteller)
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
            }
            .padding(10)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }
}

// MARK: - Unheard Voices Section

struct UnheardVoicesSection: View {
    let voices: [UnheardVoice]
    @Environment(\.theme) var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Voices You Haven't Heard Yet")
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
        HStack(spacing: 12) {
            // Avatar circle
            ZStack {
                Circle()
                    .fill(storytellerColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .stroke(storytellerColor, lineWidth: 2)
                    )
                    .overlay {
                        Text(String(voice.storyteller.prefix(1)).uppercased())
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(storytellerColor)
                    }
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text("1 new memory from \(voice.storyteller)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.textColor)

                Text(voice.storyTitle)
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
                    .lineLimit(1)
            }

            Spacer()

            // Duration
            HStack(spacing: 4) {
                Image(systemName: "play.circle.fill")
                    .font(.caption)
                Text("\(Int(voice.duration / 60))m")
                    .font(.caption)
            }
            .foregroundColor(theme.accentColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(theme.accentColor.opacity(0.1))
            )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.cardBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.accentColor.opacity(0.2), lineWidth: 1)
        )
    }

    private var storytellerColor: Color {
        switch voice.role {
        case .elder: return .storytellerOrange
        case .parent: return .storytellerBlue
        case .teen: return .storytellerPurple
        case .child: return .storytellerGreen
        }
    }
}

// MARK: - Stats Row (Parent)

struct StatsRow: View {
    let totalVoices: Int
    let totalStories: Int
    @Environment(\.theme) var theme

    var body: some View {
        HStack(spacing: 12) {
            DashboardStatCard(
                title: "\(totalVoices)",
                subtitle: "Voices",
                color: .storytellerBlue
            )

            DashboardStatCard(
                title: "\(totalStories)",
                subtitle: "Stories",
                color: .storytellerPurple
            )
        }
    }
}

struct DashboardStatCard: View {
    let title: String
    let subtitle: String
    let color: Color
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(color)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(theme.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.cardBackgroundColor)
        )
    }
}

// MARK: - Child-Specific Sections

struct ChildHeroSection: View {
    let activities: [RecentActivity]
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 16) {
            Text("What's New!")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(theme.textColor)

            if let activity = activities.first {
                HStack(spacing: 12) {
                    Text(activity.type == .newStory ? "🎙️" : activity.type == .newPerspective ? "🧵" : "📞")
                        .font(.system(size: 60))

                    VStack(alignment: .leading, spacing: 8) {
                        Text(activity.title)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(theme.textColor)

                        Text(activity.subtitle)
                            .font(.system(size: 18))
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(theme.cardBackgroundColor)
                )
                .shadow(color: .black.opacity(0.1), radius: 12)
            }
        }
        .padding(.top, theme.screenPadding)
    }
}

struct ChildUnheardSection: View {
    let voices: [UnheardVoice]
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 16) {
            Text("New Stories to Listen!")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(theme.textColor)

            ForEach(voices.prefix(2)) { voice in
                ChildUnheardCard(voice: voice)
            }
        }
    }
}

struct ChildUnheardCard: View {
    let voice: UnheardVoice
    @Environment(\.theme) var theme

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(storytellerColor.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay {
                        Text(String(voice.storyteller.prefix(1)).uppercased())
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(storytellerColor)
                    }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(voice.storyteller)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(theme.textColor)

                Text(voice.storyTitle)
                    .font(.system(size: 16))
                    .foregroundColor(theme.secondaryTextColor)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "play.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(theme.accentColor)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(theme.cardBackgroundColor)
        )
        .shadow(color: .black.opacity(0.08), radius: 8)
    }

    private var storytellerColor: Color {
        switch voice.role {
        case .elder: return .storytellerOrange
        case .parent: return .storytellerBlue
        case .teen: return .storytellerPurple
        case .child: return .storytellerGreen
        }
    }
}

// MARK: - Elder-Specific Sections

struct ElderHeroSection: View {
    let activities: [RecentActivity]
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 24) {
            Text("What's New")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(theme.textColor)

            if let activity = activities.first {
                VStack(spacing: 16) {
                    Text(activity.type == .newStory ? "🎙️" : activity.type == .newPerspective ? "🧵" : "📞")
                        .font(.system(size: 80))

                    Text(activity.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(theme.textColor)
                        .multilineTextAlignment(.center)

                    Text(activity.subtitle)
                        .font(.system(size: 22))
                        .foregroundColor(theme.secondaryTextColor)
                }
                .padding(32)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(theme.cardBackgroundColor)
                )
            }
        }
        .padding(.horizontal, theme.screenPadding)
    }
}

struct ElderUpcomingCallSection: View {
    let activity: RecentActivity
    @Environment(\.theme) var theme

    var body: some View {
        HStack(spacing: 20) {
            Circle()
                .fill(Color.storytellerOrange.opacity(0.15))
                .frame(width: 80, height: 80)
                .overlay {
                    Text("📞")
                        .font(.system(size: 40))
                }

            VStack(alignment: .leading, spacing: 8) {
                Text("Upcoming Call")
                    .font(.system(size: 18))
                    .foregroundColor(theme.secondaryTextColor)

                Text(activity.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(theme.textColor)

                Text(activity.subtitle)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(theme.accentColor)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.cardBackgroundColor)
        )
        .padding(.horizontal, theme.screenPadding)
    }
}

// MARK: - Capture Memory Button

struct CaptureMemoryButton: View {
    let action: () -> Void
    @Environment(\.theme) var theme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))

                Text("Capture a Memory")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(theme.accentColor)
            )
            .shadow(color: theme.accentColor.opacity(0.3), radius: 10, y: 4)
        }
        .padding(.bottom, 24)
    }
}

// MARK: - Capture Memory Sheet

enum CaptureAction {
    case record          // 🎙️ Add a prompt
    case suggest         // 💡 Suggest a prompt to AI
    case triggerCall     // 📞 Trigger a call
}

struct CaptureMemorySheet: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    @Binding var selectedCaptureAction: CaptureAction?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Capture a Memory")
                        .font(theme.headlineFont)
                        .foregroundColor(theme.textColor)

                    Text("Choose how you'd like to add to your family's story")
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                .padding(.bottom, 24)

                Divider()

                // Actions
                VStack(spacing: 0) {
                    CaptureActionRow(
                        icon: "🎙️",
                        title: "Add a Prompt",
                        subtitle: "Record your story in your own words",
                        color: .storytellerPurple
                    ) {
                        selectedCaptureAction = .record
                        dismiss()
                    }

                    Divider()
                        .padding(.leading, 60)

                    CaptureActionRow(
                        icon: "💡",
                        title: "Suggest a Prompt",
                        subtitle: "Let AI help you remember",
                        color: .storytellerBlue
                    ) {
                        selectedCaptureAction = .suggest
                        dismiss()
                    }

                    Divider()
                        .padding(.leading, 60)

                    CaptureActionRow(
                        icon: "📞",
                        title: "Trigger a Call",
                        subtitle: "Schedule a conversation",
                        color: .storytellerOrange
                    ) {
                        selectedCaptureAction = .triggerCall
                        dismiss()
                    }
                }

                Spacer()

                // Cancel
                Button("Cancel") {
                    dismiss()
                }
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(theme.accentColor)
                .padding(.bottom, 24)
            }
            .background(theme.backgroundColor)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.accentColor)
                }
            }
        }
        .presentationDetents([.height(460)])
        .presentationDragIndicator(.visible)
    }
}

struct CaptureActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(icon)
                    .font(.system(size: 32))
                    .frame(width: 50)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.gray.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
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
                .themed(TeenTheme())
                .previewDisplayName("Teen Dashboard")

            HubView()
                .themed(ParentTheme())
                .previewDisplayName("Parent Dashboard")

            HubView()
                .themed(ChildTheme())
                .previewDisplayName("Child Dashboard")

            HubView()
                .themed(ElderTheme())
                .previewDisplayName("Elder Dashboard")
        }
    }
}
