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

    var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundColor.ignoresSafeArea()
                
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
                
                // 2. Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            selectedInputMode = .recording
                            showCaptureSheet = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(theme.accentColor)
                                    .frame(width: 64, height: 64)
                                    .shadow(color: theme.accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
                                
                                Image(systemName: "plus")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Family Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSearchView = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(theme.accentColor)
                            .padding(8)
                            .background(theme.accentColor.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
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
    }

    private func loadDashboard() {
        loadingState = .loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.snappy) {
                loadingState = .loaded(ArchivistData.mock)
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
            Text("Capture a Memory")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(theme.textColor)
                .padding(.horizontal, theme.screenPadding)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    QuickActionButton(icon: "mic.fill", label: "Record", color: .storytellerElder) {
                        onAction(.recording)
                    }
                    QuickActionButton(icon: "camera.fill", label: "Photo", color: .storytellerChild) {
                        onAction(.imageUpload)
                    }
                    QuickActionButton(icon: "text.bubble.fill", label: "Write", color: .storytellerTeen) {
                        onAction(.typing)
                    }
                    QuickActionButton(icon: "folder.fill", label: "Audio", color: .storytellerParent) {
                        onAction(.audioUpload)
                    }
                    QuickActionButton(icon: "doc.fill", label: "Document", color: .storytellerPurple) {
                        onAction(.documentUpload)
                    }
                }
                .padding(.horizontal, theme.screenPadding)
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
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                }
                
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.textColor)
            }
            .frame(width: 90)
            .padding(.vertical, 16)
            .background(theme.cardBackgroundColor)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

struct HubEmptyStateView: View {
    @Environment(\.theme) var theme
    var onAction: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 80))
                .foregroundColor(theme.accentColor.opacity(0.3))
            
            VStack(spacing: 8) {
                Text("Your Family Story Starts Here")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(theme.textColor)
                
                Text("Capture voices, photos, and documents to build your family library.")
                    .font(.system(size: 16))
                    .foregroundColor(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: onAction) {
                Text("Start First Story")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(theme.accentColor)
                    .cornerRadius(16)
                    .shadow(color: theme.accentColor.opacity(0.3), radius: 8, y: 4)
            }
        }
        .padding(.top, 60)
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

struct ArchivistData {
    let totalVoices: Int
    let totalStories: Int
    let evolvingStories: [EvolvingStory]
    let recentContributions: [Contribution]

    static let mock = ArchivistData(
        totalVoices: 23,
        totalStories: 12,
        evolvingStories: [
            EvolvingStory(
                id: "1",
                title: "The Summer of 1968",
                storyteller: "Grandma Rose",
                color: Color(hex: "D4A84A"), // storytellerElder
                contributionCount: 3,
                lastActivity: Date().addingTimeInterval(-86400),
                previewText: "We drove across the country in our old Chevy..."
            ),
            EvolvingStory(
                id: "2",
                title: "Our First Home",
                storyteller: "Dad",
                color: Color(hex: "3D6B4F"), // storytellerParent
                contributionCount: 5,
                lastActivity: Date().addingTimeInterval(-172800),
                previewText: "I remember the kitchen with yellow curtains..."
            )
        ],
        recentContributions: [
            Contribution(
                id: "1",
                storyteller: "Mom",
                storyTitle: "My First Day at School",
                role: .light,
                timestamp: Date().addingTimeInterval(-3600),
                duration: 120
            ),
            Contribution(
                id: "2",
                storyteller: "Leo",
                storyTitle: "The Best Birthday Ever",
                role: .dark,
                timestamp: Date().addingTimeInterval(-7200),
                duration: 45
            )
        ]
    )
}

struct EvolvingStory: Identifiable {
    let id: String
    let title: String
    let storyteller: String
    let color: Color
    let contributionCount: Int
    let lastActivity: Date
    let previewText: String

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

    var body: some View {
        VStack(spacing: 32) {
            // 1. Evolving Stories (The "Value")
            VStack(alignment: .leading, spacing: 16) {
                CozySectionHeader(icon: "sparkles", title: "Stories in Progress")
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(data.evolvingStories) { story in
                            EvolvingStoryCard(story: story)
                        }
                    }
                    .padding(.horizontal, theme.screenPadding)
                }
            }

            // 2. Recent Contributions
            VStack(alignment: .leading, spacing: 16) {
                CozySectionHeader(icon: "clock.fill", title: "Family Activity")
                
                CozyCard {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(data.recentContributions.indices, id: \.self) { index in
                            let contribution = data.recentContributions[index]
                            ContributionRow(contribution: contribution)
                            
                            if index < data.recentContributions.count - 1 {
                                Divider().padding(.leading, 64)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }

            // 3. Family Wisdom Quotes
            VStack(alignment: .leading, spacing: 16) {
                CozySectionHeader(icon: "quote.bubble.fill", title: "Family Wisdom")
                
                CozyCard {
                    VStack(alignment: .leading, spacing: 20) {
                        QuoteItem(
                            text: "Family is not an important thing, it's everything.",
                            author: "Grandma Rose",
                            role: "Elder",
                            roleColor: .storytellerElder
                        )
                        
                        Divider()
                        
                        QuoteItem(
                            text: "The secret to a happy life is finding joy in small moments.",
                            author: "Dad",
                            role: "Parent",
                            roleColor: .storytellerParent
                        )
                    }
                    .padding(24)
                    
                    Divider()
                    
                    ViewAllButton(title: "View All Quotes", action: {})
                }
            }

            // 4. Family Polls
            VStack(alignment: .leading, spacing: 16) {
                CozySectionHeader(icon: "chart.bar.fill", title: "Active Family Polls")
                
                CozyCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Label("Tradition", systemImage: "star.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.storytellerParent)
                            Spacer()
                            Text("25 votes")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Text("What's your favorite family holiday tradition?")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(theme.textColor)
                        
                        // Simple Progress bar representation
                        VStack(spacing: 8) {
                            PollBar(label: "Christmas Dinner", percentage: 0.6, color: .storytellerParent)
                            PollBar(label: "Summer BBQ", percentage: 0.3, color: .storytellerElder)
                            PollBar(label: "Game Night", percentage: 0.1, color: .storytellerTeen)
                        }
                    }
                    .padding(24)
                    
                    Divider()
                    
                    ViewAllButton(title: "Join the Conversation", action: {})
                }
            }
        }
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
                .lineLimit(3)
            
            Spacer(minLength: 0)
            
            HStack {
                Text("Contribute")
                    .font(.system(size: 13, weight: .bold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundColor(theme.accentColor)
        }
        .padding(20)
        .frame(width: 260, height: 200)
        .background(theme.cardBackgroundColor)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

struct ContributionRow: View {
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
                HStack {
                    Text(contribution.storyteller)
                        .font(.system(size: 16, weight: .bold))
                    Text("contributed to")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Text(contribution.storyTitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.accentColor)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(contribution.timeAgo)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "mic.fill")
                    Text(contribution.formattedDuration)
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(theme.secondaryTextColor)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
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
