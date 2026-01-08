import SwiftUI

struct HookKidsScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var showStars = false
    @State private var bounceScale: CGFloat = 1
    @State private var currentStoryIndex = 0
    
    private let kidStories = [
        ("dinosaur.fill", "The Dinosaur Adventure", Color.green),
        ("airplane", "Grandpa's Flying Days", Color.blue),
        ("leaf.fill", "The Magic Garden", Color.orange),
        ("star.fill", "Wishing on Stars", Color.purple)
    ]
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            FloatingStarsBackground(showStars: showStars)
            
            VStack(spacing: 0) {
                Spacer()
                
                ZStack {
                    ForEach(0..<kidStories.count, id: \.self) { index in
                        KidStoryCard(
                            icon: kidStories[index].0,
                            title: kidStories[index].1,
                            color: kidStories[index].2
                        )
                        .scaleEffect(index == currentStoryIndex ? bounceScale : 0.85)
                        .opacity(index == currentStoryIndex ? 1 : 0.3)
                        .offset(x: CGFloat(index - currentStoryIndex) * 280)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentStoryIndex)
                    }
                }
                .frame(height: 280)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)
                
                HStack(spacing: 8) {
                    ForEach(0..<kidStories.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentStoryIndex ? Color.owlGold : Color.gray.opacity(0.3))
                            .frame(width: index == currentStoryIndex ? 10 : 8, height: index == currentStoryIndex ? 10 : 8)
                    }
                }
                .padding(.top, 20)
                .opacity(showContent ? 1 : 0)
                
                Spacer()
                    .frame(height: 40)
                
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.title)
                            .foregroundColor(.owlGold)
                        Text("Made for little listeners")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(theme.textColor)
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    
                    Text("Stories come alive with sounds,\nanimations, and fun surprises!")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundColor(theme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                    .frame(height: 24)
                
                HStack(spacing: 16) {
                    KidFeatureBadge(icon: "speaker.wave.2.fill", text: "Audio")
                    KidFeatureBadge(icon: "sparkles", text: "Fun Effects")
                    KidFeatureBadge(icon: "hand.tap.fill", text: "Interactive")
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
            
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                showStars = true
            }
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5).repeatForever(autoreverses: true)) {
                bounceScale = 1.05
            }
            
            Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
                withAnimation {
                    currentStoryIndex = (currentStoryIndex + 1) % kidStories.count
                }
            }
        }
    }
}

private struct FloatingStarsBackground: View {
    let showStars: Bool
    
    var body: some View {
        GeometryReader { geo in
            ForEach(0..<15, id: \.self) { i in
                Image(systemName: "star.fill")
                    .font(.system(size: CGFloat.random(in: 8...20)))
                    .foregroundColor([Color.owlGold, .yellow, .pink, .purple][i % 4].opacity(0.3))
                    .position(
                        x: CGFloat.random(in: 0...geo.size.width),
                        y: CGFloat.random(in: 0...geo.size.height)
                    )
                    .opacity(showStars ? 1 : 0)
                    .animation(
                        .easeInOut(duration: Double.random(in: 1...2))
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.1),
                        value: showStars
                    )
            }
        }
    }
}

private struct KidStoryCard: View {
    let icon: String
    let title: String
    let color: Color
    
    @State private var wiggle = false
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundColor(color)
                    .rotationEffect(.degrees(wiggle ? 5 : -5))
            }
            
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(Color.white)
                .shadow(color: color.opacity(0.3), radius: 20, x: 0, y: 10)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
                wiggle = true
            }
        }
    }
}

private struct KidFeatureBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.owlGold)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.owlGold.opacity(0.1))
        )
    }
}

#Preview {
    HookKidsScreenView(coordinator: .preview)
        .themed(LightTheme())
}
