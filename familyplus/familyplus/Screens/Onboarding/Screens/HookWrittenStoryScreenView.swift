import SwiftUI

struct HookWrittenStoryScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var transformationProgress: CGFloat = 0
    @State private var showTransformed = false
    
    private let handwrittenLines = [
        "Dear family,",
        "I remember the summer of '62...",
        "Your grandfather proposed under",
        "the old oak tree by the lake."
    ]
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                ZStack {
                    OldDocumentView(
                        lines: handwrittenLines,
                        opacity: 1 - transformationProgress
                    )
                    .opacity(showContent ? 1 : 0)
                    .offset(x: showTransformed ? -300 : 0)
                    
                    DigitalStoryCard(
                        lines: handwrittenLines,
                        progress: transformationProgress
                    )
                    .opacity(transformationProgress)
                    .scaleEffect(0.8 + (transformationProgress * 0.2))
                }
                .frame(height: 320)
                
                Spacer()
                    .frame(height: 40)
                
                VStack(spacing: 16) {
                    Text("Letters become legacy")
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundColor(theme.textColor)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                    
                    Text("Old diaries, letters, and notes\ntransformed into searchable stories")
                        .font(theme.bodyFont)
                        .foregroundColor(theme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                    .frame(height: 24)
                
                HStack(spacing: 12) {
                    FeaturePill(icon: "doc.text.magnifyingglass", text: "OCR Scan")
                    FeaturePill(icon: "sparkles", text: "AI Enhanced")
                    FeaturePill(icon: "magnifyingglass", text: "Searchable")
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                
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
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeInOut(duration: 2.0)) {
                    transformationProgress = 1.0
                }
            }
        }
    }
}

private struct OldDocumentView: View {
    let lines: [String]
    let opacity: Double
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.96, green: 0.93, blue: 0.85),
                            Color(red: 0.92, green: 0.88, blue: 0.78)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 260, height: 300)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 5, y: 5)
                .rotationEffect(.degrees(-3))
            
            VStack(alignment: .leading, spacing: 0) {
                ForEach(0..<12, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(height: 1)
                        .padding(.vertical, 10)
                }
            }
            .frame(width: 220, height: 260)
            .rotationEffect(.degrees(-3))
            
            VStack(alignment: .leading, spacing: 20) {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.custom("Snell Roundhand", size: 18))
                        .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1).opacity(0.8))
                }
            }
            .frame(width: 220, alignment: .leading)
            .rotationEffect(.degrees(-3))
        }
        .opacity(opacity)
    }
}

private struct DigitalStoryCard: View {
    let lines: [String]
    let progress: CGFloat
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Circle()
                    .fill(Color.storytellerOrange)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text("G")
                            .font(.headline)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Grandma Rose")
                        .font(.headline)
                        .foregroundColor(theme.textColor)
                    Text("Summer 1962")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
                
                Spacer()
                
                Image(systemName: "heart.fill")
                    .foregroundColor(.red.opacity(0.8))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.system(size: 15))
                        .foregroundColor(theme.textColor.opacity(0.9))
                }
            }
            
            HStack(spacing: 8) {
                StoryTag(text: "Romance", color: .pink)
                StoryTag(text: "1960s", color: .orange)
                StoryTag(text: "Proposal", color: .purple)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.cardBackgroundColor)
                .shadow(color: theme.accentColor.opacity(0.2), radius: 20, x: 0, y: 10)
        )
        .frame(width: 300)
    }
}

private struct StoryTag: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
            )
    }
}

private struct FeaturePill: View {
    let icon: String
    let text: String
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(theme.accentColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(theme.accentColor.opacity(0.1))
        )
    }
}

#Preview {
    HookWrittenStoryScreenView(coordinator: .preview)
        .themed(LightTheme())
}
