import SwiftUI

struct HookQuoteScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var currentQuoteIndex = 0
    @State private var showShareSheet = false
    
    private let quotes: [(String, String, Color)] = [
        ("The best things in life are the people you love and the memories you make.", "Grandma Rose", Color.storytellerOrange),
        ("Work hard, be kind, and amazing things will happen.", "Dad", Color.storytellerBlue),
        ("Home is wherever we are together.", "Mom", Color.storytellerGreen),
        ("Every day is a gift. That is why they call it the present.", "Grandpa Joe", Color.storytellerPurple)
    ]
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                ZStack {
                    ForEach(0..<quotes.count, id: \.self) { index in
                        QuoteCardView(
                            quote: quotes[index].0,
                            author: quotes[index].1,
                            color: quotes[index].2
                        )
                        .opacity(index == currentQuoteIndex ? 1 : 0)
                        .scaleEffect(index == currentQuoteIndex ? 1 : 0.9)
                        .rotation3DEffect(
                            .degrees(index == currentQuoteIndex ? 0 : 90),
                            axis: (x: 0, y: 1, z: 0)
                        )
                    }
                }
                .padding(.horizontal, 24)
                .frame(height: 340)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)
                
                HStack(spacing: 24) {
                    ShareActionButtonView(icon: "square.and.arrow.up", label: "Share")
                    ShareActionButtonView(icon: "photo.on.rectangle", label: "Save")
                    ShareActionButtonView(icon: "message.fill", label: "Send")
                }
                .padding(.top, 24)
                .opacity(showContent ? 1 : 0)
                
                Spacer()
                    .frame(height: 40)
                
                VStack(spacing: 16) {
                    Text("Wisdom worth sharing")
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundColor(theme.textColor)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                    
                    Text("Turn memorable quotes into beautiful\nimages to share with family & friends")
                        .font(theme.bodyFont)
                        .foregroundColor(theme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                }
                .padding(.horizontal, 32)
                
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
            
            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    currentQuoteIndex = (currentQuoteIndex + 1) % quotes.count
                }
            }
        }
    }
}

private struct QuoteCardView: View {
    let quote: String
    let author: String
    let color: Color
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "quote.opening")
                .font(.system(size: 40))
                .foregroundColor(color.opacity(0.3))
            
            Text("\"\(quote)\"")
                .font(.system(size: 22, weight: .medium, design: .serif))
                .foregroundColor(theme.textColor)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
            
            HStack(spacing: 12) {
                Circle()
                    .fill(color)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(author.prefix(1)))
                            .font(.headline)
                            .foregroundColor(.white)
                    )
                
                Text("— \(author)")
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryTextColor)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(theme.cardBackgroundColor)
                .shadow(color: color.opacity(0.2), radius: 20, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

private struct ShareActionButtonView: View {
    let icon: String
    let label: String
    
    @Environment(\.theme) private var theme
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isPressed = false
            }
        }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(theme.accentColor.opacity(0.1))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(theme.accentColor)
                }
                .scaleEffect(isPressed ? 0.9 : 1.0)
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
            }
        }
    }
}

#Preview {
    HookQuoteScreenView(coordinator: .preview)
        .themed(LightTheme())
}
