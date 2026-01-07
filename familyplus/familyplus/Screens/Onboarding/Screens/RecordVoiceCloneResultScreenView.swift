import SwiftUI

struct RecordVoiceCloneResultScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var isPlaying = false
    @State private var waveformAnimation = false
    @State private var sparkleRotation: Double = 0
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 28) {
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.1))
                            .frame(width: 140, height: 140)
                        
                        ForEach(0..<6) { i in
                            Image(systemName: "sparkle")
                                .font(.system(size: 12))
                                .foregroundColor(.purple.opacity(0.5))
                                .offset(y: -60)
                                .rotationEffect(.degrees(Double(i) * 60 + sparkleRotation))
                        }
                        
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 100, height: 100)
                        
                        if isPlaying {
                            HStack(spacing: 3) {
                                ForEach(0..<5) { i in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.white)
                                        .frame(width: 4, height: waveformAnimation ? CGFloat.random(in: 15...35) : 15)
                                }
                            }
                        } else {
                            Image(systemName: "waveform")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .opacity(showContent ? 1 : 0)
                    .scaleEffect(showContent ? 1 : 0.5)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isPlaying.toggle()
                        }
                    }
                    
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.green)
                            
                            Text("Voice Clone Ready!")
                                .font(theme.headlineFont)
                                .foregroundColor(theme.textColor)
                        }
                        
                        Text("Hear your loved one read their own words")
                            .font(theme.bodyFont)
                            .foregroundColor(theme.secondaryTextColor)
                    }
                    .opacity(showContent ? 1 : 0)
                    
                    VStack(spacing: 12) {
                        Text("\"October 15, 1985 - Dear Diary,\ntoday I stepped off the boat in New York...\"")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(theme.textColor)
                            .italic()
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                        
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.purple)
                                .frame(width: 8, height: 8)
                            
                            Text("in Grandpa's voice")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.purple)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.purple.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isPlaying.toggle()
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 16))
                            
                            Text(isPlaying ? "Pause" : "Play Sample")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.purple)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 28)
                        .background(Color.purple.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    .opacity(showContent ? 1 : 0)
                }
                
                Spacer()
                
                OnboardingCTAButton(
                    title: "Continue",
                    action: {
                        coordinator.goToNextStep()
                    }
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
            
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                sparkleRotation = 360
            }
            
            withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
                waveformAnimation = true
            }
        }
    }
}

#Preview {
    RecordVoiceCloneResultScreenView(coordinator: .preview)
        .themed(LightTheme())
}
