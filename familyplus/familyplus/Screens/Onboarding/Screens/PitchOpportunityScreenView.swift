import SwiftUI

struct PitchOpportunityScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var clockProgress: CGFloat = 0
    @State private var pulseScale: CGFloat = 1
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .trim(from: 0, to: clockProgress)
                        .stroke(
                            LinearGradient(
                                colors: [Color.storytellerElder, Color.alertRed],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 8) {
                        Image(systemName: "hourglass")
                            .font(.system(size: 40))
                            .foregroundColor(.storytellerElder)
                            .scaleEffect(pulseScale)
                        
                        Text("Limited Time")
                            .font(.headline)
                            .foregroundColor(theme.textColor)
                    }
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)
                
                Spacer()
                    .frame(height: 48)
                
                VStack(spacing: 20) {
                    Text("The window is closing")
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundColor(theme.textColor)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                    
                    Text("Your parents and grandparents\nhold decades of wisdom.\nBut time waits for no one.")
                        .font(theme.bodyFont)
                        .foregroundColor(theme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                    .frame(height: 32)
                
                VStack(spacing: 16) {
                    OpportunityCard(
                        icon: "person.2.fill",
                        title: "Average age of grandparents",
                        value: "72 years",
                        color: .storytellerElder
                    )
                    
                    OpportunityCard(
                        icon: "calendar.badge.clock",
                        title: "Time left to capture stories",
                        value: "~10 years",
                        color: .alertRed
                    )
                }
                .padding(.horizontal, 24)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                
                Spacer()
                
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
            
            withAnimation(.easeInOut(duration: 2).delay(0.5)) {
                clockProgress = 0.75
            }
            
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
        }
    }
}

private struct OpportunityCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryTextColor)
                
                Text(value)
                    .font(.title3.bold())
                    .foregroundColor(color)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackgroundColor)
                .shadow(color: color.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

#Preview {
    PitchOpportunityScreenView(coordinator: .preview)
        .themed(LightTheme())
}
