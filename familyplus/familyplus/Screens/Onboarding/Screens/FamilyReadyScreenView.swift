import SwiftUI

struct FamilyReadyScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var showCheckmark = false
    @State private var confettiTrigger = false
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            if confettiTrigger {
                ConfettiView()
            }
            
            VStack(spacing: 0) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 180, height: 180)
                        .scaleEffect(showCheckmark ? 1 : 0)
                    
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 140, height: 140)
                        .scaleEffect(showCheckmark ? 1 : 0)
                    
                    ZStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(showCheckmark ? 1 : 0)
                }
                
                Spacer()
                    .frame(height: 40)
                
                VStack(spacing: 16) {
                    Text("You're All Set!")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(theme.textColor)
                    
                    Text("Your family space is ready.\nLet's capture your first story!")
                        .font(.system(size: 18))
                        .foregroundColor(theme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                
                Spacer()
                    .frame(height: 32)
                
                VStack(spacing: 8) {
                    ReadyStatBadge(icon: "house.fill", label: "Family created")
                    ReadyStatBadge(icon: "person.fill", label: "Profile set up")
                    ReadyStatBadge(icon: "lock.fill", label: "Secure & private")
                }
                .opacity(showContent ? 1 : 0)
                
                Spacer()
                
                OnboardingCTAButton(
                    title: "Collect First Story",
                    action: {
                        coordinator.goToStep(.recordQuestion)
                    }
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) {
                showCheckmark = true
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                showContent = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                confettiTrigger = true
            }
        }
    }
}

private struct ReadyStatBadge: View {
    let icon: String
    let label: String
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.green)
            
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(theme.textColor)
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(.green)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.cardBackgroundColor)
        )
        .padding(.horizontal, 32)
    }
}

private struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }
    
    private func createParticles(in size: CGSize) {
        let colors: [Color] = [.green, .yellow, .orange, .pink, .purple, .blue]
        
        for i in 0..<40 {
            let particle = ConfettiParticle(
                id: i,
                color: colors.randomElement() ?? .green,
                size: CGFloat.random(in: 6...12),
                position: CGPoint(x: size.width / 2, y: size.height / 3),
                opacity: 1.0
            )
            particles.append(particle)
            
            let endX = CGFloat.random(in: 0...size.width)
            let endY = CGFloat.random(in: size.height * 0.6...size.height + 100)
            
            withAnimation(.easeOut(duration: Double.random(in: 1.0...2.0)).delay(Double(i) * 0.02)) {
                if let index = particles.firstIndex(where: { $0.id == i }) {
                    particles[index].position = CGPoint(x: endX, y: endY)
                    particles[index].opacity = 0
                }
            }
        }
    }
}

private struct ConfettiParticle: Identifiable {
    let id: Int
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var opacity: Double
}

#Preview {
    FamilyReadyScreenView(coordinator: .preview)
        .themed(LightTheme())
}
