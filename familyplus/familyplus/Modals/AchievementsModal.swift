//
//  AchievementsModal.swift
//  StoryRide
//
//  Modal view for displaying user achievements
//

import SwiftUI

// MARK: - Achievements Modal

struct AchievementsModal: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    
    let achievements: [Achievement]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(achievements, id: \.id) { achievement in
                        AchievementCard(achievement: achievement)
                    }
                }
                .padding(.horizontal, theme.screenPadding)
                .padding(.vertical, 16)
            }
            .background(theme.backgroundColor)
            .navigationTitle("Achievements")
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

// MARK: - Achievement Card

struct AchievementCard: View {
    let achievement: Achievement
    @Environment(\.theme) var theme
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar/icon circle
            ZStack {
                Circle()
                    .fill(
                        (achievement.earned ? theme.accentColor : Color.gray)
                            .opacity(achievement.earned ? 0.2 : 0.1)
                    )
                    .frame(width: 64, height: 64)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(achievement.earned ? theme.accentColor : .gray)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(achievement.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(achievement.earned ? theme.textColor : .secondary)
                    
                    if achievement.earned {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.green)
                    }
                }
                
                Text(achievement.description)
                    .font(.system(size: 15))
                    .foregroundColor(theme.secondaryTextColor)
                    .lineLimit(2)
                
                // Progress or earned date
                if let progress = achievement.progress, !achievement.earned {
                    VStack(alignment: .leading, spacing: 6) {
                        ProgressView(value: progress)
                            .tint(theme.accentColor)
                        
                        Text("\(Int(progress * 100))% Complete")
                            .font(.system(size: 13))
                            .foregroundColor(theme.secondaryTextColor)
                    }
                } else if let earnedAt = achievement.earnedAt {
                    Text("Earned \(earnedAt, style: .date)")
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

// MARK: - Preview

struct AchievementsModal_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AchievementsModal(achievements: [
                Achievement(
                    title: "First Story",
                    description: "Record your first story",
                    icon: "star.fill",
                    earned: true,
                    earnedAt: Date().addingTimeInterval(-86400 * 10),
                    progress: nil
                ),
                Achievement(
                    title: "Streak Master",
                    description: "7-day recording streak",
                    icon: "flame.fill",
                    earned: true,
                    earnedAt: Date().addingTimeInterval(-86400 * 5),
                    progress: nil
                ),
                Achievement(
                    title: "Storyteller",
                    description: "Record 10 stories",
                    icon: "mic.fill",
                    earned: true,
                    earnedAt: Date().addingTimeInterval(-86400 * 3),
                    progress: nil
                ),
                Achievement(
                    title: "Family Champion",
                    description: "Get family to 50 stories",
                    icon: "person.3.fill",
                    earned: false,
                    earnedAt: nil,
                    progress: 0.84
                )
            ])
            .themed(DarkTheme())
            .previewDisplayName("Dark Theme")
            
            AchievementsModal(achievements: [
                Achievement(
                    title: "First Story",
                    description: "Record your first story",
                    icon: "star.fill",
                    earned: true,
                    earnedAt: Date(),
                    progress: nil
                ),
                Achievement(
                    title: "In Progress",
                    description: "Keep going!",
                    icon: "chart.bar.fill",
                    earned: false,
                    earnedAt: nil,
                    progress: 0.5
                )
            ])
            .themed(LightTheme())
            .previewDisplayName("Light Theme")
        }
    }
}
