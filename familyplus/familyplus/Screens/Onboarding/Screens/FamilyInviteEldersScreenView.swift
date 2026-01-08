import SwiftUI

struct FamilyInviteEldersScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var floatOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.storytellerElder.opacity(0.1))
                        .frame(width: 180, height: 180)
                    
                    Circle()
                        .fill(Color.storytellerElder.opacity(0.15))
                        .frame(width: 140, height: 140)
                    
                    ZStack {
                        Circle()
                            .fill(Color.storytellerElder)
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "figure.2.arms.open")
                            .font(.system(size: 44))
                            .foregroundColor(.white)
                    }
                    .offset(y: floatOffset)
                }
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.8)
                
                Spacer()
                    .frame(height: 40)
                
                VStack(spacing: 16) {
                    Text("Invite Grandparents")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(theme.textColor)
                    
                    Text("They hold the stories that matter most")
                        .font(.system(size: 17))
                        .foregroundColor(theme.secondaryTextColor)
                }
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                
                Spacer()
                    .frame(height: 32)
                
                VStack(spacing: 12) {
                    InviteFeatureRow(icon: "phone.fill", text: "They don't need the app")
                    InviteFeatureRow(icon: "sparkles", text: "AI calls them to collect stories")
                    InviteFeatureRow(icon: "clock.fill", text: "Just 10 minutes per call")
                }
                .padding(.horizontal, 32)
                .opacity(showContent ? 1 : 0)
                
                Spacer()
                
                VStack(spacing: 12) {
                    OnboardingCTAButton(
                        title: "Invite Grandparents",
                        action: {
                            coordinator.goToNextStep()
                        }
                    )
                    
                    Button {
                        coordinator.goToNextStep()
                    } label: {
                        Text("Skip for now")
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
            
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                floatOffset = -8
            }
        }
    }
}

private struct InviteFeatureRow: View {
    let icon: String
    let text: String
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color.storytellerElder)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(theme.textColor)
            
            Spacer()
        }
    }
}

#Preview {
    FamilyInviteEldersScreenView(coordinator: .preview)
        .themed(LightTheme())
}
