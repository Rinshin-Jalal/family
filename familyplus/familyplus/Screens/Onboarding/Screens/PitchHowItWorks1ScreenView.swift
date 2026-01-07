import SwiftUI

struct PitchHowItWorks1ScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var currentMethod = 0
    @State private var pulseStep = false
    
    private let collectionMethods = [
        ("mic.fill", "Voice Recording", "Record conversations naturally"),
        ("text.quote", "Written Stories", "Type or dictate memories"),
        ("photo.fill", "Photo Stories", "Add context to old photos"),
        ("phone.fill", "Phone Calls", "AI interviews elders automatically")
    ]
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    StepIndicator(currentStep: 1, totalSteps: 3)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
                
                ZStack {
                    ForEach(0..<collectionMethods.count, id: \.self) { index in
                        CollectionMethodOrbit(
                            icon: collectionMethods[index].0,
                            isActive: currentMethod == index,
                            index: index,
                            total: collectionMethods.count
                        )
                    }
                    
                    ZStack {
                        Circle()
                            .fill(theme.accentColor.opacity(0.1))
                            .frame(width: 140, height: 140)
                            .scaleEffect(pulseStep ? 1.1 : 1.0)
                        
                        Circle()
                            .fill(theme.accentColor.opacity(0.2))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "1.circle.fill")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(theme.accentColor)
                    }
                }
                .frame(height: 280)
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.8)
                
                Spacer()
                    .frame(height: 40)
                
                VStack(spacing: 16) {
                    Text("Step 1")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.accentColor)
                        .textCase(.uppercase)
                        .tracking(2)
                    
                    Text("Collect Stories")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(theme.textColor)
                    
                    Text("Any way that works for your family")
                        .font(.system(size: 18))
                        .foregroundColor(theme.secondaryTextColor)
                }
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                
                Spacer()
                    .frame(height: 24)
                
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: collectionMethods[currentMethod].0)
                            .font(.system(size: 20))
                            .foregroundColor(theme.accentColor)
                            .frame(width: 24)
                        
                        Text(collectionMethods[currentMethod].1)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(theme.textColor)
                    }
                    .contentTransition(.interpolate)
                    
                    Text(collectionMethods[currentMethod].2)
                        .font(.system(size: 15))
                        .foregroundColor(theme.secondaryTextColor)
                        .contentTransition(.interpolate)
                }
                .animation(.easeInOut(duration: 0.3), value: currentMethod)
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
            
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseStep = true
            }
            
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentMethod = (currentMethod + 1) % collectionMethods.count
                }
            }
        }
    }
}

private struct StepIndicator: View {
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

private struct CollectionMethodOrbit: View {
    let icon: String
    let isActive: Bool
    let index: Int
    let total: Int
    
    @Environment(\.theme) private var theme
    @State private var rotation: Double = 0
    
    var body: some View {
        let angle = (Double(index) / Double(total)) * 360 + rotation
        let radians = angle * .pi / 180
        let radius: CGFloat = 110
        
        Circle()
            .fill(isActive ? theme.accentColor : theme.cardBackgroundColor)
            .frame(width: 56, height: 56)
            .overlay(
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isActive ? .white : theme.secondaryTextColor)
            )
            .shadow(color: isActive ? theme.accentColor.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
            .offset(x: cos(radians) * radius, y: sin(radians) * radius)
            .onAppear {
                withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

#Preview {
    PitchHowItWorks1ScreenView(coordinator: .preview)
        .themed(LightTheme())
}
