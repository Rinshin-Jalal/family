import SwiftUI

struct RecordRevealScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var showTranscript = false
    @State private var showWisdom = false
    
    private let sampleTranscript = "So there I was, 18 years old, stepping off the boat in New York Harbor. I remember looking up at the Statue of Liberty and thinking, 'This is it. This is where our new life begins.' We had nothing but the clothes on our backs and twenty dollars in my father's pocket. But you know what? We had each other, and that's all that mattered."
    
    private let extractedWisdom = "Family bonds matter more than material wealth"
    
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
                                
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(theme.accentColor)
                            }
                            .opacity(showContent ? 1 : 0)
                            .scaleEffect(showContent ? 1 : 0.5)
                            
                            Text("Your Story")
                                .font(theme.headlineFont)
                                .foregroundColor(theme.textColor)
                                .opacity(showContent ? 1 : 0)
                            
                            HStack(spacing: 8) {
                                Label("Grandma", systemImage: "person.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color.storytellerOrange)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.storytellerOrange.opacity(0.15))
                                    .clipShape(Capsule())
                                
                                Text("•")
                                    .foregroundColor(theme.secondaryTextColor)
                                
                                Text("2:34")
                                    .font(.system(size: 14))
                                    .foregroundColor(theme.secondaryTextColor)
                            }
                            .opacity(showContent ? 1 : 0)
                        }
                        .padding(.top, 24)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "text.quote")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(theme.accentColor)
                                
                                Text("TRANSCRIPT")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(theme.accentColor)
                                    .tracking(0.5)
                            }
                            
                            Text(sampleTranscript)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(theme.textColor)
                                .lineSpacing(6)
                                .italic()
                        }
                        .padding(20)
                        .background(theme.cardBackgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 24)
                        .opacity(showTranscript ? 1 : 0)
                        .offset(y: showTranscript ? 0 : 20)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.purple)
                                
                                Text("WISDOM EXTRACTED")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.purple)
                                    .tracking(0.5)
                            }
                            
                            Text("\"\(extractedWisdom)\"")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(theme.textColor)
                            
                            HStack(spacing: 8) {
                                WisdomTag(text: "Family", color: .blue)
                                WisdomTag(text: "Values", color: .green)
                                WisdomTag(text: "Immigration", color: .orange)
                            }
                        }
                        .padding(20)
                        .background(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.1), Color.purple.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal, 24)
                        .opacity(showWisdom ? 1 : 0)
                        .offset(y: showWisdom ? 0 : 20)
                        
                        Spacer(minLength: 120)
                    }
                }
                
                VStack(spacing: 12) {
                    OnboardingCTAButton(
                        title: "Continue",
                        action: {
                            coordinator.goToStep(.recordTags)
                        }
                    )
                    
                    OnboardingSecondaryButton(
                        title: "Re-record Story",
                        action: {
                            coordinator.goToStep(.recordQuestion)
                        }
                    )
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
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showTranscript = true
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showWisdom = true
                }
            }
        }
    }
}

private struct WisdomTag: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

#Preview {
    RecordRevealScreenView(coordinator: .preview)
        .themed(LightTheme())
}
