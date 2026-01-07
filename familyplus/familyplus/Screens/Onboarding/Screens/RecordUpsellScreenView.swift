import SwiftUI

struct RecordUpsellScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var showFeatures: [Bool] = [false, false, false, false]
    @State private var crownAnimation = false
    
    private let features: [(icon: String, title: String)] = [
        ("infinity", "Unlimited stories"),
        ("waveform.circle.fill", "Voice cloning magic"),
        ("sparkles", "Kids podcasts"),
        ("brain.head.profile", "AI wisdom summaries")
    ]
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(Color.yellow.opacity(0.15))
                            .frame(width: 120, height: 120)
                            .scaleEffect(crownAnimation ? 1.1 : 1.0)
                        
                        Circle()
                            .fill(Color.yellow.opacity(0.2))
                            .frame(width: 90, height: 90)
                        
                        Image(systemName: "crown.fill")
                            .font(.system(size: 44, weight: .medium))
                            .foregroundColor(.yellow)
                            .shadow(color: .yellow.opacity(0.5), radius: 10)
                    }
                    .opacity(showContent ? 1 : 0)
                    .scaleEffect(showContent ? 1 : 0.5)
                    
                    VStack(spacing: 8) {
                        Text("Unlock Full Access")
                            .font(theme.headlineFont)
                            .foregroundColor(theme.textColor)
                        
                        Text("Preserve every family story forever")
                            .font(theme.bodyFont)
                            .foregroundColor(theme.secondaryTextColor)
                    }
                    .opacity(showContent ? 1 : 0)
                    
                    VStack(spacing: 14) {
                        ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                            PremiumFeatureRow(
                                icon: feature.icon,
                                title: feature.title,
                                isVisible: showFeatures[index]
                            )
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    VStack(spacing: 6) {
                        Text("30-Day Free Trial")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(theme.textColor)
                        
                        Text("Then $9.99/month • Cancel anytime")
                            .font(.system(size: 14))
                            .foregroundColor(theme.secondaryTextColor)
                    }
                    .opacity(showContent ? 1 : 0)
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    OnboardingCTAButton(
                        title: "Start Free Trial",
                        action: {
                            coordinator.completeOnboarding()
                        },
                        icon: "sparkles"
                    )
                    
                    Button(action: {
                        coordinator.completeOnboarding()
                    }) {
                        Text("Maybe Later")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(theme.secondaryTextColor)
                    }
                    .padding(.vertical, 8)
                    
                    HStack(spacing: 16) {
                        Text("Terms")
                        Text("•")
                        Text("Privacy")
                        Text("•")
                        Text("Restore")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(theme.secondaryTextColor.opacity(0.7))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
            
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                crownAnimation = true
            }
            
            for i in 0..<4 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4 + Double(i) * 0.1) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showFeatures[i] = true
                    }
                }
            }
        }
    }
}

private struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let isVisible: Bool
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(.green)
            
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(theme.accentColor)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.textColor)
            }
            
            Spacer()
        }
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -20)
    }
}

#Preview {
    RecordUpsellScreenView(coordinator: .preview)
        .themed(LightTheme())
}
