import SwiftUI

struct RecordQuestionScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var showQuestions: [Bool] = [false, false, false, false, false]
    @State private var selectedIndex: Int? = nil
    
    private let questions: [(icon: String, text: String, category: String)] = [
        ("heart.fill", "What's your earliest memory?", "Childhood"),
        ("heart.text.square.fill", "Tell us about your wedding day", "Love"),
        ("house.fill", "What was it like growing up?", "Family"),
        ("lightbulb.fill", "What's a lesson you learned the hard way?", "Wisdom"),
        ("person.2.fill", "Tell us about your parents", "Heritage")
    ]
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(theme.accentColor.opacity(0.1))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "questionmark.bubble.fill")
                                    .font(.system(size: 36, weight: .medium))
                                    .foregroundColor(theme.accentColor)
                            }
                            .opacity(showContent ? 1 : 0)
                            .scaleEffect(showContent ? 1 : 0.5)
                            
                            Text("Pick a Question")
                                .font(theme.headlineFont)
                                .foregroundColor(theme.textColor)
                                .opacity(showContent ? 1 : 0)
                            
                            Text("Choose a prompt to guide your story")
                                .font(theme.bodyFont)
                                .foregroundColor(theme.secondaryTextColor)
                                .opacity(showContent ? 1 : 0)
                        }
                        .padding(.top, 24)
                        
                        VStack(spacing: 12) {
                            ForEach(Array(questions.enumerated()), id: \.offset) { index, question in
                                QuestionCard(
                                    icon: question.icon,
                                    text: question.text,
                                    category: question.category,
                                    isSelected: selectedIndex == index,
                                    isVisible: showQuestions[index]
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedIndex = index
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 120)
                    }
                }
                
                VStack(spacing: 12) {
                    OnboardingCTAButton(
                        title: "Continue",
                        action: {
                            if let index = selectedIndex {
                                coordinator.selectQuestion(OnboardingPrompt(text: questions[index].text))
                            }
                        }
                    )
                    .opacity(selectedIndex != nil ? 1 : 0.5)
                    .disabled(selectedIndex == nil)
                    
                    Button(action: {
                        coordinator.goToStep(.recordTips)
                    }) {
                        Text("Or ask your own question")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(theme.accentColor)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .background(
                    LinearGradient(
                        colors: [theme.backgroundColor.opacity(0), theme.backgroundColor],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 60)
                    .offset(y: -60),
                    alignment: .top
                )
                .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
            
            for i in 0..<5 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(i) * 0.08) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showQuestions[i] = true
                    }
                }
            }
        }
    }
}

private struct QuestionCard: View {
    let icon: String
    let text: String
    let category: String
    let isSelected: Bool
    let isVisible: Bool
    let action: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isSelected ? theme.accentColor : theme.accentColor.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isSelected ? .white : theme.accentColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(theme.accentColor.opacity(0.7))
                        .tracking(0.5)
                    
                    Text(text)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.textColor)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(theme.accentColor)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.cardBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? theme.accentColor : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.02 : 1)
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
    }
}

#Preview {
    RecordQuestionScreenView(coordinator: .preview)
        .themed(LightTheme())
}
