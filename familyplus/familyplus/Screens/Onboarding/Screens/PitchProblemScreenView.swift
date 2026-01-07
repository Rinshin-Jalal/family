import SwiftUI

struct PitchProblemScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var fadeOutProgress: CGFloat = 0
    @State private var counterValue: Int = 10000
    
    private let fadingPhotos = ["grandma", "grandpa", "family", "wedding", "childhood"]
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                ZStack {
                    ForEach(0..<5, id: \.self) { index in
                        FadingMemoryCard(index: index, fadeProgress: fadeOutProgress)
                    }
                }
                .frame(height: 300)
                .opacity(showContent ? 1 : 0)
                
                Spacer()
                    .frame(height: 32)
                
                VStack(spacing: 20) {
                    Text("Every day, we lose")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(theme.secondaryTextColor)
                        .opacity(showContent ? 1 : 0)
                    
                    HStack(spacing: 0) {
                        Text("\(counterValue)")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundColor(.alertRed)
                            .contentTransition(.numericText())
                        Text("+")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.alertRed)
                    }
                    .opacity(showContent ? 1 : 0)
                    
                    Text("irreplaceable family stories")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(theme.textColor)
                        .opacity(showContent ? 1 : 0)
                }
                .multilineTextAlignment(.center)
                
                Spacer()
                    .frame(height: 24)
                
                VStack(spacing: 12) {
                    LossStatRow(icon: "person.fill.xmark", text: "Someone passes away", stat: "every 0.5 seconds")
                    LossStatRow(icon: "brain.head.profile", text: "Memories fade", stat: "within 2 generations")
                    LossStatRow(icon: "photo.on.rectangle.angled", text: "Photos get lost", stat: "in 90% of families")
                }
                .padding(.horizontal, 24)
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
            
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                fadeOutProgress = 1
            }
            
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                withAnimation {
                    counterValue += Int.random(in: 1...5)
                }
            }
        }
    }
}

private struct FadingMemoryCard: View {
    let index: Int
    let fadeProgress: CGFloat
    
    var body: some View {
        let rotation = Double(index - 2) * 8
        let offset = CGFloat(index - 2) * 20
        let fadeDelay = CGFloat(index) * 0.15
        let adjustedFade = max(0, min(1, (fadeProgress - fadeDelay) * 2))
        
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .frame(width: 200, height: 250)
                .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
            
            VStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 180, height: 180)
                    .overlay(
                        Image(systemName: "photo.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.4))
                    )
                
                Text("Memory \(index + 1)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(10)
        }
        .opacity(Double(1.0 - adjustedFade * 0.7))
        .blur(radius: adjustedFade * 3)
        .rotationEffect(.degrees(rotation))
        .offset(x: offset, y: CGFloat(abs(index - 2)) * 10)
    }
}

private struct LossStatRow: View {
    let icon: String
    let text: String
    let stat: String
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.alertRed.opacity(0.8))
                .frame(width: 30)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(theme.textColor)
            
            Spacer()
            
            Text(stat)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.alertRed)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.alertRed.opacity(0.05))
        )
    }
}

#Preview {
    PitchProblemScreenView(coordinator: .preview)
        .themed(LightTheme())
}
