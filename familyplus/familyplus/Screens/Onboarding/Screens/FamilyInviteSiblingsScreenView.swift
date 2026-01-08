import SwiftUI

struct FamilyInviteSiblingsScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.storytellerTeen.opacity(0.1))
                        .frame(width: 160, height: 160)
                    
                    Circle()
                        .fill(Color.storytellerTeen.opacity(0.15))
                        .frame(width: 120, height: 120)
                    
                    ZStack {
                        Circle()
                            .fill(Color.storytellerTeen)
                            .frame(width: 88, height: 88)
                        
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 38))
                            .foregroundColor(.white)
                    }
                }
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.8)
                
                Spacer()
                    .frame(height: 40)
                
                VStack(spacing: 16) {
                    Text("Invite Siblings")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(theme.textColor)
                    
                    Text("Share childhood memories together")
                        .font(.system(size: 17))
                        .foregroundColor(theme.secondaryTextColor)
                }
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                
                Spacer()
                    .frame(height: 32)
                
                VStack(spacing: 12) {
                    SiblingFeatureRow(icon: "bubble.left.and.bubble.right.fill", text: "Remember moments together")
                    SiblingFeatureRow(icon: "puzzlepiece.fill", text: "Fill in each other's gaps")
                    SiblingFeatureRow(icon: "heart.fill", text: "Build your shared legacy")
                }
                .padding(.horizontal, 32)
                .opacity(showContent ? 1 : 0)
                
                Spacer()
                
                VStack(spacing: 12) {
                    OnboardingCTAButton(
                        title: "Invite Siblings",
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
        }
    }
}

private struct SiblingFeatureRow: View {
    let icon: String
    let text: String
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color.storytellerTeen)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(theme.textColor)
            
            Spacer()
        }
    }
}

#Preview {
    FamilyInviteSiblingsScreenView(coordinator: .preview)
        .themed(LightTheme())
}
