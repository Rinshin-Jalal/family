import SwiftUI

struct RecordTipsScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var showTips: [Bool] = [false, false, false, false]
    
    private let tips: [(icon: String, title: String, description: String)] = [
        ("location.fill", "Find a Quiet Spot", "Background noise affects audio quality"),
        ("clock.fill", "Take Your Time", "There's no rush—pause whenever you need"),
        ("heart.fill", "Share Emotions", "The feelings matter as much as the facts"),
        ("person.wave.2.fill", "Be Yourself", "Imagine talking to your grandchildren")
    ]
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.1))
                            .frame(width: 100, height: 100)
                            .scaleEffect(showContent ? 1.1 : 0.9)
                        
                        Circle()
                            .fill(Color.green.opacity(0.15))
                            .frame(width: 70, height: 70)
                        
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.green)
                    }
                    .opacity(showContent ? 1 : 0)
                    .scaleEffect(showContent ? 1 : 0.5)
                    
                    VStack(spacing: 8) {
                        Text("Before You Start")
                            .font(theme.headlineFont)
                            .foregroundColor(theme.textColor)
                        
                        Text("A few tips for the best recording")
                            .font(theme.bodyFont)
                            .foregroundColor(theme.secondaryTextColor)
                    }
                    .opacity(showContent ? 1 : 0)
                }
                
                Spacer().frame(height: 32)
                
                VStack(spacing: 16) {
                    ForEach(Array(tips.enumerated()), id: \.offset) { index, tip in
                        RecordingTipRow(
                            icon: tip.icon,
                            title: tip.title,
                            description: tip.description,
                            index: index + 1,
                            isVisible: showTips[index]
                        )
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                VStack(spacing: 16) {
                    OnboardingCTAButton(
                        title: "Start Recording",
                        action: {
                            coordinator.startRecording()
                        },
                        icon: "mic.fill"
                    )
                    
                    Text("You can re-record anytime")
                        .font(.system(size: 14))
                        .foregroundColor(theme.secondaryTextColor)
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
            
            for i in 0..<4 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4 + Double(i) * 0.12) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showTips[i] = true
                    }
                }
            }
        }
    }
}

private struct RecordingTipRow: View {
    let icon: String
    let title: String
    let description: String
    let index: Int
    let isVisible: Bool
    
    @Environment(\.theme) private var theme
    
    private let tipColors: [Color] = [.blue, .orange, .pink, .purple]
    
    private var tipColor: Color {
        tipColors[(index - 1) % tipColors.count]
    }
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(tipColor.opacity(0.12))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(tipColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.textColor)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(theme.secondaryTextColor)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.green.opacity(0.7))
        }
        .padding(14)
        .background(theme.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -30)
    }
}

#Preview {
    RecordTipsScreenView(coordinator: .preview)
        .themed(LightTheme())
}
