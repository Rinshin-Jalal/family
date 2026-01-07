import SwiftUI

struct FamilyYourNameScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var name = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(theme.accentColor.opacity(0.1))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "person.fill")
                            .font(.system(size: 44))
                            .foregroundColor(theme.accentColor)
                    }
                    .opacity(showContent ? 1 : 0)
                    .scaleEffect(showContent ? 1 : 0.8)
                    
                    VStack(spacing: 12) {
                        Text("What's Your Name?")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(theme.textColor)
                        
                        Text("This is how you'll appear to family")
                            .font(.system(size: 17))
                            .foregroundColor(theme.secondaryTextColor)
                    }
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1 : 0)
                }
                
                Spacer()
                    .frame(height: 48)
                
                VStack(spacing: 16) {
                    TextField("", text: $name, prompt: Text("Your name").foregroundColor(theme.secondaryTextColor.opacity(0.6)))
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(theme.textColor)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 20)
                        .padding(.horizontal, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(theme.cardBackgroundColor)
                        )
                        .focused($isFocused)
                    
                    if !name.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "hand.wave.fill")
                                .font(.system(size: 16))
                            Text("Hi, \(name)!")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(theme.accentColor)
                        .transition(.opacity.combined(with: .scale))
                    }
                }
                .padding(.horizontal, 24)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                
                Spacer()
                
                OnboardingCTAButton(
                    title: "Continue",
                    action: {
                        coordinator.setUserRole(coordinator.onboardingState.userRole, name: name)
                        coordinator.goToNextStep()
                    }
                )
                .disabled(name.isEmpty)
                .opacity(name.isEmpty ? 0.6 : 1)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
    }
}

#Preview {
    FamilyYourNameScreenView(coordinator: .preview)
        .themed(LightTheme())
}
