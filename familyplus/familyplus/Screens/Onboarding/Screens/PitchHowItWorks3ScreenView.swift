import SwiftUI

struct PitchHowItWorks3ScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var shieldPulse = false
    @State private var generationIndex = 0
    
    private let generations = ["Grandparents", "Parents", "You", "Children", "Grandchildren"]
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    StepIndicator3(currentStep: 3, totalSteps: 3)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
                
                ZStack {
                    ForEach(0..<3, id: \.self) { ring in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.green.opacity(0.3 - Double(ring) * 0.1),
                                        theme.accentColor.opacity(0.2 - Double(ring) * 0.05)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 140 + CGFloat(ring) * 40, height: 140 + CGFloat(ring) * 40)
                            .scaleEffect(shieldPulse ? 1.05 : 1.0)
                            .animation(
                                .easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(ring) * 0.2),
                                value: shieldPulse
                            )
                    }
                    
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.2), theme.accentColor.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "3.circle.fill")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(theme.accentColor)
                    }
                }
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.8)
                
                Spacer()
                    .frame(height: 32)
                
                VStack(spacing: 16) {
                    Text("Step 3")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.accentColor)
                        .textCase(.uppercase)
                        .tracking(2)
                    
                    Text("Preserve Forever")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(theme.textColor)
                    
                    Text("Safe for generations to come")
                        .font(.system(size: 18))
                        .foregroundColor(theme.secondaryTextColor)
                }
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                
                Spacer()
                    .frame(height: 32)
                
                VStack(spacing: 8) {
                    Text("Passed down through")
                        .font(.system(size: 15))
                        .foregroundColor(theme.secondaryTextColor)
                    
                    HStack(spacing: 4) {
                        ForEach(Array(generations.enumerated()), id: \.offset) { index, gen in
                            GenerationDot(
                                label: gen,
                                isActive: index <= generationIndex,
                                isCurrent: index == generationIndex
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .opacity(showContent ? 1 : 0)
                
                Spacer()
                    .frame(height: 24)
                
                VStack(spacing: 12) {
                    PreservationFeature(icon: "lock.shield.fill", text: "Bank-level encryption")
                    PreservationFeature(icon: "icloud.fill", text: "Automatic cloud backup")
                    PreservationFeature(icon: "person.3.fill", text: "Family-only access")
                }
                .padding(.horizontal, 40)
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
            
            shieldPulse = true
            
            Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.4)) {
                    generationIndex = (generationIndex + 1) % generations.count
                }
            }
        }
    }
}

private struct StepIndicator3: View {
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

private struct GenerationDot: View {
    let label: String
    let isActive: Bool
    let isCurrent: Bool
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(isActive ? Color.green : theme.cardBackgroundColor)
                .frame(width: isCurrent ? 16 : 10, height: isCurrent ? 16 : 10)
                .overlay(
                    Circle()
                        .stroke(isCurrent ? Color.green : .clear, lineWidth: 2)
                        .frame(width: 22, height: 22)
                )
            
            if isCurrent {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(theme.textColor)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct PreservationFeature: View {
    let icon: String
    let text: String
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.green)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(theme.textColor)
            
            Spacer()
        }
    }
}

#Preview {
    PitchHowItWorks3ScreenView(coordinator: .preview)
        .themed(LightTheme())
}
