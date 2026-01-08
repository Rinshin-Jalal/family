//
//  SimpleOnboardingContainerView.swift
//  StoryRide
//
//  Simplified onboarding container - 3 steps to value
//

import SwiftUI

struct SimpleOnboardingContainerView: View {
    @StateObject private var coordinator: SimpleOnboardingCoordinator
    @Environment(\.theme) private var theme

    /// Callback when onboarding is completed
    var onComplete: (() -> Void)?

    init(onComplete: (() -> Void)? = nil) {
        _coordinator = StateObject(wrappedValue: SimpleOnboardingCoordinator())
        self.onComplete = onComplete
    }

    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator (subtle, at top)
                if coordinator.currentStep != .startCapturing {
                    SimpleProgressView(
                        progress: coordinator.progress,
                        currentStep: coordinator.currentStepNumber,
                        totalSteps: coordinator.totalSteps
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }

                // Main content
                coordinator.currentView
                    .frame(maxHeight: .infinity)
            }
        }
        .onChange(of: coordinator.onboardingState.isCompleted) { _, isCompleted in
            if isCompleted {
                onComplete?()
            }
        }
    }
}

// MARK: - Simple Progress View

struct SimpleProgressView: View {
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
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.accentColor)
                        .frame(width: geometry.size.width * progress, height: 6)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 6)

            // Step counter (minimal)
            Text("Step \(currentStep) of \(totalSteps)")
                .font(.caption)
                .foregroundColor(theme.secondaryTextColor)
        }
    }
}

// MARK: - Preview

#Preview("Simple Onboarding") {
    SimpleOnboardingContainerView {
        print("Onboarding complete!")
    }
    .themed(LightTheme())
}

#Preview("Dark Mode") {
    SimpleOnboardingContainerView {
        print("Onboarding complete!")
    }
    .themed(DarkTheme())
}
