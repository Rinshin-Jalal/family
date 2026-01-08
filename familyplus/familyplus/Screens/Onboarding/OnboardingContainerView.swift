//
//  OnboardingContainerView.swift
//  StoryRd
//
//  Main container view for the onboarding flow
//

import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme

    /// Callback when onboarding is completed
    var onComplete: (() -> Void)?

    init(navigationCoordinator: NavigationCoordinator = .shared, onComplete: (() -> Void)? = nil) {
        _coordinator = StateObject(wrappedValue: OnboardingCoordinator())
        self.onComplete = onComplete
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                theme.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress indicator
                    OnboardingProgressView(
                        progress: coordinator.progress,
                        currentStep: coordinator.currentStepNumber,
                        totalSteps: coordinator.totalSteps
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Main content
                    coordinator.currentView
                        .frame(maxHeight: .infinity)
                }
            }
        }
        .environmentObject(coordinator)
        .onChange(of: coordinator.onboardingState.isCompleted) { _, isCompleted in
            if isCompleted {
                onComplete?()
            }
        }
    }
}

// MARK: - Progress View

struct OnboardingProgressView: View {
    let progress: Double
    let currentStep: Int
    let totalSteps: Int
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 8) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.cardBackgroundColor.opacity(0.3))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.accentColor)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 8)
            
            // Step counter
            HStack {
                Text("Step \(currentStep) of \(totalSteps)")
                    .font(theme.bodyFont)
                    .foregroundColor(theme.textColor.opacity(0.6))
                
                Spacer()
                
                if currentStep >= 9 && currentStep <= 16 {
                    Text("THE PITCH")
                        .font(theme.bodyFont)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.accentColor)
                } else if currentStep >= 17 && currentStep <= 23 {
                    Text("FAMILY SETUP")
                        .font(theme.bodyFont)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.accentColor)
                } else if currentStep >= 24 {
                    Text("FIRST STORY")
                        .font(theme.bodyFont)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.accentColor)
                } else {
                    Text("GETTING STARTED")
                        .font(theme.bodyFont)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.accentColor)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingContainerView(navigationCoordinator: .preview)
        .themed(LightTheme())
}
