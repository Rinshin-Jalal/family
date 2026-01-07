import SwiftUI

struct HookQuestionScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var currentQuestionIndex = 0
    @State private var isAnimatingQuestion = false
    
    private let sampleQuestions = [
        "What's a lesson your parents taught you that you still live by?",
        "What's a family tradition you hope never dies?",
        "What moment made you proudest of your family?",
        "What story do you wish you'd recorded before it was too late?"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 32) {
                ZStack {
                    Circle()
                        .fill(theme.accentColor.opacity(0.15))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "questionmark.bubble.fill")
                        .font(.system(size: 44))
                        .foregroundColor(theme.accentColor)
                        .symbolEffect(.bounce, value: currentQuestionIndex)
                }
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.8)
                
                VStack(spacing: 16) {
                    Text("Imagine asking...")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.secondaryTextColor)
                        .textCase(.uppercase)
                        .tracking(2)
                    
                    Text("\"\(sampleQuestions[currentQuestionIndex])\"")
                        .font(.system(size: 24, weight: .semibold, design: .serif))
                        .foregroundColor(theme.textColor)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, 24)
                        .opacity(isAnimatingQuestion ? 0 : 1)
                        .offset(y: isAnimatingQuestion ? -20 : 0)
                }
                .frame(minHeight: 150)
                .opacity(showContent ? 1 : 0)
                
                HStack(spacing: 8) {
                    ForEach(0..<sampleQuestions.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentQuestionIndex ? theme.accentColor : theme.secondaryTextColor.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.spring(), value: currentQuestionIndex)
                    }
                }
                .opacity(showContent ? 1 : 0)
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                    Text("AI-powered questions tailored to your family")
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryTextColor)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(
                    Capsule()
                        .fill(theme.cardBackgroundColor)
                )
                .opacity(showContent ? 1 : 0)
            }
            
            Spacer()
            
            OnboardingCTAButton(
                title: "See How It Works",
                action: { coordinator.goToNextStep() }
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
            startQuestionCycle()
        }
    }
    
    private func startQuestionCycle() {
        Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                isAnimatingQuestion = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                currentQuestionIndex = (currentQuestionIndex + 1) % sampleQuestions.count
                withAnimation(.easeInOut(duration: 0.3)) {
                    isAnimatingQuestion = false
                }
            }
        }
    }
}

#Preview {
    HookQuestionScreenView(coordinator: OnboardingCoordinator.preview)
        .themed(LightTheme())
}
