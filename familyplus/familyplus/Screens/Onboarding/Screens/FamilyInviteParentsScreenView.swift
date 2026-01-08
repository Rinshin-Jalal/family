import SwiftUI

struct FamilyInviteParentsScreenView: View {
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
                        .fill(Color.storytellerParent.opacity(0.1))
                        .frame(width: 160, height: 160)
                    
                    Circle()
                        .fill(Color.storytellerParent.opacity(0.15))
                        .frame(width: 120, height: 120)
                    
                    ZStack {
                        Circle()
                            .fill(Color.storytellerParent)
                            .frame(width: 88, height: 88)
                        
                        Image(systemName: "figure.and.child.holdinghands")
                            .font(.system(size: 38))
                            .foregroundColor(.white)
                    }
                }
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.8)
                
                Spacer()
                    .frame(height: 40)
                
                VStack(spacing: 16) {
                    Text("Invite Parents")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(theme.textColor)
                    
                    Text("They can help collect and preserve stories")
                        .font(.system(size: 17))
                        .foregroundColor(theme.secondaryTextColor)
                }
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                
                Spacer()
                    .frame(height: 32)
                
                VStack(spacing: 12) {
                    ParentFeatureRow(icon: "person.badge.plus", text: "Help interview grandparents")
                    ParentFeatureRow(icon: "square.and.pencil", text: "Add their own memories")
                    ParentFeatureRow(icon: "photo.stack", text: "Upload old photos")
                }
                .padding(.horizontal, 32)
                .opacity(showContent ? 1 : 0)
                
                Spacer()
                
                VStack(spacing: 12) {
                    OnboardingCTAButton(
                        title: "Invite Parents",
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

private struct ParentFeatureRow: View {
    let icon: String
    let text: String
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color.storytellerParent)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(theme.textColor)
            
            Spacer()
        }
    }
}

#Preview {
    FamilyInviteParentsScreenView(coordinator: .preview)
        .themed(LightTheme())
}
