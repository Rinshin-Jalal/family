//
//  FamilyView.swift
//  StoryRide
//
//  Family - Motivation loop tailored per persona
//

import SwiftUI

// MARK: - Family View

struct FamilyView: View {
    @Environment(\.theme) var theme
    @State private var loadingState: LoadingState<ProfileData> = .loading
    
    var body: some View {
        TeenProfile(loadingState: loadingState)
            .animation(theme.animation, value: loadingState)
            .onAppear {
                loadProfile()
            }
    }

    private func loadProfile() {
        loadingState = .loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            loadingState = .loaded(ProfileData.sample)
        }
    }
}

// MARK: - Profile Data Model

struct ProfileData {
    let totalStories: Int
    let nextMilestone: Int
    let familyMembers: [FamilyMember]
    let earnedStickers: [String]
    let lockedStickers: [String]
    let achievements: [Achievement]
    let recentActivity: [Activity]

    static let sample = ProfileData(
        totalStories: 42,
        nextMilestone: 50,
        familyMembers: [
            FamilyMember(name: "Grandma Rose", avatarEmoji: "❤️", storyCount: 15, status: .offline, isElder: true),
            FamilyMember(name: "Dad",  avatarEmoji: "👨", storyCount: 12, status: .online),
            FamilyMember(name: "Leo",  avatarEmoji: "🎸", storyCount: 8, status: .away),
            FamilyMember(name: "Mia", avatarEmoji: "🌟", storyCount: 7, status: .online)
        ],
        earnedStickers: ["⭐️", "🚀", "🦁", "🎨", "🌈"],
        lockedStickers: ["🐶", "🎪", "🎈", "🎯", "🏆"],
        achievements: [
            Milestone(title: "First Story Preserved", description: "Your first family story saved forever", icon: "star.fill", earned: true, earnedAt: Date().addingTimeInterval(-86400 * 10), progress: nil, category: .preservation),
            Milestone(title: "Storyteller", description: "10 stories preserved", icon: "book.fill", earned: true, earnedAt: Date().addingTimeInterval(-86400 * 3), progress: nil, category: .preservation),
            Milestone(title: "Family Anthology", description: "50 stories preserved", icon: "books.vertical.fill", earned: false, earnedAt: nil, progress: 0.84, category: .preservation)
        ],
        recentActivity: [
            Activity(type: .storyRecorded, title: "The Summer Road Trip of '68", member: "Grandma Rose", timestamp: Date().addingTimeInterval(-3600)),
            Activity(type: .milestone, title: "Reached 40 stories!", member: nil, timestamp: Date().addingTimeInterval(-86400))
        ]
    )
}

enum ActivityType {
    case storyRecorded
    case milestone
    case achievement
    case newMember
}

struct Activity {
    let type: ActivityType
    let title: String
    let member: String?
    let timestamp: Date
}

struct TeenProfileSkeleton: View {
    @Environment(\.theme) var theme
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 200).clipShape(RoundedRectangle(cornerRadius: 16))
                Rectangle().fill(Color.gray.opacity(0.1)).frame(height: 150).clipShape(RoundedRectangle(cornerRadius: 16))
                Rectangle().fill(Color.gray.opacity(0.1)).frame(height: 200).clipShape(RoundedRectangle(cornerRadius: 16))
                Rectangle().fill(Color.gray.opacity(0.3)).frame(height: theme.buttonHeight).clipShape(RoundedRectangle(cornerRadius: 16))
            }.padding(theme.screenPadding)
        }.background(theme.backgroundColor)
    }
}

struct TeenProfileEmptyState: View {
    @Environment(\.theme) var theme
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "chart.bar.doc.horizontal").font(.system(size: 80)).foregroundColor(theme.secondaryTextColor.opacity(0.5))
            VStack(spacing: 12) {
                Text("No Stats Yet").font(.system(size: 28, weight: .bold)).foregroundColor(theme.textColor)
                Text("Start recording stories\nto track your family's journey").font(.system(size: 16, weight: .medium)).foregroundColor(theme.secondaryTextColor).multilineTextAlignment(.center)
            }
            Spacer()
        }.padding(theme.screenPadding)
    }
}

struct TeenProfile: View {
    let loadingState: LoadingState<ProfileData>
    @Environment(\.theme) var theme
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator

    @State private var showAchievements = false
    @State private var showInvite = false
    @State private var showAddElder = false
    @State private var showManageMembers = false
    @State private var showGovernance = false

    // TODO: Replace with actual family data from API
    @State private var familyData = FamilyData(
        id: "family-123",
        name: "The Rodriguez Family",
        memberCount: 4,
        storyCount: 42,
        ownerId: "user-1",
        createdAt: Date(),
        hasSensitiveTopics: true,
        allowsConflictingPerspectives: true
    )

    var body: some View {
        NavigationStack {
            Group {
                switch loadingState {
                case .loading:
                    TeenProfileSkeleton()
                case .empty:
                    TeenProfileEmptyState()
                case .loaded(let data):
                    TeenProfileContent(
                        data: data,
                        showAchievements: $showAchievements,
                        showInvite: $showInvite,
                        showGovernance: $showGovernance,
                        familyData: $familyData
                    )
                case .error(let message):
                    ErrorStateView(message: message, onRetry: {})
                }
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationTitle("\(familyData.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EmptyView()
                }
            }
        }
        .sheet(isPresented: $showAchievements) { MilestonesModal(milestones: ProfileData.sample.achievements) }
        .sheet(isPresented: $showInvite) { ShareCollectionsModal() }
        .sheet(isPresented: $showAddElder) { AddElderModal() }
        .sheet(isPresented: $showManageMembers) { ManageMembersModal() }
        .sheet(isPresented: $showGovernance) { FamilyGovernanceModal(familyData: familyData) }
        .onChange(of: navigationCoordinator.pendingFamilyAction) { _, action in
            switch action {
            case .showAddElder:
                showAddElder = true
            case .showManageMembers:
                showManageMembers = true
            case .showGovernance:
                showGovernance = true
            case .none:
                break
            }
            navigationCoordinator.clearPendingAction()
        }
    }
}

struct TeenProfileContent: View {
    let data: ProfileData
    @Binding var showAchievements: Bool
    @Binding var showInvite: Bool
    @Binding var showGovernance: Bool
    @Binding var familyData: FamilyData
    @Environment(\.theme) var theme

    // TODO: Replace with actual user ownership status from API
    @State private var isOwner: Bool = true

    var progress: Double { Double(data.totalStories) / Double(data.nextMilestone) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Stories & Milestone Card (simplified - removed streak)
                ZStack {
                    VStack(spacing: 16) {
                        // Top section: Total Stories
                        HStack {
                            Image(systemName: "book.fill").font(.system(size: 35, weight: .bold)).foregroundColor(.white)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Family Stories").font(.system(size: 22, weight: .bold)).foregroundColor(.white)
                                Text("Preserving memories together").font(.system(size: 14, weight: .medium)).foregroundColor(.white.opacity(0.8))
                            }
                            Spacer()
                            VStack(spacing: 4) {
                                Text("\(data.totalStories)").font(.system(size: 40, weight: .bold, design: .rounded)).foregroundColor(.white)
                                Text("Stories").font(.system(size: 12, weight: .semibold)).textCase(.uppercase).foregroundColor(.white.opacity(0.8))
                            }
                        }

                        Divider().background(.white.opacity(0.2))

                        // Bottom section: Milestone Progress
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("NEXT MILESTONE").font(.system(size: 13, weight: .semibold)).foregroundColor(.white.opacity(0.9)).tracking(1)
                                Spacer()
                                Text("\(data.totalStories)/\(data.nextMilestone)").font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                            }
                            ZStack(alignment: .leading) {
                                Capsule().fill(.white.opacity(0.2)).frame(height: 8)
                                Capsule().fill(.white).frame(width: max(0, min(1, progress)) * (UIScreen.main.bounds.width - 64), height: 8)
                            }.frame(height: 8)
                            Text("\(data.nextMilestone - data.totalStories) more to go").font(.system(size: 14, weight: .medium)).foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(20)
                }
                .frame(height: 200)
                .background(theme.accentColor)
                .cornerRadius(24)
                .shadow(color: theme.accentColor.opacity(0.3), radius: 12, y: 4)

                // Governance quick access (owner only)
                if isOwner {
                    Button(action: { showGovernance = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "shield.checkered")
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Family Governance")
                                    .font(.headline)

                                Text("Permissions, privacy & safety")
                                    .font(.caption)
                                    .foregroundColor(theme.secondaryTextColor)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(theme.secondaryTextColor)
                        }
                        .foregroundColor(theme.accentColor)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(theme.accentColor.opacity(0.1))
                        )
                    }
                }

                // Family Members
                VStack(alignment: .leading, spacing: 16) {
                    Text("Family Members").font(.system(size: 17, weight: .bold)).foregroundColor(theme.textColor).padding(.horizontal, 16).padding(.top, 16)
                    VStack(spacing: 8) {
                        ForEach(data.familyMembers, id: \.name) { member in
                            TeenFamilyMemberRow(member: member)
                        }
                    }.padding(.horizontal, 16).padding(.bottom, 16)
                }
                .background(theme.role == .light ? Color.white : theme.cardBackgroundColor)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)

                // Share Button (TRANSFORMED from "Invite Family Member")
                Button(action: { showInvite = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up").font(.system(size: 18, weight: .semibold))
                        Text("Share Stories").font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: theme.buttonHeight)
                    .background(theme.accentColor)
                    .cornerRadius(16)
                }
                .padding(.top, 8)

                // Achievements section REMOVED - gamification de-emphasized in favor of value extraction
                // Milestones are still accessible through the milestones modal
            }
            .padding(theme.screenPadding)
        }
    }
}

// Teen Achievement Card Component

struct TeenAchievementCard: View {
    let achievement: Achievement
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Progress ring wraps around the icon (only shows when in progress)
                if let progress = achievement.progress, !achievement.earned {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            theme.accentColor,
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .frame(width: 64, height: 64)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: progress)
                }

                // Background circle
                Circle()
                    .fill(achievement.earned ? theme.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 56, height: 56)

                // Achievement icon
                Image(systemName: achievement.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(achievement.earned ? theme.accentColor : .gray)
            }
            Text(achievement.title).font(.system(size: 13, weight: .semibold)).foregroundColor(achievement.earned ? theme.textColor : .secondary).lineLimit(2).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
    }
}

struct TeenFamilyMemberRow: View {
    let member: FamilyMember
    @Environment(\.theme) var theme

    var storytellerColor: Color {
        return .storytellerGreen
    }

    var body: some View {
        Button(action: {}) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(storytellerColor.opacity(0.2)).frame(width: 44, height: 44)
                    Text(member.avatarEmoji).font(.system(size: 22))
                }
                Text(member.name).font(.system(size: 16, weight: .medium)).foregroundColor(theme.textColor).lineLimit(1)
                Spacer()
                Text("\(member.storyCount)").font(.system(size: 18, weight: .bold)).foregroundColor(theme.accentColor)
            }.padding(.vertical, 8).padding(.horizontal, 4)
        }.buttonStyle(.plain)
    }
}

// MARK: - Preview

struct FamilyView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FamilyView()
                .environmentObject(NavigationCoordinator.shared)
                .themed(DarkTheme())
                .previewDisplayName("dark Family")
            
            FamilyView()
                .environmentObject(NavigationCoordinator.shared)
                .themed(LightTheme())
                .previewDisplayName("light Family")
        }
    }
}

