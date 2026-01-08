import SwiftUI

struct HookPodcastScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var isPlaying = false
    @State private var playProgress: CGFloat = 0
    @State private var currentEpisode = 0
    
    private let episodes = [
        ("How We Met", "Grandma & Grandpa", "12:34", Color.storytellerElder),
        ("Summer of '85", "Dad", "8:21", Color.storytellerParent),
        ("My First Day", "Everyone", "15:47", Color.storytellerTeen)
    ]
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                PodcastPlayerCard(
                    episodes: episodes,
                    currentEpisode: $currentEpisode,
                    isPlaying: $isPlaying,
                    progress: $playProgress
                )
                .padding(.horizontal, 24)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)
                
                Spacer()
                    .frame(height: 48)
                
                VStack(spacing: 16) {
                    Text("Your family podcast")
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundColor(theme.textColor)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                    
                    Text("AI turns your stories into a beautiful\npodcast you can listen to anywhere")
                        .font(theme.bodyFont)
                        .foregroundColor(theme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                    .frame(height: 24)
                
                HStack(spacing: 20) {
                    PlatformBadge(icon: "applelogo", name: "Podcasts")
                    PlatformBadge(icon: "headphones", name: "Spotify")
                    PlatformBadge(icon: "antenna.radiowaves.left.and.right", name: "RSS")
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
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isPlaying = true
                withAnimation(.linear(duration: 12)) {
                    playProgress = 1
                }
            }
        }
    }
}

private struct PodcastPlayerCard: View {
    let episodes: [(String, String, String, Color)]
    @Binding var currentEpisode: Int
    @Binding var isPlaying: Bool
    @Binding var progress: CGFloat
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [episodes[currentEpisode].3, episodes[currentEpisode].3.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 200)
                
                VStack(spacing: 16) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                        .scaleEffect(isPlaying ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isPlaying)
                    
                    Text("The Family Story")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                    
                    Text("Episode \(currentEpisode + 1) of \(episodes.count)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text(episodes[currentEpisode].0)
                        .font(.headline)
                        .foregroundColor(theme.textColor)
                    
                    Text("Told by \(episodes[currentEpisode].1)")
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryTextColor)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 4)
                        
                        Capsule()
                            .fill(episodes[currentEpisode].3)
                            .frame(width: geo.size.width * progress, height: 4)
                    }
                }
                .frame(height: 4)
                
                HStack {
                    Text(formatProgress(progress, duration: episodes[currentEpisode].2))
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                    
                    Spacer()
                    
                    HStack(spacing: 24) {
                        Button(action: {
                            withAnimation {
                                currentEpisode = max(0, currentEpisode - 1)
                            }
                        }) {
                            Image(systemName: "backward.fill")
                                .font(.title3)
                                .foregroundColor(theme.textColor)
                        }
                        
                        Button(action: { isPlaying.toggle() }) {
                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(episodes[currentEpisode].3)
                        }
                        
                        Button(action: {
                            withAnimation {
                                currentEpisode = min(episodes.count - 1, currentEpisode + 1)
                            }
                        }) {
                            Image(systemName: "forward.fill")
                                .font(.title3)
                                .foregroundColor(theme.textColor)
                        }
                    }
                    
                    Spacer()
                    
                    Text(episodes[currentEpisode].2)
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
            }
            .padding(20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.cardBackgroundColor)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
    }
    
    private func formatProgress(_ progress: CGFloat, duration: String) -> String {
        let parts = duration.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return "0:00" }
        let totalSeconds = parts[0] * 60 + parts[1]
        let currentSeconds = Int(CGFloat(totalSeconds) * progress)
        let mins = currentSeconds / 60
        let secs = currentSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

private struct PlatformBadge: View {
    let icon: String
    let name: String
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(theme.accentColor)
            Text(name)
                .font(.caption2)
                .foregroundColor(theme.secondaryTextColor)
        }
        .frame(width: 80, height: 70)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.cardBackgroundColor)
                .shadow(color: .black.opacity(0.05), radius: 8)
        )
    }
}

#Preview {
    HookPodcastScreenView(coordinator: .preview)
        .themed(LightTheme())
}
