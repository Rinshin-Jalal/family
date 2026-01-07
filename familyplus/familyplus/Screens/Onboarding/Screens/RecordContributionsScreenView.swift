import SwiftUI

struct RecordContributionsScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var showContributions: [Bool] = [false, false, false]
    
    private let contributions: [(name: String, action: String, avatar: String, color: Color, timeAgo: String)] = [
        ("Dad", "Added a photo from 1985", "D", .blue, "2 hours ago"),
        ("Mom", "Added her perspective", "M", .pink, "1 hour ago"),
        ("Sarah", "Left a comment", "S", .purple, "30 min ago")
    ]
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(theme.accentColor.opacity(0.1))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(theme.accentColor)
                        }
                        .opacity(showContent ? 1 : 0)
                        .scaleEffect(showContent ? 1 : 0.5)
                        
                        Text("Family Contributions")
                            .font(theme.headlineFont)
                            .foregroundColor(theme.textColor)
                            .opacity(showContent ? 1 : 0)
                        
                        Text("Your family is adding to this story")
                            .font(theme.bodyFont)
                            .foregroundColor(theme.secondaryTextColor)
                            .opacity(showContent ? 1 : 0)
                    }
                    
                    VStack(spacing: 12) {
                        ForEach(Array(contributions.enumerated()), id: \.offset) { index, contribution in
                            ContributionCard(
                                name: contribution.name,
                                action: contribution.action,
                                avatar: contribution.avatar,
                                color: contribution.color,
                                timeAgo: contribution.timeAgo,
                                isVisible: showContributions[index]
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)
                        
                        Text("We'll notify you when family adds more")
                            .font(.system(size: 14))
                            .foregroundColor(theme.secondaryTextColor)
                    }
                    .opacity(showContent ? 1 : 0)
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    OnboardingCTAButton(
                        title: "Add Your Memory",
                        action: {
                            coordinator.goToNextStep()
                        },
                        icon: "plus.circle.fill"
                    )
                    
                    OnboardingSecondaryButton(
                        title: "Skip for now",
                        action: {
                            coordinator.goToNextStep()
                        }
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
            
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(i) * 0.12) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showContributions[i] = true
                    }
                }
            }
        }
    }
}

private struct ContributionCard: View {
    let name: String
    let action: String
    let avatar: String
    let color: Color
    let timeAgo: String
    let isVisible: Bool
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 48, height: 48)
                
                Text(avatar)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.textColor)
                
                Text(action)
                    .font(.system(size: 14))
                    .foregroundColor(theme.secondaryTextColor)
            }
            
            Spacer()
            
            Text(timeAgo)
                .font(.system(size: 12))
                .foregroundColor(theme.secondaryTextColor.opacity(0.7))
        }
        .padding(14)
        .background(theme.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -30)
    }
}

#Preview {
    RecordContributionsScreenView(coordinator: .preview)
        .themed(LightTheme())
}
