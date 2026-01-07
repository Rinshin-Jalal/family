import SwiftUI

struct PitchHowItWorks2ScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var processingStep = 0
    @State private var sparkleRotation: Double = 0
    
    private let aiFeatures = [
        ("waveform", "Transcription", "Voice to text instantly"),
        ("tag.fill", "Smart Tags", "Auto-categorizes memories"),
        ("doc.text.fill", "Summaries", "Key moments highlighted"),
        ("person.wave.2.fill", "Voice Clone", "Preserves their voice forever")
    ]
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    StepIndicator2(currentStep: 2, totalSteps: 3)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(theme.accentColor.opacity(0.1), lineWidth: 2)
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .stroke(theme.accentColor.opacity(0.2), lineWidth: 2)
                        .frame(width: 160, height: 160)
                    
                    ForEach(0..<6, id: \.self) { index in
                        Image(systemName: "sparkle")
                            .font(.system(size: 16))
                            .foregroundColor(theme.accentColor.opacity(0.6))
                            .offset(x: cos(Double(index) * .pi / 3 + sparkleRotation) * 90,
                                    y: sin(Double(index) * .pi / 3 + sparkleRotation) * 90)
                    }
                    
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.purple.opacity(0.3), theme.accentColor.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "2.circle.fill")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(theme.accentColor)
                    }
                }
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.8)
                
                Spacer()
                    .frame(height: 32)
                
                VStack(spacing: 16) {
                    Text("Step 2")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.accentColor)
                        .textCase(.uppercase)
                        .tracking(2)
                    
                    Text("AI Magic")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(theme.textColor)
                    
                    Text("We enhance every story automatically")
                        .font(.system(size: 18))
                        .foregroundColor(theme.secondaryTextColor)
                }
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                
                Spacer()
                    .frame(height: 24)
                
                VStack(spacing: 12) {
                    ForEach(Array(aiFeatures.enumerated()), id: \.offset) { index, feature in
                        AIFeatureRow(
                            icon: feature.0,
                            title: feature.1,
                            description: feature.2,
                            isActive: processingStep >= index,
                            delay: Double(index) * 0.15
                        )
                        .opacity(showContent ? 1 : 0)
                        .offset(x: showContent ? 0 : -20)
                        .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.1), value: showContent)
                    }
                }
                .padding(.horizontal, 24)
                
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
            
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                sparkleRotation = .pi * 2
            }
            
            Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { timer in
                withAnimation(.easeInOut(duration: 0.3)) {
                    processingStep = (processingStep + 1) % (aiFeatures.count + 1)
                }
            }
        }
    }
}

private struct StepIndicator2: View {
    let currentStep: Int
    let totalSteps: Int
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep ? theme.accentColor : theme.accentColor.opacity(0.2))
                    .frame(width: step == currentStep ? 32 : 8, height: 8)
            }
        }
    }
}

private struct AIFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let isActive: Bool
    let delay: Double
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isActive ? theme.accentColor : theme.cardBackgroundColor)
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isActive ? .white : theme.secondaryTextColor)
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
            
            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.cardBackgroundColor)
        )
    }
}

#Preview {
    PitchHowItWorks2ScreenView(coordinator: .preview)
        .themed(LightTheme())
}
