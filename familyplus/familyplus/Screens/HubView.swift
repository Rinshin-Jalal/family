//
//  HubView.swift
//  StoryRide
//
//  Living Memory Dashboard - Home screen showing what's alive in the family
//  Redesigned following Apple HIG: clarity, deference, depth
//

import SwiftUI

// MARK: - Dashboard Data Models

struct DailyPrompt: Identifiable, Codable {
    let id: String
    let question: String
    let category: PromptCategory
    let icon: String
    let validUntil: Date
    let responseCount: Int?

    enum PromptCategory: String, Codable {
        case memory = "Memory"
        case tradition = "Tradition"
        case milestone = "Milestone"
        case wisdom = "Wisdom"
        case fun = "Fun"

        var color: Color {
            switch self {
            case .memory: return .blue
            case .tradition: return .orange
            case .milestone: return .purple
            case .wisdom: return .teal
            case .fun: return .yellow
            }
        }
    }
}

struct RecentActivity: Identifiable {
    let id = UUID()
    let type: ActivityType
    let title: String
    let subtitle: String
    let timestamp: Date
    let storyId: String?
    let duration: TimeInterval?
    let hasListened: Bool

    enum ActivityType {
        case newStory
        case newPerspective
        case upcomingCall

        var icon: String {
            switch self {
            case .newStory: return "waveform"
            case .newPerspective: return "bubble.left.and.bubble.right"
            case .upcomingCall: return "phone"
            }
        }

        var color: Color {
            switch self {
            case .newStory: return .orange
            case .newPerspective: return .blue
            case .upcomingCall: return .purple
            }
        }
    }

    var timeAgoText: String {
        let now = Date()
        let interval = now.timeIntervalSince(timestamp)

        if interval < 0 {
            let futureInterval = -interval
            if futureInterval < 3600 {
                return "In \(Int(futureInterval / 60))m"
            } else if futureInterval < 86400 {
                return "In \(Int(futureInterval / 3600))h"
            } else if futureInterval < 172800 {
                return "Tomorrow"
            } else {
                return "In \(Int(futureInterval / 86400))d"
            }
        }

        if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h ago"
        } else if interval < 172800 {
            return "Yesterday"
        } else {
            return "\(Int(interval / 86400))d ago"
        }
    }

    var formattedDuration: String? {
        guard let duration = duration else { return nil }
        let minutes = Int(duration / 60)
        if minutes == 0 {
            return "\(Int(duration))s"
        }
        return "\(minutes) min"
    }
}

struct ActiveStory: Identifiable {
    let id = UUID()
    let story: Story
    let lastActivity: Date
    let isEvolving: Bool
    let emotionalHint: String?
    let freshnessText: String?
}

struct UnheardVoice: Identifiable {
    let id = UUID()
    let storyteller: String
    let storyTitle: String
    let role: AppTheme
    let duration: TimeInterval
    let recordedDate: Date

    var formattedDuration: String {
        let minutes = Int(duration / 60)
        return "\(minutes) min"
    }
}

// MARK: - Hub View (Dashboard)

struct HubView: View {
    @Environment(\.theme) var theme
    @Environment(\.colorScheme) var colorScheme
    @State private var loadingState: LoadingState<DashboardData> = .loading
    @State private var showCaptureSheet = false
    @State private var showCreateStoryModal = false
    @State private var dailyPrompt: DailyPrompt?
    @State private var selectedPromptForCapture: PromptData?

    var body: some View {
        UnifiedDashboard(
            loadingState: loadingState,
            onShowCapture: { prompt in
                selectedPromptForCapture = prompt
                showCaptureSheet = true
            },
            onShowCreateStory: {
                showCreateStoryModal = true
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
        .sheet(isPresented: $showCreateStoryModal) {
            CreateStoryModal()
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
                duration: 180,
                hasListened: false
            ),
            RecentActivity(
                type: .newPerspective,
                title: "A new perspective was added",
                subtitle: "to 'Our First Home' by Mom",
                timestamp: Date().addingTimeInterval(-172800),
                storyId: "story-2",
                duration: 120,
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
                lastActivity: Date().addingTimeInterval(-259200),
                isEvolving: true,
                emotionalHint: "Remembered very differently by each person",
                freshnessText: "New perspective 3 days ago"
            ),
            ActiveStory(
                story: Story.sampleStories[1],
                lastActivity: Date().addingTimeInterval(-604800),
                isEvolving: false,
                emotionalHint: "A joyful memory for everyone",
                freshnessText: "Last updated 1 week ago"
            ),
            ActiveStory(
                story: Story.sampleStories[2],
                lastActivity: Date().addingTimeInterval(-1209600),
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

// MARK: - Unified Dashboard (Apple HIG Compliant)

struct UnifiedDashboard: View {
    let loadingState: LoadingState<DashboardData>
    let onShowCapture: (PromptData?) -> Void
    let onShowCreateStory: () -> Void
    let dailyPrompt: DailyPrompt?
    @Environment(\.theme) var theme
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            Group {
                switch loadingState {
                case .loading:
                    DashboardSkeleton()
                case .empty:
                    UnifiedEmptyState(onCreateStory: { onShowCapture(nil) })
                case .loaded(let data):
                    DashboardContent(
                        data: data,
                        onShowCapture: onShowCapture,
                        onShowCreateStory: onShowCreateStory,
                        dailyPrompt: dailyPrompt
                    )
                case .error(let message):
                    ErrorStateView(message: message, onRetry: {})
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Dashboard Content

struct DashboardContent: View {
    let data: DashboardData
    let onShowCapture: (PromptData?) -> Void
    let onShowCreateStory: () -> Void
    let dailyPrompt: DailyPrompt?
    @Environment(\.theme) var theme
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        List {
            // Daily Prompt Section
            if let prompt = dailyPrompt {
                Section {
                    PromptHeroCard(prompt: prompt, onTap: onShowCreateStory)
                } header: {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text("Today's Question")
                    }
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                }
            }

            // Recent Activity Section
            Section {
                ForEach(data.recentActivities) { activity in
                    NavigationLink(destination: storyDetail(for: activity)) {
                        ActivityRow(activity: activity)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Recent Activity")
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }

            // Stories Section
            Section {
                ForEach(data.activeStories) { activeStory in
                    NavigationLink(destination: StoryDetailView(story: activeStory.story)) {
                        StoryCardRow(story: activeStory)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Stories")
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }

            // Unheard Voices Section
            if !data.unheardVoices.isEmpty {
                Section {
                    ForEach(data.unheardVoices) { voice in
                        NavigationLink(destination: Text("Story Player")) {
                            VoiceRow(voice: voice)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    HStack {
                        Text("Unheard Voices")
                        Spacer()
                        Text("\(data.unheardVoices.count)")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                }
            }

            // Stats Summary
            Section {
                HStack(spacing: 32) {
                    DashboardStatItem(value: "\(data.totalStories)", label: "Stories")
                    DashboardStatItem(value: "\(data.totalVoices)", label: "Voices")
                }
                .padding(.vertical, 8)
            } header: {
                Text("Your Family")
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private func storyDetail(for activity: RecentActivity) -> some View {
        if let storyId = activity.storyId,
           let story = Story.sampleStories.first(where: { $0.id.uuidString == storyId }) {
            return AnyView(StoryDetailView(story: story))
        }
        return AnyView(Text("Story detail"))
    }
}

// MARK: - Activity Row

struct ActivityRow: View {
    let activity: RecentActivity

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(activity.type.color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: activity.type.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(activity.type.color)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.body)
                    .foregroundColor(Color(UIColor.label))

                HStack(spacing: 8) {
                    Text(activity.subtitle)
                        .font(.footnote)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .lineLimit(1)

                    if let duration = activity.formattedDuration {
                        Text("·")
                            .font(.footnote)
                            .foregroundColor(Color(UIColor.tertiaryLabel))

                        Text(duration)
                            .font(.footnote)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }

                    Text("·")
                        .font(.footnote)
                        .foregroundColor(Color(UIColor.tertiaryLabel))

                    Text(activity.timeAgoText)
                        .font(.footnote)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
            }

            Spacer()
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

// MARK: - Story Card Row

struct StoryCardRow: View {
    let story: ActiveStory
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(storyColor)
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "waveform")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(story.story.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(UIColor.label))
                    .lineLimit(1)

                Text(story.story.storyteller)
                    .font(.caption)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .lineLimit(1)
            }

            Spacer()

            if story.isEvolving {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
            }

            if story.story.voiceCount > 1 {
                HStack(spacing: 3) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 10))
                    Text("\(story.story.voiceCount)")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.15))
                .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private var storyColor: Color {
        .storytellerPurple
    }
}

// MARK: - Voice Row

struct VoiceRow: View {
    let voice: UnheardVoice

    var body: some View {
        HStack(spacing: 16) {
            // Avatar initial
            Text(String(voice.storyteller.prefix(1)).uppercased())
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Circle().fill(storytellerColor))

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(voice.storyTitle)
                    .font(.body)
                    .foregroundColor(Color(UIColor.label))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(voice.storyteller)
                        .font(.footnote)
                        .foregroundColor(storytellerColor)

                    Text("·")
                        .foregroundColor(Color(UIColor.tertiaryLabel))

                    Text(voice.formattedDuration)
                        .font(.footnote)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
            }

            Spacer()

            Circle()
                .fill(Color.blue)
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private var storytellerColor: Color {
        switch voice.role {
        case .light: return .storytellerBlue
        case .dark: return .storytellerPurple
        }
    }
}

// MARK: - Dashboard Stat Item

struct DashboardStatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color(UIColor.label))

            Text(label)
                .font(.caption)
                .foregroundColor(Color(UIColor.secondaryLabel))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Prompt Hero Card

struct PromptHeroCard: View {
    let prompt: DailyPrompt
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: prompt.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(prompt.category.color)

                    Text(prompt.category.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(prompt.category.color)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }

                Text(prompt.question)
                    .font(.headline)
                    .foregroundColor(Color(UIColor.label))
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)

                Text("Tap to share your story")
                    .font(.caption)
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(
                        color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 8)
    }
}

// MARK: - Unified Empty State

struct UnifiedEmptyState: View {
    let onCreateStory: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            VStack(spacing: 12) {
                Text("No Stories Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor.label))

                Text("Start capturing your family memories")
                    .font(.body)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .multilineTextAlignment(.center)
            }

            Button(action: onCreateStory) {
                Text("Record Your First Story")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .padding(32)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

// MARK: - Dashboard Skeleton

struct DashboardSkeleton: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            List {
                // Prompt skeleton
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Circle()
                                .fill(Color(.tertiaryLabel).opacity(0.3))
                                .frame(width: 20, height: 20)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.tertiaryLabel).opacity(0.3))
                                .frame(width: 60, height: 12)

                            Spacer()

                            Circle()
                                .fill(Color(.tertiaryLabel).opacity(0.3))
                                .frame(width: 14, height: 14)
                        }

                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.tertiaryLabel).opacity(0.3))
                            .frame(height: 24)
                            .frame(maxWidth: .infinity)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.tertiaryLabel).opacity(0.3))
                            .frame(width: 150, height: 12)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Today's Question")
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }

                // Activity skeleton
                Section {
                    ForEach(0..<3, id: \.self) { _ in
                        HStack(spacing: 16) {
                            Circle()
                                .fill(Color(.tertiaryLabel).opacity(0.3))
                                .frame(width: 40, height: 40)

                            VStack(alignment: .leading, spacing: 8) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.tertiaryLabel).opacity(0.3))
                                    .frame(width: 180, height: 16)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.tertiaryLabel).opacity(0.3))
                                    .frame(width: 120, height: 12)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("Recent Activity")
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }

                // Stories skeleton
                Section {
                    ForEach(0..<2, id: \.self) { _ in
                        HStack(spacing: 16) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.tertiaryLabel).opacity(0.3))
                                .frame(width: 48, height: 48)

                            VStack(alignment: .leading, spacing: 8) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.tertiaryLabel).opacity(0.3))
                                    .frame(width: 160, height: 16)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.tertiaryLabel).opacity(0.3))
                                    .frame(width: 100, height: 12)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("Stories")
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
    }
}

// MARK: - Create Story Modal

struct CreateStoryModal: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedPrompt: String?
    @State private var customPrompt = ""
    @State private var storyText = ""
    @State private var isRecording = false
    @State private var inputMethod: InputMethod = .text
    @State private var showStoryView = false

    enum InputMethod: String, CaseIterable {
        case text = "Text"
        case voice = "Voice"
    }

    // Sample prompts for story creation
    let samplePrompts = [
        "What's your earliest memory?",
        "Tell me about a family tradition that matters to you.",
        "What was the happiest day of your life?",
        "What's a lesson you've learned that you want to pass on?",
        "Describe your childhood home.",
        "What's a story your parents or grandparents told you?",
        "Tell me about a challenge you overcame.",
        "What was life like when you were young?"
    ]

    var canProceed: Bool {
        if selectedPrompt != nil {
            return true
        }
        return !customPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Group {
            if showStoryView {
                StoryCreationView(
                    prompt: selectedPrompt ?? customPrompt,
                    storyText: $storyText,
                    isRecording: $isRecording,
                    inputMethod: $inputMethod,
                    onBack: {
                        showStoryView = false
                        selectedPrompt = nil
                        customPrompt = ""
                    },
                    onSubmit: submitStory
                )
            } else {
                PromptSelectionView(
                    prompts: samplePrompts,
                    selectedPrompt: $selectedPrompt,
                    customPrompt: $customPrompt,
                    onContinue: {
                        showStoryView = true
                    },
                    canProceed: canProceed
                )
            }
        }
        .background(Color(uiColor: .systemBackground))
    }

    func submitStory() {
        print("Creating story with prompt: \(selectedPrompt ?? customPrompt)")
        print("Method: \(inputMethod.rawValue)")
        print("Content: \(storyText)")
        dismiss()
    }

    // MARK: - Prompt Selection View

    struct PromptSelectionView: View {
        let prompts: [String]
        @Binding var selectedPrompt: String?
        @Binding var customPrompt: String
        let onContinue: () -> Void
        let canProceed: Bool

        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Create a Story")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Choose a prompt or write your own to get started")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)

                        // Prompts section
                        Text("Choose a Prompt")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            ForEach(prompts, id: \.self) { prompt in
                                PromptButton(
                                    prompt: prompt,
                                    isSelected: selectedPrompt == prompt,
                                    onSelect: {
                                        selectedPrompt = prompt
                                        customPrompt = ""
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)

                        // Custom prompt section
                        HStack {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.3))
                                .frame(height: 1)
                            Text("or write your own")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Rectangle()
                                .fill(Color.secondary.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.horizontal)

                        // Custom prompt input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Prompt")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            TextEditor(text: $customPrompt)
                                .frame(minHeight: 80)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                                .onTapGesture {
                                    selectedPrompt = nil
                                }

                            Text("Write your own story prompt")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)

                        Spacer(minLength: 100)
                    }
                }
                .navigationTitle("New Story")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: onContinue) {
                            Text("Continue")
                                .fontWeight(.semibold)
                        }
                        .disabled(!canProceed)
                    }
                }
            }
        }
    }

    // MARK: - Prompt Button

    struct PromptButton: View {
        let prompt: String
        let isSelected: Bool
        let onSelect: () -> Void

        var body: some View {
            Button(action: onSelect) {
                HStack(spacing: 12) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? .blue : .secondary)

                    Text(prompt)
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)

                    Spacer()
                }
                .padding()
                .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Story Creation View

    struct StoryCreationView: View {
        let prompt: String
        @Binding var storyText: String
        @Binding var isRecording: Bool
        @Binding var inputMethod: InputMethod
        let onBack: () -> Void
        let onSubmit: () -> Void

        var canSubmit: Bool {
            switch inputMethod {
            case .text:
                return !storyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            case .voice:
                return isRecording
            }
        }

        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Prompt context
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Prompt")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)

                            Text(prompt)
                                .font(.title3)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)

                        Divider()
                            .padding(.horizontal)

                        // Input method picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How would you like to tell your story?")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Picker("Input Method", selection: $inputMethod) {
                                ForEach(InputMethod.allCases, id: \.self) { method in
                                    Text(method.rawValue).tag(method)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(.horizontal)

                        // Input area based on method
                        Group {
                            if inputMethod == .text {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Your Story")
                                        .font(.subheadline)
                                        .fontWeight(.medium)

                                    TextEditor(text: $storyText)
                                        .frame(minHeight: 200)
                                        .padding(12)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(.systemGray4), lineWidth: 1)
                                        )

                                    HStack {
                                        Spacer()
                                        Text("\(storyText.count) characters")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            } else {
                                VStack(spacing: 20) {
                                    Image(systemName: isRecording ? "waveform" : "mic.fill")
                                        .font(.system(size: 64))
                                        .foregroundColor(isRecording ? .red : .blue)
                                        .symbolEffect(.pulse, isActive: isRecording)

                                    Text(isRecording ? "Recording your story..." : "Tap to record")
                                        .font(.headline)

                                    Text("Tell your story naturally")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)

                                    Button(action: {
                                        isRecording.toggle()
                                    }) {
                                        Text(isRecording ? "Stop Recording" : "Start Recording")
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 16)
                                            .background(isRecording ? Color.red : Color.blue)
                                            .cornerRadius(12)
                                    }
                                    .disabled(false)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)

                        Spacer(minLength: 100)
                    }
                }
                .navigationTitle("Tell Your Story")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: onBack) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: onSubmit) {
                            Text("Save Story")
                                .fontWeight(.semibold)
                        }
                        .disabled(!canSubmit)
                    }
                }
            }
        }
    }
}

// MARK: - Story Bubble Card

struct StoryBubbleCard: View {
    let story: Story
    let isSelected: Bool
    let textColor: Color
    let accentColor: Color

    var body: some View {
        VStack(spacing: 8) {
            // Bubble indicator
            ZStack {
                Circle()
                    .fill(isSelected ? accentColor : Color.clear)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? accentColor : Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 16, height: 16)
                    )
                    .offset(y: -30)
            }

            // Story card
            VStack(alignment: .leading, spacing: 6) {
                Text(story.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(textColor)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Text(story.storyteller)
                        .font(.caption2)
                        .foregroundColor(textColor.opacity(0.7))
                }
            }
            .padding(12)
            .frame(width: 140)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isSelected ? 0.2 : 0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Preview

struct HubView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HubView()
                .preferredColorScheme(.light)
                .previewDisplayName("Light Theme")

            HubView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Theme")
        }
    }
}
