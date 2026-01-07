import SwiftUI

struct PitchSocialProof1ScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var animatedStats: [Int] = [0, 0, 0]
    
    private let targetStats = [50000, 2000000, 98]
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 24) {
                    ZStack {
                        ForEach(0..<5, id: \.self) { index in
                            Image(systemName: "star.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.yellow)
                                .offset(x: CGFloat(index - 2) * 36)
                                .opacity(showContent ? 1 : 0)
                                .scaleEffect(showContent ? 1 : 0)
                                .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(Double(index) * 0.1), value: showContent)
                        }
                    }
                    .frame(height: 40)
                    
                    Text("4.9 out of 5 stars")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(theme.textColor)
                        .opacity(showContent ? 1 : 0)
                    
                    Text("Loved by Families Everywhere")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(theme.textColor)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                }
                
                Spacer()
                    .frame(height: 48)
                
                VStack(spacing: 20) {
                    SocialStatCard(
                        value: animatedStats[0],
                        suffix: "+",
                        label: "Families Preserving Memories",
                        icon: "house.fill"
                    )
                    
                    SocialStatCard(
                        value: animatedStats[1],
                        suffix: "+",
                        label: "Stories Captured",
                        icon: "book.fill"
                    )
                    
                    SocialStatCard(
                        value: animatedStats[2],
                        suffix: "%",
                        label: "Would Recommend to Friends",
                        icon: "heart.fill"
                    )
                }
                .padding(.horizontal, 24)
                .opacity(showContent ? 1 : 0)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 16))
                    Text("App Store Editors' Choice")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(theme.secondaryTextColor)
                .opacity(showContent ? 1 : 0)
                .padding(.bottom, 16)
                
                OnboardingCTAButton(
                    title: "Continue",
                    action: { coordinator.goToNextStep() }
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
            
            animateStats()
        }
    }
    
    private func animateStats() {
        let duration: Double = 1.5
        let steps = 30
        let interval = duration / Double(steps)
        
        for step in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(step)) {
                let progress = Double(step) / Double(steps)
                let eased = 1 - pow(1 - progress, 3)
                
                withAnimation(.none) {
                    animatedStats[0] = Int(Double(targetStats[0]) * eased)
                    animatedStats[1] = Int(Double(targetStats[1]) * eased)
                    animatedStats[2] = Int(Double(targetStats[2]) * eased)
                }
            }
        }
    }
}

private struct SocialStatCard: View {
    let value: Int
    let suffix: String
    let label: String
    let icon: String
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(theme.accentColor.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(theme.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 0) {
                    Text(formatNumber(value))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textColor)
                    
                    Text(suffix)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(theme.accentColor)
                }
                
                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(theme.secondaryTextColor)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackgroundColor)
        )
    }
    
    private func formatNumber(_ num: Int) -> String {
        if num >= 1000000 {
            return String(format: "%.1fM", Double(num) / 1000000)
        } else if num >= 1000 {
            return String(format: "%.0fK", Double(num) / 1000)
        }
        return "\(num)"
    }
}

#Preview {
    PitchSocialProof1ScreenView(coordinator: .preview)
        .themed(LightTheme())
}
