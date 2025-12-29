//
//  ProfileView.swift
//  StoryRide
//
//  Profile - Motivation loop tailored per persona
//

import SwiftUI

// MARK: - Profile View

struct ProfileView: View {
    @Environment(\.theme) var theme
    @State private var loadingState: LoadingState<ProfileData> = .loading
    @State private var currentProfile: UserProfile = UserProfile(name: "Leo", role: .teen, avatarEmoji: "🎸")
    let profiles: [UserProfile] = [
        UserProfile(name: "Leo", role: .teen, avatarEmoji: "🎸"),
        UserProfile(name: "Mom", role: .parent, avatarEmoji: "👩"),
        UserProfile(name: "Mia", role: .child, avatarEmoji: "🌟"),
        UserProfile(name: "Grandma", role: .elder, avatarEmoji: "❤️")
    ]

    var body: some View {
        Group {
            switch theme.role {
            case .teen, .parent:
                // Unified Teen/Parent view - same UX, different theme
                TeenProfile(loadingState: loadingState, currentProfile: $currentProfile, profiles: profiles)
            case .child:
                ChildProfile(loadingState: loadingState, currentProfile: $currentProfile, profiles: profiles)
            case .elder:
                ElderProfile(currentProfile: $currentProfile, profiles: profiles)
            }
        }
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
    let weekStreak: Int
    let totalStories: Int
    let nextMilestone: Int
    let familyMembers: [FamilyMember]
    let earnedStickers: [String]
    let lockedStickers: [String]
    let achievements: [Achievement]
    let recentActivity: [Activity]

    static let sample = ProfileData(
        weekStreak: 4,
        totalStories: 42,
        nextMilestone: 50,
        familyMembers: [
            FamilyMember(name: "Grandma Rose", role: .elder, avatarEmoji: "❤️", storyCount: 15, weeksStreak: 3, status: .offline),
            FamilyMember(name: "Dad", role: .parent, avatarEmoji: "👨", storyCount: 12, weeksStreak: 4, status: .online),
            FamilyMember(name: "Leo", role: .teen, avatarEmoji: "🎸", storyCount: 8, weeksStreak: 2, status: .away),
            FamilyMember(name: "Mia", role: .child, avatarEmoji: "🌟", storyCount: 7, weeksStreak: 3, status: .online)
        ],
        earnedStickers: ["⭐️", "🚀", "🦁", "🎨", "🌈"],
        lockedStickers: ["🐶", "🎪", "🎈", "🎯", "🏆"],
        achievements: [
            Achievement(title: "First Story", description: "Record your first story", icon: "star.fill", earned: true, earnedAt: Date().addingTimeInterval(-86400 * 10), progress: nil),
            Achievement(title: "Streak Master", description: "7-day recording streak", icon: "flame.fill", earned: true, earnedAt: Date().addingTimeInterval(-86400 * 5), progress: nil),
            Achievement(title: "Storyteller", description: "Record 10 stories", icon: "mic.fill", earned: true, earnedAt: Date().addingTimeInterval(-86400 * 3), progress: nil),
            Achievement(title: "Family Champion", description: "Get family to 50 stories", icon: "person.3.fill", earned: false, earnedAt: nil, progress: 0.84)
        ],
        recentActivity: [
            Activity(type: .storyRecorded, title: "The Summer Road Trip of '68", member: "Grandma Rose", timestamp: Date().addingTimeInterval(-3600)),
            Activity(type: .milestone, title: "Reached 40 stories!", member: nil, timestamp: Date().addingTimeInterval(-86400)),
            Activity(type: .achievement, title: "Streak Master unlocked", member: nil, timestamp: Date().addingTimeInterval(-86400 * 2))
        ]
    )
}

struct Achievement {
    let title: String
    let description: String
    let icon: String
    let earned: Bool
    let earnedAt: Date?
    let progress: Double?
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

// MARK: - Teen Profile ("Family Stats" - Instagram Style)

struct TeenProfile: View {
    let loadingState: LoadingState<ProfileData>
    @Binding var currentProfile: UserProfile
    let profiles: [UserProfile]
    @Environment(\.theme) var theme
    @State private var showAchievements = false
    @State private var showInvite = false

    var body: some View {
        NavigationStack {
            Group {
                switch loadingState {
                case .loading:
                    TeenProfileSkeleton()
                case .empty:
                    TeenProfileEmptyState()
                case .loaded(let data):
                    TeenProfileContent(data: data, showAchievements: $showAchievements, showInvite: $showInvite)
                case .error(let message):
                    ErrorStateView(message: message, onRetry: {})
                }
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EmptyView()
                }
            }
        }
        .sheet(isPresented: $showAchievements) { AchievementsView(achievements: ProfileData.sample.achievements) }
        .sheet(isPresented: $showInvite) { InviteFamilyView() }
    }
}

struct TeenProfileContent: View {
    let data: ProfileData
    @Binding var showAchievements: Bool
    @Binding var showInvite: Bool
    @Environment(\.theme) var theme

    var progress: Double { Double(data.totalStories) / Double(data.nextMilestone) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Streak & Stats Card
                ZStack {
                    LinearGradient(colors: [theme.accentColor.opacity(0.8), theme.accentColor], startPoint: .topLeading, endPoint: .bottomTrailing)

                    VStack(spacing: 16) {
                        // Top section: Streak & Total Stories
                        HStack {
                            ZStack {
                                Circle().fill(.orange.opacity(0.3)).frame(width: 56, height: 56)
                                Image(systemName: "flame.fill").font(.system(size: 28, weight: .bold)).foregroundColor(.orange)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(data.weekStreak) Week Streak").font(.system(size: 22, weight: .bold)).foregroundColor(.white)
                                Text("Keep it momentum!").font(.system(size: 14, weight: .medium)).foregroundColor(.white.opacity(0.8))
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
                .frame(height: 220)
                .shadow(color: .black.opacity(0.3), radius: 12, y: 4)

                // Family Members
                VStack(alignment: .leading, spacing: 16) {
                    Text("Family Members").font(.system(size: 17, weight: .bold)).foregroundColor(theme.textColor).padding(.horizontal, 16).padding(.top, 16)
                    VStack(spacing: 8) {
                        ForEach(data.familyMembers, id: \.name) { member in
                            TeenFamilyMemberRow(member: member)
                        }
                    }.padding(.horizontal, 16).padding(.bottom, 16)
                }.background(RoundedRectangle(cornerRadius: 16).fill(theme.cardBackgroundColor))

                // Invite Button
                Button(action: { showInvite = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "person.badge.plus").font(.system(size: 18, weight: .semibold))
                        Text("Invite Family Member").font(.system(size: 17, weight: .semibold))
                    }.foregroundColor(.white).frame(maxWidth: .infinity).frame(height: theme.buttonHeight).background(LinearGradient(colors: [theme.accentColor, theme.accentColor.opacity(0.8)], startPoint: .leading, endPoint: .trailing)).clipShape(RoundedRectangle(cornerRadius: 16))
                }.buttonStyle(.plain)

                // Achievements Card - 2 Column Grid
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "trophy.fill").font(.system(size: 20)).foregroundColor(theme.accentColor)
                        Text("Achievements").font(.system(size: 17, weight: .bold)).foregroundColor(theme.textColor)
                        Spacer()
                        Button(action: { showAchievements = true }) {
                            Text("See All").font(.system(size: 14, weight: .semibold)).foregroundColor(theme.accentColor)
                        }
                    }.padding(.horizontal, 16).padding(.top, 16)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(data.achievements.prefix(4), id: \.title) { achievement in
                            TeenAchievementCard(achievement: achievement)
                        }
                    }.padding(.horizontal, 16).padding(.bottom, 16)
                }.background(RoundedRectangle(cornerRadius: 16).fill(theme.cardBackgroundColor))
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
                Circle().fill(achievement.earned ? theme.accentColor.opacity(0.2) : Color.gray.opacity(0.1)).frame(width: 56, height: 56)
                Image(systemName: achievement.icon).font(.system(size: 24, weight: .semibold)).foregroundColor(achievement.earned ? theme.accentColor : .gray)
            }
            Text(achievement.title).font(.system(size: 13, weight: .semibold)).foregroundColor(achievement.earned ? theme.textColor : .secondary).lineLimit(2).multilineTextAlignment(.center)
            if let progress = achievement.progress, !achievement.earned {
                ProgressView(value: progress).tint(theme.accentColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(achievement.earned ? Color(.systemGray6) : Color.gray.opacity(0.05)))
    }
}

struct TeenFamilyMemberRow: View {
    let member: FamilyMember
    @Environment(\.theme) var theme

    var storytellerColor: Color {
        switch member.role {
        case .elder: return .storytellerOrange
        case .parent: return .storytellerBlue
        case .teen: return .storytellerPurple
        case .child: return .storytellerGreen
        }
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
// MARK: - Child Profile ("Sticker Book" - Magical)

struct ChildProfile: View {
    let loadingState: LoadingState<ProfileData>; @Environment(\.theme) var theme
    @Binding var currentProfile: UserProfile
    let profiles: [UserProfile]
    @State private var showStickerCelebration = false; @State private var selectedSticker: String?

    var body: some View {
        Group {
            switch loadingState {
            case .loading: ChildProfileSkeleton()
            case .empty: ChildProfileEmptyState()
            case .loaded(let data): ChildProfileContent(data: data, showStickerCelebration: $showStickerCelebration, selectedSticker: $selectedSticker)
            case .error: ChildProfileErrorState()
            }
        }.background(theme.backgroundColor.ignoresSafeArea())
        .sheet(isPresented: $showStickerCelebration) { ChildStickerCelebrationView { showStickerCelebration = false } }.animation(theme.animation, value: loadingState)
    }
}

struct ChildProfileContent: View {
    let data: ProfileData; @Binding var showStickerCelebration: Bool; @Binding var selectedSticker: String?
    @Environment(\.theme) var theme

    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var totalStickers: Int { data.earnedStickers.count + data.lockedStickers.count }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text("My Sticker Book!").font(.system(size: 40, weight: .heavy, design: .rounded)).foregroundColor(theme.textColor)
                VStack(spacing: 12) {
                    Text("\(data.earnedStickers.count) of \(totalStickers) Stickers").font(.system(size: 22, weight: .semibold, design: .rounded)).foregroundColor(theme.accentColor)
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.gray.opacity(0.2)).frame(height: 20)
                        Capsule().fill(theme.accentColor).frame(width: CGFloat(data.earnedStickers.count) / CGFloat(totalStickers) * 300, height: 20).shadow(color: theme.accentColor.opacity(0.4), radius: 8)
                    }.frame(height: 20)
                    Text("\(totalStickers - data.earnedStickers.count) more to collect!").font(.system(size: 20, weight: .medium, design: .rounded)).foregroundColor(theme.secondaryTextColor)
                }.padding().background(RoundedRectangle(cornerRadius: 24).fill(theme.cardBackgroundColor).shadow(color: .black.opacity(0.06), radius: 8, y: 4))
            }.padding(.top, theme.screenPadding)
            ScrollView {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(data.earnedStickers, id: \.self) { sticker in ChildStickerView(sticker: sticker, isLocked: false) { selectedSticker = sticker; showStickerCelebration = true } }
                    ForEach(data.lockedStickers, id: \.self) { sticker in ChildStickerView(sticker: sticker, isLocked: true) {} }
                }.padding(.horizontal, theme.screenPadding).padding(.vertical, 24)
            }
            VStack(spacing: 12) {
                Text("Record more stories to collect stickers!").font(.system(size: 22, weight: .semibold, design: .rounded)).foregroundColor(theme.secondaryTextColor).multilineTextAlignment(.center)
                HStack(spacing: 12) {
                    Image(systemName: "star.fill").font(.system(size: 24)).foregroundColor(.yellow)
                    Image(systemName: "star.fill").font(.system(size: 20)).foregroundColor(.orange)
                    Image(systemName: "star.fill").font(.system(size: 16)).foregroundColor(.red)
                }
            }.padding(.horizontal, theme.screenPadding).padding(.bottom, theme.screenPadding)
        }
    }
}

struct ChildStickerView: View {
    let sticker: String; let isLocked: Bool; let action: () -> Void
    @Environment(\.theme) var theme; @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 20).fill(isLocked ? Color.gray.opacity(0.15) : theme.accentColor.opacity(0.2)).frame(width: 100, height: 120).overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(isLocked ? Color.gray.opacity(0.2) : theme.accentColor, lineWidth: isLocked ? 2 : 4))
                if isLocked {
                    ZStack { Circle().fill(Color.gray).frame(width: 36, height: 36); Image(systemName: "lock.fill").font(.system(size: 20, weight: .semibold)).foregroundColor(.white) }.shadow(color: .black.opacity(0.2), radius: 4)
                } else {
                    Text(sticker).font(.system(size: 64)).scaleEffect(isPressed ? 0.8 : 1.0).animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
                }
            }.shadow(color: isLocked ? .clear : theme.accentColor.opacity(0.3), radius: isPressed ? 4 : 12, y: isPressed ? 2 : 6)
        }.buttonStyle(.plain).disabled(isLocked)
    }
}

struct ChildProfileSkeleton: View {
    @Environment(\.theme) var theme
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) { Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 30); Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 20) }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 24) {
                ForEach(0..<6) { _ in Rectangle().fill(Color.gray.opacity(0.1)).frame(width: 100, height: 120).clipShape(RoundedRectangle(cornerRadius: 20)) }
            }
        }.padding(theme.screenPadding).background(theme.backgroundColor)
    }
}

struct ChildProfileEmptyState: View {
    @Environment(\.theme) var theme
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: "book.closed").font(.system(size: 100)).foregroundColor(theme.secondaryTextColor.opacity(0.5))
            VStack(spacing: 16) {
                Text("Your Sticker Book is Empty!").font(.system(size: 32, weight: .heavy, design: .rounded)).foregroundColor(theme.textColor).multilineTextAlignment(.center)
                Text("Record your first story\nto get your first sticker!").font(.system(size: 22, weight: .medium, design: .rounded)).foregroundColor(theme.secondaryTextColor).multilineTextAlignment(.center).lineSpacing(6)
            }
            Spacer()
        }.padding(theme.screenPadding)
    }
}

struct ChildProfileErrorState: View {
    @Environment(\.theme) var theme
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 80)).foregroundColor(.orange)
            VStack(spacing: 16) {
                Text("Oops!").font(.system(size: 36, weight: .heavy, design: .rounded)).foregroundColor(theme.textColor)
                Text("Something went wrong.\nLet's try again!").font(.system(size: 22, weight: .medium, design: .rounded)).foregroundColor(theme.secondaryTextColor).multilineTextAlignment(.center).lineSpacing(6)
            }
            Button(action: {}) {
                Text("Try Again").font(.system(size: 24, weight: .heavy, design: .rounded)).foregroundColor(.white).frame(width: 200, height: 70).background(Capsule().fill(theme.accentColor).shadow(color: theme.accentColor.opacity(0.4), radius: 12, y: 6))
            }.buttonStyle(.plain)
            Spacer()
        }.padding(theme.screenPadding)
    }
}

struct ChildStickerCelebrationView: View {
    let onDismiss: () -> Void; @Environment(\.theme) var theme
    @State private var showContent = false; @State private var confettiActive = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 32) {
                Text("").font(.system(size: 120)).scaleEffect(showContent ? 1.0 : 0.1).rotationEffect(.degrees(showContent ? 0 : -180)).shadow(color: .yellow.opacity(0.5), radius: 20)
                VStack(spacing: 16) {
                    Text("Wow!").font(.system(size: 52, weight: .heavy, design: .rounded)).foregroundColor(.white)
                    Text("You found a sticker!").font(.system(size: 28, weight: .bold, design: .rounded)).foregroundColor(.white.opacity(0.95))
                }.opacity(showContent ? 1 : 0).offset(y: showContent ? 0 : 30)
                Button(action: onDismiss) {
                    Text("Yay!").font(.system(size: 32, weight: .heavy, design: .rounded)).foregroundColor(.white).frame(width: 200, height: 80).background(Capsule().fill(Color.storytellerGreen).shadow(color: Color.storytellerGreen.opacity(0.5), radius: 16, y: 8))
                }.opacity(showContent ? 1 : 0).scaleEffect(showContent ? 1 : 0.5)
            }
            if confettiActive { ConfettiView().ignoresSafeArea() }
        }.onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { showContent = true }
            confettiActive = true
        }
    }
}

struct ConfettiView: View {
    @State private var animate = false
    let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink, .mint, .cyan]
    var body: some View {
        ZStack {
            ForEach(0..<60) { index in ConfettiPiece(color: colors.randomElement() ?? .blue, startDelay: Double(index) * 0.015) }
        }.onAppear { animate = true }
    }
}

struct ConfettiPiece: View {
    let color: Color; let startDelay: Double
    @State private var offset: CGFloat = -100; @State private var rotation: Double = 0; @State private var xOffset: CGFloat = 0
    var body: some View {
        RoundedRectangle(cornerRadius: 2).fill(color).frame(width: CGFloat.random(in: 8...16), height: CGFloat.random(in: 8...16)).offset(x: xOffset, y: offset).rotationEffect(.degrees(rotation))
            .onAppear {
                xOffset = CGFloat.random(in: -250...250)
                DispatchQueue.main.asyncAfter(deadline: .now() + startDelay) {
                    withAnimation(.linear(duration: Double.random(in: 2.5...4.5))) {
                        offset = UIScreen.main.bounds.height + 100
                        rotation = Double.random(in: 360...720) * (Bool.random() ? 1 : -1)
                        xOffset += CGFloat.random(in: -150...150)
                    }
                }
            }
    }
}

// MARK: - Elder Profile

struct ElderProfile: View {
    @Environment(\.theme) var theme
    @Binding var currentProfile: UserProfile
    let profiles: [UserProfile]
    @State private var upcomingCall: Date? = Date().addingTimeInterval(86400 * 2)
    @State private var callNow = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Profile header
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(theme.accentColor.opacity(0.15))
                        .frame(width: 120, height: 120)
                    Image(systemName: "phone.fill")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(theme.accentColor)
                }

                VStack(spacing: 12) {
                    Text("Your Profile")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(theme.textColor)
                    Text("Stories saved: 15")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(theme.secondaryTextColor)
                }
            }

            Spacer()

            // Next call card
            if let callTime = upcomingCall, !callNow {
                VStack(spacing: 12) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 40))
                        .foregroundColor(theme.accentColor)
                    Text("Next Call")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(theme.textColor)
                    Text(formatCallDate(callTime))
                        .font(.system(size: 20))
                        .foregroundColor(theme.accentColor)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(theme.cardBackgroundColor)
                )
                .padding(.horizontal, theme.screenPadding)
            }

            Spacer()

            // Call button
            Button(action: { callNow.toggle() }) {
                HStack(spacing: 12) {
                    Image(systemName: callNow ? "phone.down.fill" : "phone.fill")
                        .font(.system(size: 28, weight: .semibold))
                    Text(callNow ? "Ending..." : "Call Me Now")
                        .font(.system(size: 26, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(callNow ? Color.red : Color.green)
                        .shadow(color: (callNow ? Color.red : Color.green).opacity(0.4), radius: 16, y: 8)
                )
            }
            .padding(.horizontal, theme.screenPadding)
            .padding(.bottom, 40)
        }
        .background(theme.backgroundColor.ignoresSafeArea())
        .animation(.spring(), value: callNow)
    }

    private func formatCallDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
}

// MARK: - Modal Views

struct AchievementsView: View {
    let achievements: [Achievement]; @Environment(\.theme) var theme; @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            ScrollView { LazyVStack(spacing: 16) { ForEach(achievements, id: \.title) { achievement in ModalAchievementCard(achievement: achievement) } }.padding(theme.screenPadding) }.background(theme.backgroundColor).navigationTitle("Achievements").navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() }.foregroundColor(theme.accentColor) } }
        }
    }
}

struct ModalAchievementCard: View {
    let achievement: Achievement; @Environment(\.theme) var theme
    var body: some View {
        HStack(spacing: 16) {
            ZStack { Circle().fill(achievement.earned ? theme.accentColor.opacity(0.2) : Color.gray.opacity(0.1)).frame(width: 64, height: 64); Image(systemName: achievement.icon).font(.system(size: 28, weight: .semibold)).foregroundColor(achievement.earned ? theme.accentColor : .gray) }
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(achievement.title).font(.system(size: 18, weight: .bold)).foregroundColor(achievement.earned ? theme.textColor : .secondary)
                    if achievement.earned { Image(systemName: "checkmark.circle.fill").font(.system(size: 20)).foregroundColor(.green) }
                }
                Text(achievement.description).font(.system(size: 15)).foregroundColor(theme.secondaryTextColor).lineLimit(2)
                if let progress = achievement.progress, !achievement.earned {
                    VStack(alignment: .leading, spacing: 6) {
                        ProgressView(value: progress).tint(theme.accentColor)
                        Text("\(Int(progress * 100))% Complete").font(.system(size: 13)).foregroundColor(theme.secondaryTextColor)
                    }
                } else if let earnedAt = achievement.earnedAt {
                    Text("Earned \(earnedAt, style: .date)").font(.system(size: 13)).foregroundColor(theme.secondaryTextColor)
                }
            }
            Spacer()
        }.padding().background(RoundedRectangle(cornerRadius: 16).fill(theme.cardBackgroundColor))
    }
}

struct InviteFamilyView: View {
    @Environment(\.theme) var theme; @Environment(\.dismiss) var dismiss
    @State private var email = ""; @State private var showSuccess = false
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                if !showSuccess {
                    VStack(spacing: 24) {
                        Image(systemName: "person.badge.plus").font(.system(size: 64)).foregroundColor(theme.accentColor)
                        VStack(spacing: 12) {
                            Text("Invite Family Member").font(.system(size: 28, weight: .bold)).foregroundColor(theme.textColor)
                            Text("Share your invite link\nto add someone new").font(.system(size: 16)).foregroundColor(theme.secondaryTextColor).multilineTextAlignment(.center)
                        }
                        TextField("", text: $email)
                            .font(.system(size: 18))
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(theme.cardBackgroundColor)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(theme.accentColor, lineWidth: 2)
                            )
                            .overlay(
                                Group {
                                    if email.isEmpty {
                                        Text("Enter email address")
                                            .foregroundColor(theme.secondaryTextColor)
                                            .padding(.leading, 20)
                                    }
                                },
                                alignment: .leading
                            )
                        Button(action: { withAnimation { showSuccess = true } }) {
                            Text("Send Invite").font(.system(size: 18, weight: .semibold)).foregroundColor(.white).frame(maxWidth: .infinity).frame(height: theme.buttonHeight).background(theme.accentColor).clipShape(RoundedRectangle(cornerRadius: 16))
                        }.disabled(email.isEmpty).opacity(email.isEmpty ? 0.5 : 1.0)
                    }
                } else {
                    VStack(spacing: 24) {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 80)).foregroundColor(.green)
                        Text("Invite Sent!").font(.system(size: 28, weight: .bold)).foregroundColor(theme.textColor)
                        Text("Check your email for invite link").font(.system(size: 16)).foregroundColor(theme.secondaryTextColor).multilineTextAlignment(.center)
                    }
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Text(showSuccess ? "Done" : "Cancel").font(.system(size: 18, weight: .semibold)).foregroundColor(theme.accentColor).frame(maxWidth: .infinity).frame(height: theme.buttonHeight).background(RoundedRectangle(cornerRadius: 16).strokeBorder(theme.accentColor, lineWidth: 2))
                }
            }.padding(theme.screenPadding)
        }
    }
}

// MARK: - Preview

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ProfileView().themed(TeenTheme()).previewDisplayName("Teen Profile")
            ProfileView().themed(ParentTheme()).previewDisplayName("Parent Profile")
            ProfileView().themed(ChildTheme()).previewDisplayName("Child Profile")
            ProfileView().themed(ElderTheme()).previewDisplayName("Elder Profile")
        }
    }
}

