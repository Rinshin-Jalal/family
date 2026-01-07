import SwiftUI

struct PitchSolutionScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var showFeatures = false
    @State private var logoScale: CGFloat = 0.5
    @State private var glowOpacity: CGFloat = 0
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(theme.accentColor.opacity(0.1))
                        .frame(width: 180, height: 180)
                        .scaleEffect(glowOpacity > 0 ? 1.3 : 1)
                        .opacity(glowOpacity * 0.5)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [theme.accentColor, theme.accentColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .shadow(color: theme.accentColor.opacity(0.4), radius: 30, x: 0, y: 15)
                    
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.white)
                }
                .scaleEffect(logoScale)
                .opacity(showContent ? 1 : 0)
                
                Spacer()
                    .frame(height: 40)
                
                VStack(spacing: 16) {
                    Text("Introducing StoryRd")
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundColor(theme.textColor)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                    
                    Text("The easiest way to preserve your\nfamily wisdom for generations")
                        .font(theme.bodyFont)
                        .foregroundColor(theme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                    .frame(height: 32)
                
                VStack(spacing: 12) {
                    SolutionFeatureRow(
                        icon: "mic.fill",
                        text: "Record stories in any format",
                        delay: 0.0,
                        show: showFeatures
                    )
                    SolutionFeatureRow(
                        icon: "sparkles",
                        text: "AI enhances and organizes",
                        delay: 0.15,
                        show: showFeatures
                    )
                    SolutionFeatureRow(
                        icon: "person.3.fill",
                        text: "Share with your whole family",
                        delay: 0.3,
                        show: showFeatures
                    )
                    SolutionFeatureRow(
                        icon: "infinity",
                        text: "Preserved forever",
                        delay: 0.45,
                        show: showFeatures
                    )
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                OnboardingCTAButton(
                    title: "See How It Works",
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
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.3)) {
                logoScale = 1
            }
            
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.5)) {
                glowOpacity = 1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showFeatures = true
            }
        }
    }
}

private struct SolutionFeatureRow: View {
    let icon: String
    let text: String
    let delay: Double
    let show: Bool
    
    @Environment(\.theme) private var theme
    @State private var appeared = false
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(theme.accentColor.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(theme.accentColor)
            }
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(theme.textColor)
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.5)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(theme.cardBackgroundColor)
        )
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : -30)
        .onChange(of: show) { _, newValue in
            if newValue {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                    appeared = true
                }
            }
        }
    }
}

#Preview {
    PitchSolutionScreenView(coordinator: .preview)
        .themed(LightTheme())
}
