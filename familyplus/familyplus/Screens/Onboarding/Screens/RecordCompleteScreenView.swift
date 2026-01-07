import SwiftUI

struct RecordCompleteScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var showCheckmark = false
    @State private var celebrationScale: CGFloat = 0
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.1))
                            .frame(width: 140, height: 140)
                            .scaleEffect(celebrationScale)
                        
                        Circle()
                            .fill(Color.green.opacity(0.15))
                            .frame(width: 100, height: 100)
                            .scaleEffect(celebrationScale * 0.9)
                        
                        Circle()
                            .fill(Color.green)
                            .frame(width: 80, height: 80)
                            .scaleEffect(showCheckmark ? 1 : 0)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(showCheckmark ? 1 : 0)
                            .rotationEffect(.degrees(showCheckmark ? 0 : -90))
                    }
                    
                    VStack(spacing: 12) {
                        Text("Recording Complete!")
                            .font(theme.headlineFont)
                            .foregroundColor(theme.textColor)
                        
                        Text("Great job! Let's see what wisdom\nthe AI finds in your story.")
                            .font(theme.bodyFont)
                            .foregroundColor(theme.secondaryTextColor)
                            .multilineTextAlignment(.center)
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    
                    HStack(spacing: 24) {
                        StatBubble(value: "2:34", label: "Duration", icon: "clock.fill", color: .blue)
                        StatBubble(value: "1", label: "Story", icon: "book.fill", color: .purple)
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                }
                
                Spacer()
                
                OnboardingCTAButton(
                    title: "Continue",
                    action: {
                        coordinator.goToStep(.recordProcessing)
                    },
                    icon: "sparkles"
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            triggerCelebration()
        }
    }
    
    private func triggerCelebration() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            showCheckmark = true
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
            celebrationScale = 1.2
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            showContent = true
        }
    }
}

private struct StatBubble: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(theme.textColor)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(theme.secondaryTextColor)
        }
        .padding(16)
        .background(theme.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    RecordCompleteScreenView(coordinator: .preview)
        .themed(LightTheme())
}
