import SwiftUI

struct RecordShareQuoteScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var showQuotes: [Bool] = [false, false, false]
    @State private var selectedQuote: Int? = nil
    
    private let quotes = [
        "\"So there I was, 18 years old, stepping off the boat...\"",
        "\"We had nothing but we had each other.\"",
        "\"That's all that mattered.\""
    ]
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.purple.opacity(0.1))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "quote.bubble.fill")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(.purple)
                        }
                        .opacity(showContent ? 1 : 0)
                        .scaleEffect(showContent ? 1 : 0.5)
                        
                        Text("Share a Quote")
                            .font(theme.headlineFont)
                            .foregroundColor(theme.textColor)
                            .opacity(showContent ? 1 : 0)
                        
                        Text("Pick a memorable moment to share")
                            .font(theme.bodyFont)
                            .foregroundColor(theme.secondaryTextColor)
                            .opacity(showContent ? 1 : 0)
                    }
                    
                    VStack(spacing: 12) {
                        ForEach(Array(quotes.enumerated()), id: \.offset) { index, quote in
                            ShareableQuoteCard(
                                quote: quote,
                                isSelected: selectedQuote == index,
                                isVisible: showQuotes[index]
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedQuote = index
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    if selectedQuote != nil {
                        HStack(spacing: 16) {
                            ShareOption(icon: "message.fill", label: "iMessage", color: .green)
                            ShareOption(icon: "square.and.arrow.up", label: "Share", color: .blue)
                            ShareOption(icon: "doc.on.doc", label: "Copy", color: .orange)
                        }
                        .opacity(showContent ? 1 : 0)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    OnboardingCTAButton(
                        title: selectedQuote != nil ? "Share Quote" : "Select a Quote",
                        action: {
                            coordinator.goToNextStep()
                        },
                        icon: selectedQuote != nil ? "square.and.arrow.up" : nil
                    )
                    .opacity(selectedQuote != nil ? 1 : 0.5)
                    .disabled(selectedQuote == nil)
                    
                    OnboardingSecondaryButton(
                        title: "Skip",
                        action: {
                            coordinator.goToNextStep()
                        }
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
            
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(i) * 0.12) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showQuotes[i] = true
                    }
                }
            }
        }
    }
}

private struct ShareableQuoteCard: View {
    let quote: String
    let isSelected: Bool
    let isVisible: Bool
    let action: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(quote)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.textColor)
                    .italic()
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.purple)
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.purple.opacity(0.1) : theme.cardBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
    }
}

private struct ShareOption: View {
    let icon: String
    let label: String
    let color: Color
    
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
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    RecordShareQuoteScreenView(coordinator: .preview)
        .themed(LightTheme())
}
