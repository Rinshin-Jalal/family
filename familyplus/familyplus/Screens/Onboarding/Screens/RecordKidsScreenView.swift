import SwiftUI

struct RecordKidsScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var showFeatures: [Bool] = [false, false, false]
    @State private var bounceAnimation = false
    
    private let features: [(icon: String, title: String, description: String)] = [
        ("headphones", "Listen Anywhere", "Perfect for car rides and bedtime"),
        ("sparkles", "Fun Sound Effects", "Ambient sounds bring stories to life"),
        ("captions.bubble", "Read Along Mode", "See words as they're spoken")
    ]
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(Color.playfulOrange.opacity(0.15))
                            .frame(width: 120, height: 120)
                            .scaleEffect(bounceAnimation ? 1.1 : 1.0)
                        
                        Circle()
                            .fill(Color.playfulOrange.opacity(0.2))
                            .frame(width: 90, height: 90)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 44, weight: .medium))
                            .foregroundColor(.playfulOrange)
                            .rotationEffect(.degrees(bounceAnimation ? 10 : -10))
                    }
                    .opacity(showContent ? 1 : 0)
                    .scaleEffect(showContent ? 1 : 0.5)
                    
                    VStack(spacing: 8) {
                        Text("For Kids!")
                            .font(theme.headlineFont)
                            .foregroundColor(theme.textColor)
                        
                        Text("Turn grandma's story into a podcast\nthe kids will actually love")
                            .font(theme.bodyFont)
                            .foregroundColor(theme.secondaryTextColor)
                            .multilineTextAlignment(.center)
                    }
                    .opacity(showContent ? 1 : 0)
                    
                    VStack(spacing: 14) {
                        ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                            KidsFeatureCard(
                                icon: feature.icon,
                                title: feature.title,
                                description: feature.description,
                                isVisible: showFeatures[index]
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    HStack(spacing: 8) {
                        ForEach(0..<5) { i in
                            Image(systemName: "star.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.yellow)
                        }
                        Text("Kids love it!")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.secondaryTextColor)
                    }
                    .opacity(showContent ? 1 : 0)
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    OnboardingCTAButton(
                        title: "Create Kids Podcast",
                        action: {
                            coordinator.goToNextStep()
                        },
                        icon: "wand.and.stars",
                        style: .custom(Color.playfulOrange)
                    )
                    
                    OnboardingSecondaryButton(
                        title: "Maybe later",
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
            
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                bounceAnimation = true
            }
            
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4 + Double(i) * 0.12) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showFeatures[i] = true
                    }
                }
            }
        }
    }
}

private struct KidsFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let isVisible: Bool
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.playfulOrange.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.playfulOrange)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.textColor)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(theme.secondaryTextColor)
            }
            
            Spacer()
        }
        .padding(14)
        .background(theme.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -30)
    }
}

#Preview {
    RecordKidsScreenView(coordinator: .preview)
        .themed(LightTheme())
}
