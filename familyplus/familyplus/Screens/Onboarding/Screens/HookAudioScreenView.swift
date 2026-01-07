import SwiftUI

struct HookAudioScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var waveformAmplitudes: [CGFloat] = Array(repeating: 0.3, count: 40)
    @State private var isPlaying = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 32) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [theme.accentColor.opacity(0.2), theme.accentColor.opacity(0.05)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                    
                    HStack(spacing: 3) {
                        ForEach(0..<40, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(
                                    LinearGradient(
                                        colors: [theme.accentColor, theme.accentColor.opacity(0.6)],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(width: 3, height: 60 * waveformAmplitudes[index])
                        }
                    }
                    .frame(width: 160, height: 80)
                }
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.8)
                
                VStack(spacing: 16) {
                    Text("Hear their voice")
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundColor(theme.textColor)
                    
                    Text("Feel the story")
                        .font(.system(size: 24, weight: .medium, design: .serif))
                        .foregroundColor(theme.accentColor)
                }
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1 : 0)
                
                VStack(spacing: 8) {
                    Text("Every pause, every laugh, every crack in their voice—")
                        .font(theme.bodyFont)
                        .foregroundColor(theme.secondaryTextColor)
                    
                    Text("that's the story.")
                        .font(theme.bodyFont)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.textColor)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .opacity(showContent ? 1 : 0)
            }
            
            Spacer()
            
            HStack(spacing: 24) {
                VoiceMemoryBubble(name: "Grandma", time: "2:34", theme: theme)
                VoiceMemoryBubble(name: "Dad", time: "1:12", theme: theme)
                VoiceMemoryBubble(name: "You", time: "0:45", theme: theme, isHighlighted: true)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 30)
            
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
            startWaveformAnimation()
        }
    }
    
    private func startWaveformAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.1)) {
                for i in 0..<waveformAmplitudes.count {
                    waveformAmplitudes[i] = CGFloat.random(in: 0.2...1.0)
                }
            }
        }
    }
}

private struct VoiceMemoryBubble: View {
    let name: String
    let time: String
    let theme: PersonaTheme
    var isHighlighted: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isHighlighted ? theme.accentColor : theme.cardBackgroundColor)
                    .frame(width: 56, height: 56)
                
                Image(systemName: "waveform")
                    .font(.title2)
                    .foregroundColor(isHighlighted ? .white : theme.accentColor)
            }
            
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(theme.textColor)
            
            Text(time)
                .font(.caption2)
                .foregroundColor(theme.secondaryTextColor)
        }
    }
}

#Preview {
    HookAudioScreenView(coordinator: OnboardingCoordinator.preview)
        .themed(LightTheme())
}
