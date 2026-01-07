import SwiftUI

struct PitchOfferScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var pulseGift = false
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 180, height: 180)
                        .scaleEffect(pulseGift ? 1.1 : 1.0)
                    
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 140, height: 140)
                    
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.green, Color.green.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "gift.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.white)
                    }
                }
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.8)
                
                Spacer()
                    .frame(height: 40)
                
                VStack(spacing: 16) {
                    Text("Start Free Today")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(theme.textColor)
                    
                    Text("No credit card required")
                        .font(.system(size: 18))
                        .foregroundColor(theme.secondaryTextColor)
                }
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                
                Spacer()
                    .frame(height: 32)
                
                VStack(spacing: 12) {
                    OfferFeatureRow(icon: "checkmark.circle.fill", text: "Unlimited stories for 30 days")
                    OfferFeatureRow(icon: "checkmark.circle.fill", text: "AI transcription & tagging")
                    OfferFeatureRow(icon: "checkmark.circle.fill", text: "Voice cloning included")
                    OfferFeatureRow(icon: "checkmark.circle.fill", text: "Family sharing (up to 10)")
                    OfferFeatureRow(icon: "checkmark.circle.fill", text: "Cancel anytime")
                }
                .padding(.horizontal, 32)
                .opacity(showContent ? 1 : 0)
                
                Spacer()
                    .frame(height: 24)
                
                VStack(spacing: 4) {
                    Text("Then $9.99/month")
                        .font(.system(size: 15))
                        .foregroundColor(theme.secondaryTextColor)
                    
                    Text("Less than a cup of coffee")
                        .font(.system(size: 13))
                        .foregroundColor(theme.secondaryTextColor.opacity(0.7))
                }
                .opacity(showContent ? 1 : 0)
                
                Spacer()
                
                VStack(spacing: 12) {
                    OnboardingCTAButton(
                        title: "Start My Free Trial",
                        action: { coordinator.goToStep(.familyCreateOrJoin) }
                    )
                    
                    Button {
                        coordinator.goToStep(.familyCreateOrJoin)
                    } label: {
                        Text("I'll decide later")
                            .font(.system(size: 16))
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
            
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseGift = true
            }
        }
    }
}

private struct OfferFeatureRow: View {
    let icon: String
    let text: String
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.green)
            
            Text(text)
                .font(.system(size: 17))
                .foregroundColor(theme.textColor)
            
            Spacer()
        }
    }
}

#Preview {
    PitchOfferScreenView(coordinator: .preview)
        .themed(LightTheme())
}
