import SwiftUI

struct HookFamilyChatScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var messages: [ChatMessage] = []
    @State private var currentMessageIndex = 0
    
    private let chatMessages: [ChatMessage] = [
        ChatMessage(sender: "Grandma", text: "We drove across the country in a Chevy...", avatar: "person.crop.circle.fill", color: .orange),
        ChatMessage(sender: "Dad", text: "Actually Mom, it was a Ford! 😄", avatar: "person.crop.circle.fill", color: .blue),
        ChatMessage(sender: "You", text: "Wait, which one broke down in Nevada?", avatar: "person.crop.circle.fill", color: .purple),
        ChatMessage(sender: "Grandma", text: "Oh! That's a whole other story...", avatar: "person.crop.circle.fill", color: .orange)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Family stories aren't monologues")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(theme.textColor)
                    
                    Text("They're conversations")
                        .font(.system(size: 24, weight: .medium, design: .serif))
                        .foregroundColor(theme.accentColor)
                }
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1 : 0)
                
                VStack(spacing: 12) {
                    ForEach(Array(messages.enumerated()), id: \.offset) { index, message in
                        ChatBubbleView(message: message, isRight: message.sender == "You")
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                }
                .frame(maxWidth: 320)
                .padding(.vertical, 20)
                .opacity(showContent ? 1 : 0)
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "person.3.fill")
                        .foregroundColor(theme.accentColor)
                    Text("Everyone adds their perspective")
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryTextColor)
                }
                
                Text("The truth lives in the disagreements")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.cardBackgroundColor)
            )
            .opacity(showContent ? 1 : 0)
            
            Spacer()
            
            OnboardingCTAButton(
                title: "Continue",
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
            startChatAnimation()
        }
    }
    
    private func startChatAnimation() {
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { timer in
            if currentMessageIndex < chatMessages.count {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    messages.append(chatMessages[currentMessageIndex])
                    currentMessageIndex += 1
                }
            } else {
                timer.invalidate()
            }
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let sender: String
    let text: String
    let avatar: String
    let color: Color
}

struct ChatBubbleView: View {
    let message: ChatMessage
    var isRight: Bool = false
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isRight { Spacer() }
            
            if !isRight {
                Circle()
                    .fill(message.color.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: message.avatar)
                            .font(.system(size: 16))
                            .foregroundColor(message.color)
                    )
            }
            
            VStack(alignment: isRight ? .trailing : .leading, spacing: 4) {
                Text(message.sender)
                    .font(.caption)
                    .foregroundColor(message.color)
                
                Text(message.text)
                    .font(.subheadline)
                    .foregroundColor(theme.textColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(isRight ? message.color.opacity(0.15) : theme.cardBackgroundColor)
                    )
            }
            
            if isRight {
                Circle()
                    .fill(message.color.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: message.avatar)
                            .font(.system(size: 16))
                            .foregroundColor(message.color)
                    )
            }
            
            if !isRight { Spacer() }
        }
    }
}

#Preview {
    HookFamilyChatScreenView(coordinator: OnboardingCoordinator.preview)
        .themed(LightTheme())
}
