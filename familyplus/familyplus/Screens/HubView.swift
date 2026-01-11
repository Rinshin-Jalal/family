//
//  HubView.swift
//  StoryRide
//
//  Family Stories - Where your family's memories live
//

import SwiftUI
import Foundation


// MARK: - Hub Loading State Enum

enum HubLoadingState<T>: Equatable {
    case loading
    case empty
    case loaded(T)
    case error(String)

    static func == (lhs: HubLoadingState<T>, rhs: HubLoadingState<T>) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading), (.empty, .empty):
            return true
        case (.loaded, .loaded):
            return true // Simplified for Equatable conformance
        case (.error(let lhsMsg), .error(let rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }
}

// MARK: - Local UI Helpers

struct CozySectionHeader: View {
    let icon: String
    let title: String
    @Environment(\.theme) var theme
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(theme.accentColor)
            
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(theme.secondaryTextColor)
            
            Spacer()
        }
        .padding(.horizontal, theme.screenPadding)
    }
}

struct ViewAllButton: View {
    let title: String
    let action: () -> Void
    @Environment(\.theme) var theme
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(theme.accentColor)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Image(systemName: "chevron.right")
                    Image(systemName: "chevron.left")
                    Image(systemName: "chevron.right")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(theme.accentColor)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
    }
}

struct CozyCard<Content: View>: View {
    @Environment(\.theme) var theme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(theme.role == .light ? Color.white : theme.cardBackgroundColor)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}

struct RoleBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(color.opacity(0.6))
            .foregroundColor(.white)
            .clipShape(Capsule())
    }
}

struct HubView: View {
    @Environment(\.theme) var theme
    @State private var loadingState: HubLoadingState<ArchivistData> = .loading
    @State private var showCaptureSheet = false
    @State private var showSearchView = false
    @State private var selectedInputMode: InputMode? = nil
    @State private var selectedStory: EvolvingStory? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    switch loadingState {
                    case .loading:
                        DashboardSkeletonView()
                    case .loaded(let data):
                        // 1. Quick Action Hero
                        QuickActionHero(onAction: { mode in
                            selectedInputMode = mode
                            showCaptureSheet = true
                        })
                        .padding(.top, 8)

                        DashboardView(data: data, onCaptureAction: {
                            selectedInputMode = .recording
                            showCaptureSheet = true
                        }, onStorySelected: { story in
                            print("🔥 STORY TAPPED: \(story.title) - ID: \(story.id)")
                            selectedStory = story
                            print("🔥 selectedStory set to: \(String(describing: selectedStory))")
                        })
                        .transition(.opacity)
                    case .empty:
                        HubEmptyStateView(onAction: {
                            showCaptureSheet = true
                        })
                    case .error(let message):
                        HubErrorStateView(message: message, onRetry: loadDashboard)
                    }
                }
                .padding(.bottom, 100) // Space for FAB
            }
            .refreshable {
                await refreshDashboard()
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .overlay(alignment: .bottomTrailing) {
                // Floating Action Button
                Button(action: {
                    selectedInputMode = .recording
                    showCaptureSheet = true
                }) {
                    ZStack {
                        Circle()
                            .fill(theme.accentColor)
                            .frame(width: 64, height: 64)
                            .shadow(color: theme.accentColor.opacity(0.3), radius: 12, x: 0, y: 6)

                        Image(systemName: "plus")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.trailing, 24)
                .padding(.bottom, 120)
            }
            .navigationTitle("Family Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSearchView = true
                    } label: {
                        HStack(spacing: 6) {
                            Text("Search")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(theme.accentColor)
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(theme.accentColor)
                                .padding(8)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationDestination(for: EvolvingStory.self) { story in
                StoryDetailView(story: Story(
                    id: story.id,
                    title: story.title,
                    storyteller: story.storyteller,
                    imageURL: nil,
                    voiceCount: story.contributionCount,
                    timestamp: story.lastActivity
                ))
            }
        }
        .sheet(isPresented: $showCaptureSheet) {
            CaptureMemorySheet(initialMode: selectedInputMode ?? .recording)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSearchView) {
            WisdomSearchView()
        }
        .onAppear {
            loadDashboard()
        }
        .onChange(of: showCaptureSheet) { _, isShowing in
            // Reload dashboard when capture sheet is dismissed
            if !isShowing {
                loadDashboard()
            }
        }
    }

    // Async version for pull-to-refresh
    private func refreshDashboard() async {
        print("[HubView] 🔄 Starting refresh...")
        do {
            let stories = try await APIService.shared.getStories()
            print("[HubView] ✅ Fetched \(stories.count) stories")
            
            let family = try await APIService.shared.getFamily()
            print("[HubView] ✅ Fetched family")
            
            let members = try await APIService.shared.getFamilyMembers()
            print("[HubView] ✅ Fetched \(members.count) members")

            let quotesResponse = try? await APIService.shared.getPopularQuoteCards(limit: 10)
            let quotes = quotesResponse?.quotes.map { quote in
                FamilyQuote(
                    id: quote.id,
                    quoteText: quote.quoteText,
                    authorName: quote.authorName,
                    authorRole: quote.authorRole,
                    storyId: quote.storyId,
                    theme: quote.theme,
                    createdAt: Date()
                )
            } ?? []
            print("[HubView] ✅ Fetched \(quotes.count) quotes")

            let topicsResponse = try? await APIService.shared.getDiscussionTopics()
            let discussionTopics = topicsResponse?.topics ?? []
            print("[HubView] ✅ Fetched \(discussionTopics.count) discussion topics")

            let archivistData = ArchivistData(
                stories: stories,
                family: family,
                members: members,
                quotes: quotes,
                discussionTopics: discussionTopics
            )
            print("[HubView] ✅ Created new ArchivistData with \(stories.count) stories")

            await MainActor.run {
                withAnimation(.snappy) {
                    loadingState = .loaded(archivistData)
                    print("[HubView] ✅ Updated loadingState - view should refresh!")
                }
            }
        } catch {
            print("[HubView] ❌ Failed to refresh dashboard: \(error.localizedDescription)")
            // Don't show error on refresh, just keep current data
        }
    }

    private func loadDashboard() {
        loadingState = .loading
        Task {
            do {
                let stories = try await APIService.shared.getStories()
                let family = try await APIService.shared.getFamily()
                let members = try await APIService.shared.getFamilyMembers()

                // Fetch quotes from API
                let quotesResponse = try? await APIService.shared.getPopularQuoteCards(limit: 10)
                let quotes = quotesResponse?.quotes.map { quote in
                    FamilyQuote(
                        id: quote.id,
                        quoteText: quote.quoteText,
                        authorName: quote.authorName,
                        authorRole: quote.authorRole,
                        storyId: quote.storyId,
                        theme: quote.theme,
                        createdAt: Date()
                    )
                } ?? []

                // Fetch AI-generated discussion topics
                let topicsResponse = try? await APIService.shared.getDiscussionTopics()
                let discussionTopics = topicsResponse?.topics ?? []

                let archivistData = ArchivistData(
                    stories: stories,
                    family: family,
                    members: members,
                    quotes: quotes,
                    discussionTopics: discussionTopics
                )

                await MainActor.run {
                    withAnimation(.snappy) {
                        loadingState = .loaded(archivistData)
                    }
                }
            } catch {
                print("[HubView] ❌ Failed to load dashboard: \(error.localizedDescription)")
                await MainActor.run {
                    withAnimation(.snappy) {
                        loadingState = .error(error.localizedDescription)
                    }
                }
            }
        }
    }
}

// MARK: - Subviews

struct QuickActionHero: View {
    @Environment(\.theme) var theme
    var onAction: (InputMode) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What's on your mind?")
                .font(theme.headlineFont)
                .foregroundColor(theme.textColor)
                .padding(.horizontal, theme.screenPadding)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Primary Action: Record
                    Button(action: {
                        onAction(.recording)
                    }) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(theme.accentColor)
                                    .frame(width: 64, height: 64)
                                    .shadow(color: theme.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                                
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                            }
                            
                            Text("Record Voice")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(theme.textColor)
                        }
                        .frame(width: 120)
                        .padding(.vertical, 16)
                        .background(theme.cardBackgroundColor)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(theme.accentColor.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    // Secondary Actions
                    QuickActionButton(icon: "camera", label: "Add Photo", color: theme.accentColor) {
                        onAction(.imageUpload)
                    }
                    QuickActionButton(icon: "text.bubble", label: "Write Story", color: theme.accentColor) {
                        onAction(.typing)
                    }
                    QuickActionButton(icon: "arrow.up.doc", label: "Upload Audio", color: theme.accentColor) {
                        onAction(.audioUpload)
                    }
                }
                .padding(.horizontal, theme.screenPadding)
                .padding(.vertical, 10) // Space for shadows
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    @Environment(\.theme) var theme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .strokeBorder(color.opacity(0.3), lineWidth: 1.5)
                        .background(Circle().fill(Color.clear))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 84)
            .padding(.vertical, 12)
            .background(Color.clear) // Transparent background for secondary
        }
        .buttonStyle(.plain)
    }
}


struct HubErrorStateView: View {
    let message: String
    var onRetry: () -> Void
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange.opacity(0.8))
            
            Text("Something went wrong")
                .font(.system(size: 18, weight: .bold))
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button("Try Again") {
                onRetry()
            }
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(theme.accentColor)
            .cornerRadius(12)
        }
        .padding(.top, 60)
    }
}

// MARK: - Data Models

struct FamilyQuote: Identifiable, Equatable {
    let id: String
    let quoteText: String
    let authorName: String
    let authorRole: String
    let storyId: String?
    let theme: String
    let createdAt: Date

    var roleColor: Color {
        switch authorRole.lowercased() {
        case "elder": return .storytellerElder
        case "parent", "organizer": return .storytellerParent
        case "child": return .storytellerChild
        case "teen": return .storytellerTeen
        default: return .storytellerPurple
        }
    }
}

struct ArchivistData {
    let totalVoices: Int
    let totalStories: Int
    let evolvingStories: [EvolvingStory]
    let recentContributions: [Contribution]
    let quotes: [FamilyQuote]
    let discussionTopics: [DiscussionTopic]

    // Initialize from real API data
    init(stories: [StoryData], family: FamilyInfo, members: [FamilyMemberData], quotes: [FamilyQuote] = [], discussionTopics: [DiscussionTopic] = []) {
        self.totalStories = stories.count
        self.totalVoices = stories.reduce(0) { $0 + $1.voiceCount }
        self.quotes = quotes
        self.discussionTopics = discussionTopics

        // Create evolving stories from stories with multiple responses
        self.evolvingStories = stories
            .filter { $0.voiceCount > 1 }
            .sorted { $0.createdAtDate > $1.createdAtDate }
            .prefix(5)
            .map { story in
                EvolvingStory(
                    id: story.id,
                    title: story.title ?? story.promptText ?? "Untitled Story",
                    storyteller: members.first(where: { $0.familyId == story.familyId })?.fullName ?? members.first?.fullName ?? "Family",
                    color: Color(hex: story.storytellerColorName),
                    contributionCount: story.voiceCount,
                    lastActivity: story.createdAtDate,
                    previewText: story.summaryText ?? "A story from your family..."
                )
            }

        // Create recent contributions from all stories
        self.recentContributions = stories
            .sorted { $0.createdAtDate > $1.createdAtDate }
            .prefix(5)
            .map { story in
                Contribution(
                    id: story.id,
                    storyteller: members.first(where: { $0.familyId == story.familyId })?.fullName ?? members.first?.fullName ?? "Family",
                    storyTitle: story.title ?? story.promptText ?? "Untitled Story",
                    role: story.promptCategory?.lowercased().contains("elder") == true ? .dark : .light,
                    timestamp: story.createdAtDate,
                    duration: 60 // Default duration - will be updated from API
                )
            }
    }
}

struct EvolvingStory: Identifiable, Hashable {
    let id: String
    let title: String
    let storyteller: String
    let color: Color
    let contributionCount: Int
    let lastActivity: Date
    let previewText: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: EvolvingStory, rhs: EvolvingStory) -> Bool {
        lhs.id == rhs.id
    }

    var timeAgo: String {
        let interval = Date().timeIntervalSince(lastActivity)
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }
}

struct Contribution: Identifiable {
    let id: String
    let storyteller: String
    let storyTitle: String
    let role: AppTheme
    let timestamp: Date
    let duration: TimeInterval

    var timeAgo: String {
        let interval = Date().timeIntervalSince(timestamp)
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }

    var formattedDuration: String {
        let minutes = Int(duration / 60)
        return minutes > 0 ? "\(minutes) min" : "\(Int(duration))s"
    }
}

// MARK: - Dashboard View

struct DashboardView: View {
    let data: ArchivistData
    @Environment(\.theme) var theme
    var onCaptureAction: () -> Void = {}
    var onStorySelected: (EvolvingStory) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 32) {
            // Show empty state if no stories yet
            if data.evolvingStories.isEmpty && data.recentContributions.isEmpty {
                HubEmptyStateView(onAction: onCaptureAction)
            } else {
                loadedContentView
            }
        }
    }

    private var loadedContentView: some View {
        VStack(spacing: 32) {
            // 1. Evolving Stories (The "Value")
            if !data.evolvingStories.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    CozySectionHeader(icon: "sparkles", title: "Growing Stories")

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(data.evolvingStories) { story in
                                NavigationLink(value: story) {
                                    EvolvingStoryCard(story: story)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, theme.screenPadding)
                    }
                }
            }

            // 2. Recent Contributions
            if !data.recentContributions.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    CozySectionHeader(icon: "clock.fill", title: "Recent Moments")

                    CozyCard {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(data.recentContributions.indices, id: \.self) { index in
                                let contribution = data.recentContributions[index]
                                NavigationLink(value: EvolvingStory(
                                    id: contribution.id,
                                    title: contribution.storyTitle,
                                    storyteller: contribution.storyteller,
                                    color: theme.accentColor,
                                    contributionCount: 1,
                                    lastActivity: contribution.timestamp,
                                    previewText: ""
                                )) {
                                    ContributionRowContent(contribution: contribution)
                                }
                                .buttonStyle(.plain)

                                if index < data.recentContributions.count - 1 {
                                    Divider().padding(.leading, 64)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }

            // 3. Family Wisdom Quotes
            if !data.quotes.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    CozySectionHeader(icon: "quote.bubble.fill", title: "Family Wisdom")

                    CozyCard {
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(data.quotes.prefix(3)) { quote in
                                if quote.id != data.quotes.first?.id {
                                    Divider()
                                }
                                QuoteItem(
                                    text: quote.quoteText,
                                    author: quote.authorName,
                                    role: quote.authorRole.capitalized,
                                    roleColor: quote.roleColor
                                )
                            }
                        }
                        .padding(24)

                        Divider()

                        ViewAllButton(title: "View All Quotes", action: {
                            // TODO: Navigate to quotes view
                            print("Navigate to all quotes")
                        })
                    }
                }
            }

            // 4. Family Discussion Topics (AI-Generated based on family's stories)
            if !data.discussionTopics.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    CozySectionHeader(icon: "bubble.left.and.bubble.right.fill", title: "Discussion Topics")

                    // Show first AI-generated topic
                    if let firstTopic = data.discussionTopics.first {
                        CozyCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Label(firstTopic.category, systemImage: "sparkles")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.storytellerParent)
                                    Spacer()
                                    
                                    if firstTopic.relatedStoryCount > 0 {
                                        HStack(spacing: 4) {
                                            Image(systemName: "book.fill")
                                                .font(.system(size: 10))
                                            Text("\(firstTopic.relatedStoryCount) stories")
                                                .font(.system(size: 10, weight: .bold))
                                        }
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.secondary.opacity(0.1))
                                        .clipShape(Capsule())
                                    }
                                }

                                Text(firstTopic.question)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(theme.textColor)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(20)

                            Button(action: {
                                // TODO: Navigate to capture with this topic
                                print("Discuss topic: \(firstTopic.question)")
                            }) {
                                HStack {
                                    Text("Add Your Voice")
                                        .font(.system(size: 16, weight: .bold))
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        colors: [theme.accentColor, theme.accentColor.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Hub Empty State View

struct HubEmptyStateView: View {
    @Environment(\.theme) var theme
    var onAction: () -> Void = {}

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Illustration
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.storytellerElder.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Image(systemName: "sparkles")
                        .font(.system(size: 50))
                        .foregroundColor(.storytellerElder)
                }

                Text("Welcome to Your Family Library")
                    .font(theme.headlineFont)
                    .foregroundColor(theme.textColor)
                    .multilineTextAlignment(.center)
            }

            // Getting Started Steps
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.storytellerElder)
                            .frame(width: 28, height: 28)
                            .overlay {
                                Text("1")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Capture Your First Memory")
                                .font(theme.headlineFont)
                                .foregroundColor(theme.textColor)

                            Text("Record a story, upload a photo, or write down a precious moment")
                                .font(theme.bodyFont)
                                .foregroundColor(theme.textColor.opacity(0.7))
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.storytellerParent)
                            .frame(width: 28, height: 28)
                            .overlay {
                                Text("2")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Share With Family")
                                .font(theme.headlineFont)
                                .foregroundColor(theme.textColor)

                            Text("Invite family members to add their perspectives to your stories")
                                .font(theme.bodyFont)
                                .foregroundColor(theme.textColor.opacity(0.7))
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.storytellerChild)
                            .frame(width: 28, height: 28)
                            .overlay {
                                Text("3")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Build Your Collection")
                                .font(theme.headlineFont)
                                .foregroundColor(theme.textColor)

                            Text("Watch your family library grow with each new memory")
                                .font(theme.bodyFont)
                                .foregroundColor(theme.textColor.opacity(0.7))
                        }
                    }
                }
            }
            .padding(.horizontal, theme.screenPadding + 8)

            // CTA Button
            Button(action: onAction) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Capture Your First Memory")
                }
                .font(theme.headlineFont)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.storytellerElder, .storytellerParent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            Spacer()
        }
        .padding(.top, 60)
    }
}

// MARK: - Dashboard Components

struct EvolvingStoryCard: View {
    let story: EvolvingStory
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(story.color.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 14))
                            .foregroundColor(story.color)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(story.storyteller)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(theme.secondaryTextColor)
                    Text(story.timeAgo)
                        .font(.system(size: 10))
                        .foregroundColor(theme.secondaryTextColor.opacity(0.6))
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "waveform")
                    Text("\(story.contributionCount)")
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(story.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(story.color.opacity(0.1))
                .clipShape(Capsule())
            }
            
            Text(story.title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(theme.textColor)
                .lineLimit(2)
            
            Text(story.previewText)
                .font(.system(size: 14))
                .foregroundColor(theme.secondaryTextColor)
                .lineLimit(2)
            
            Spacer(minLength: 0)
            
            HStack {
                Text("Join Story")
                    .font(.system(size: 13, weight: .bold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundColor(theme.accentColor)
        }
        .padding(20)
        .frame(width: 280, height: 200)
        .background(theme.cardBackgroundColor)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        .contentShape(Rectangle())
    }
}

struct ContributionRowContent: View {
    let contribution: Contribution
    @Environment(\.theme) var theme

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(theme.accentColor.opacity(0.1))
                    .frame(width: 48, height: 48)

                Image(systemName: contribution.role == .dark ? "person.fill" : "person.2.fill")
                    .foregroundColor(theme.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(contribution.storyTitle)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(theme.textColor)
                
                Text("by \(contribution.storyteller) • \(contribution.timeAgo)")
                    .font(.system(size: 13))
                    .foregroundColor(theme.secondaryTextColor)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "mic.fill")
                    Text(contribution.formattedDuration)
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(theme.textColor.opacity(0.7))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }
}

struct PollBar: View {
    let label: String
    let percentage: Double
    let color: Color
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(theme.textColor)
                Spacer()
                Text("\(Int(percentage * 100))%")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(theme.secondaryTextColor)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.backgroundColor)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(percentage), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

struct QuoteItem: View {
    let text: String
    let author: String
    let role: String
    let roleColor: Color
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\"\(text)\"")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(theme.textColor)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack {
                Text("— \(author)")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                RoleBadge(text: role, color: roleColor)
            }
        }
    }
}

// MARK: - Skeleton

struct DashboardSkeletonView: View {
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 32) {
            ForEach(0..<3) { _ in
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Circle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 24, height: 24)
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 150, height: 20)
                            .cornerRadius(4)
                    }
                    .padding(.horizontal, theme.screenPadding)
                    
                    Rectangle()
                        .fill(theme.role == .light ? Color.white : theme.cardBackgroundColor)
                        .frame(height: 200)
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                        .padding(.horizontal, 16)
                        .overlay(
                            VStack(alignment: .leading, spacing: 12) {
                                Rectangle().fill(Color.gray.opacity(0.05)).frame(height: 20).cornerRadius(4)
                                Rectangle().fill(Color.gray.opacity(0.05)).frame(height: 20).cornerRadius(4)
                                Rectangle().fill(Color.gray.opacity(0.05)).frame(width: 200, height: 20).cornerRadius(4)
                            }
                            .padding(24)
                        )
                }
            }
        }
    }
}

// MARK: - Preview

struct HubView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HubView()
                .environment(\.theme, ThemeFactory.theme(for: .dark))
                .previewDisplayName("Teen (Dark)")

            HubView()
                .environment(\.theme, ThemeFactory.theme(for: .light))
                .previewDisplayName("Parent (Light)")
        }
    }
}
