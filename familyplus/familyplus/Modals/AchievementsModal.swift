//
//  MilestonesModal.swift
//  StoryRide
//
//  Modal view for displaying content milestones (value created, not engagement)
//
//  TRANSFORMED FROM: AchievementsModal.swift
//  Changed from gamification to value-based progress tracking
//

import SwiftUI

// MARK: - Milestones Modal

struct MilestonesModal: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    let milestones: [Milestone]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(milestones, id: \.id) { milestone in
                        MilestoneCard(milestone: milestone)
                    }
                }
                .padding(.horizontal, theme.screenPadding)
                .padding(.vertical, 16)
            }
            .background(theme.backgroundColor)
            .navigationTitle("Your Milestones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.accentColor)
                    .font(.system(size: 17, weight: .semibold))
                }
            }
        }
    }
}

// MARK: - Milestone Card

struct MilestoneCard: View {
    let milestone: Milestone
    @Environment(\.theme) var theme

    var body: some View {
        HStack(spacing: 16) {
            // Avatar/icon circle
            ZStack {
                Circle()
                    .fill(
                        (milestone.earned ? theme.accentColor : Color.gray)
                            .opacity(milestone.earned ? 0.2 : 0.1)
                    )
                    .frame(width: 64, height: 64)

                Image(systemName: milestone.icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(milestone.earned ? theme.accentColor : .gray)
            }

            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(milestone.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(milestone.earned ? theme.textColor : .secondary)

                    if milestone.earned {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.green)
                    }
                }

                Text(milestone.description)
                    .font(.system(size: 15))
                    .foregroundColor(theme.secondaryTextColor)
                    .lineLimit(2)

                // Progress or earned date
                if let progress = milestone.progress, !milestone.earned {
                    VStack(alignment: .leading, spacing: 6) {
                        ProgressView(value: progress)
                            .tint(theme.accentColor)

                        Text("\(Int(progress * 100))% Complete")
                            .font(.system(size: 13))
                            .foregroundColor(theme.secondaryTextColor)
                    }
                } else if let earnedAt = milestone.earnedAt {
                    Text("Milestone reached \(earnedAt, style: .date)")
                        .font(.system(size: 13))
                        .foregroundColor(theme.secondaryTextColor)
                }
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackgroundColor)
        )
    }
}

// Backward compatibility alias
typealias AchievementsModal = MilestonesModal
typealias AchievementCard = MilestoneCard

// MARK: - Preview

struct MilestonesModal_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MilestonesModal(milestones: [
                Milestone(
                    title: "First Story Preserved",
                    description: "Your first family story saved forever",
                    icon: "star.fill",
                    earned: true,
                    earnedAt: Date().addingTimeInterval(-86400 * 10),
                    progress: nil,
                    category: .preservation
                ),
                Milestone(
                    title: "Wisdom Captured",
                    description: "10 wisdom moments tagged",
                    icon: "brain.fill",
                    earned: true,
                    earnedAt: Date().addingTimeInterval(-86400 * 5),
                    progress: nil,
                    category: .wisdom
                ),
                Milestone(
                    title: "Elder Reached",
                    description: "Grandma's stories captured",
                    icon: "heart.fill",
                    earned: true,
                    earnedAt: Date().addingTimeInterval(-86400 * 3),
                    progress: nil,
                    category: .connection
                ),
                Milestone(
                    title: "Family Anthology",
                    description: "50 stories preserved",
                    icon: "book.fill",
                    earned: false,
                    earnedAt: nil,
                    progress: 0.84,
                    category: .preservation
                )
            ])
            .themed(DarkTheme())
            .previewDisplayName("Dark Theme")

            MilestonesModal(milestones: [
                Milestone(
                    title: "First Story",
                    description: "Your first family story saved",
                    icon: "star.fill",
                    earned: true,
                    earnedAt: Date(),
                    progress: nil,
                    category: .preservation
                ),
                Milestone(
                    title: "Building Wisdom",
                    description: "Keep capturing family stories!",
                    icon: "brain.fill",
                    earned: false,
                    earnedAt: nil,
                    progress: 0.5,
                    category: .wisdom
                )
            ])
            .themed(LightTheme())
            .previewDisplayName("Light Theme")
        }
    }
}

