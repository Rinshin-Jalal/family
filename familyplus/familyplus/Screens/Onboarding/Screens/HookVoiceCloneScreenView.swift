import SwiftUI

struct HookVoiceCloneScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var wavePhase: CGFloat = 0
    @State private var isPlaying = false
    @State private var playProgress: CGFloat = 0
    
    private let storyText = "\"When I was your age, we used to walk five miles to school, uphill both ways...\""
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            VoiceWavesBackground(phase: wavePhase)
                .opacity(0.1)
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 24) {
                    HStack(spacing: 40) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(theme.cardBackgroundColor)
                                    .frame(width: 80, height: 80)
                                    .shadow(color: .black.opacity(0.1), radius: 10)
                                
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(theme.secondaryTextColor)
                            }
                            
                            Text("Written")
                                .font(.caption)
                                .foregroundColor(theme.secondaryTextColor)
                        }
                        .opacity(showContent ? 1 : 0)
                        .offset(x: showContent ? 0 : -30)
                        
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.right")
                                .font(.title2)
                                .foregroundColor(theme.accentColor)
                            
                            Text("AI")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(theme.accentColor)
                                )
                        }
                        .opacity(showContent ? 1 : 0)
                        
                        VStack(spacing: 8) {
                            ZStack {
                                if isPlaying {
                                    ForEach(0..<3, id: \.self) { i in
                                        Circle()
                                            .stroke(Color.storytellerOrange.opacity(0.3 - Double(i) * 0.1), lineWidth: 2)
                                            .frame(width: 80 + CGFloat(i) * 20, height: 80 + CGFloat(i) * 20)
                                            .scaleEffect(isPlaying ? 1.2 : 1)
                                            .opacity(isPlaying ? 0 : 1)
                                            .animation(
                                                .easeOut(duration: 1.5)
                                                .repeatForever(autoreverses: false)
                                                .delay(Double(i) * 0.3),
                                                value: isPlaying
                                            )
                                    }
                                }
                                
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.storytellerOrange, Color.storytellerOrange.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                    .shadow(color: Color.storytellerOrange.opacity(0.4), radius: 15)
                                
                                Text("G")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            Text("Grandpa's Voice")
                                .font(.caption)
                                .foregroundColor(theme.textColor)
                                .fontWeight(.medium)
                        }
                        .opacity(showContent ? 1 : 0)
                        .offset(x: showContent ? 0 : 30)
                    }
                    
                    VoicePlayerCard(
                        text: storyText,
                        isPlaying: $isPlaying,
                        progress: $playProgress
                    )
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 30)
                }
                .padding(.horizontal, 24)
                
                Spacer()
                    .frame(height: 48)
                
                VStack(spacing: 16) {
                    Text("Hear their voice again")
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundColor(theme.textColor)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                    
                    Text("Written words come alive in your\nloved one's own voice")
                        .font(theme.bodyFont)
                        .foregroundColor(theme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                    .frame(height: 24)
                
                HStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.green)
                    Text("Voice data stays private & secure")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
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
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
            
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                wavePhase = .pi * 2
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isPlaying = true
                withAnimation(.linear(duration: 8)) {
                    playProgress = 1
                }
            }
        }
    }
}

private struct VoiceWavesBackground: View {
    let phase: CGFloat
    
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let width = geo.size.width
                let height = geo.size.height
                let midY = height / 2
                
                path.move(to: CGPoint(x: 0, y: midY))
                
                for x in stride(from: 0, to: width, by: 2) {
                    let relativeX = x / width
                    let sine = sin(relativeX * .pi * 4 + phase)
                    let y = midY + sine * 50
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(Color.storytellerOrange, lineWidth: 3)
        }
    }
}

private struct VoicePlayerCard: View {
    let text: String
    @Binding var isPlaying: Bool
    @Binding var progress: CGFloat
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 16) {
            Text(text)
                .font(.system(size: 16, design: .serif))
                .foregroundColor(theme.textColor)
                .italic()
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            HStack(spacing: 3) {
                ForEach(0..<30, id: \.self) { i in
                    VoiceCloneWaveformBar(
                        index: i,
                        isPlaying: isPlaying,
                        progress: progress
                    )
                }
            }
            .frame(height: 40)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(theme.cardBackgroundColor)
                        .frame(height: 4)
                    
                    Capsule()
                        .fill(Color.storytellerOrange)
                        .frame(width: geo.size.width * progress, height: 4)
                }
            }
            .frame(height: 4)
            
            HStack {
                Text(formatTime(progress * 45))
                    .font(.caption2)
                    .foregroundColor(theme.secondaryTextColor)
                Spacer()
                Text("0:45")
                    .font(.caption2)
                    .foregroundColor(theme.secondaryTextColor)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.cardBackgroundColor)
                .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 10)
        )
    }
    
    private func formatTime(_ seconds: CGFloat) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

private struct VoiceCloneWaveformBar: View {
    let index: Int
    let isPlaying: Bool
    let progress: CGFloat
    
    @State private var animatedHeight: CGFloat = 0.3
    
    var body: some View {
        let isActive = CGFloat(index) / 30.0 < progress
        
        RoundedRectangle(cornerRadius: 2)
            .fill(isActive ? Color.storytellerOrange : Color.gray.opacity(0.3))
            .frame(width: 4, height: isPlaying && isActive ? animatedHeight * 40 : 8)
            .onAppear {
                if isPlaying {
                    withAnimation(
                        .easeInOut(duration: 0.3)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.05)
                    ) {
                        animatedHeight = CGFloat.random(in: 0.3...1.0)
                    }
                }
            }
    }
}

#Preview {
    HookVoiceCloneScreenView(coordinator: .preview)
        .themed(LightTheme())
}
