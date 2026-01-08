//
//  SimpleOnboardingViews.swift
//  StoryRide
//
//  Simplified onboarding screens - 3 steps to start capturing
//

import SwiftUI

// MARK: - Simple Welcome

struct SimpleWelcomeView: View {
    @ObservedObject var coordinator: SimpleOnboardingCoordinator
    @Environment(\.theme) private var theme

    @State private var showContent = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Hero icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [theme.accentColor, theme.accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: theme.accentColor.opacity(0.4), radius: 20, x: 0, y: 10)

                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.white)
            }
            .scaleEffect(showContent ? 1 : 0.8)
            .opacity(showContent ? 1 : 0)

            // Headline
            VStack(spacing: 12) {
                Text("Preserve what matters")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(theme.textColor)

                Text("Your family's stories, safely stored forever")
                    .font(.system(size: 18))
                    .foregroundColor(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)

            Spacer()

            // CTA
            OnboardingCTAButton(
                title: "Get Started",
                action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        coordinator.goToNextStep()
                    }
                },
                icon: "arrow.right"
            )
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                showContent = true
            }
        }
    }
}

// MARK: - What To Preserve

struct SimpleWhatToPreserveView: View {
    @ObservedObject var coordinator: SimpleOnboardingCoordinator
    @Environment(\.theme) private var theme

    @State private var showContent = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Text("What do you want to preserve?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(theme.textColor)

                Text("Select all that apply")
                    .font(.system(size: 16))
                    .foregroundColor(theme.secondaryTextColor)
            }
            .opacity(showContent ? 1 : 0)

            // Preserve type grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(PreserveType.allCases, id: \.self) { type in
                    PreserveTypeCard(
                        type: type,
                        isSelected: coordinator.onboardingState.preserveTypes.contains(type)
                    ) {
                        coordinator.togglePreserveType(type)
                    }
                }
            }
            .padding(.horizontal, 24)
            .opacity(showContent ? 1 : 0)

            Spacer()

            // CTA
            OnboardingCTAButton(
                title: "Continue",
                action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        coordinator.goToNextStep()
                    }
                },
                icon: "arrow.right",
                style: coordinator.onboardingState.preserveTypes.isEmpty ? .secondary : .primary
            )
            .disabled(coordinator.onboardingState.preserveTypes.isEmpty)
            .opacity(showContent ? 1 : 0)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
    }
}

// MARK: - Who For

struct SimpleWhoForView: View {
    @ObservedObject var coordinator: SimpleOnboardingCoordinator
    @Environment(\.theme) private var theme

    @State private var showContent = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Text("Who are you capturing for?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(theme.textColor)

                Text("This helps us tailor your experience")
                    .font(.system(size: 16))
                    .foregroundColor(theme.secondaryTextColor)
            }
            .opacity(showContent ? 1 : 0)

            // Target options
            VStack(spacing: 12) {
                ForEach(CaptureTarget.allCases, id: \.self) { target in
                    CaptureTargetCard(
                        target: target,
                        isSelected: coordinator.onboardingState.captureTarget == target
                    ) {
                        coordinator.setCaptureTarget(target)
                    }
                }
            }
            .padding(.horizontal, 24)
            .opacity(showContent ? 1 : 0)

            Spacer()

            // CTA
            OnboardingCTAButton(
                title: "Continue",
                action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        coordinator.goToNextStep()
                    }
                },
                icon: "arrow.right"
            )
            .opacity(showContent ? 1 : 0)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
    }
}

// MARK: - Start Capturing

struct SimpleStartCapturingView: View {
    @ObservedObject var coordinator: SimpleOnboardingCoordinator
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) var dismiss

    @State private var showContent = false
    @State private var isCreatingAccount = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Success icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: .green.opacity(0.4), radius: 20, x: 0, y: 10)

                Image(systemName: isCreatingAccount ? "hourglass" : "checkmark")
                    .symbolEffect(.pulse, options: .repeating)
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            .scaleEffect(showContent ? 1 : 0.8)
            .opacity(showContent ? 1 : 0)

            VStack(spacing: 12) {
                Text(isCreatingAccount ? "Setting up your account..." : "You're all set!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(theme.textColor)

                Text("Start capturing your family's stories")
                    .font(.system(size: 16))
                    .foregroundColor(theme.secondaryTextColor)
            }
            .opacity(showContent ? 1 : 0)

            Spacer()

            // CTA
            OnboardingCTAButton(
                title: "Start Capturing",
                action: {
                    coordinator.completeOnboarding()
                    dismiss()
                },
                icon: "mic.fill"
            )
            .opacity(showContent ? 1 : 0)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }

            // Create account in background
            isCreatingAccount = true
            Task {
                await coordinator.createAccountInBackground()
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isCreatingAccount = false
                    }
                }
            }
        }
    }
}

// MARK: - Preserve Type Card

struct PreserveTypeCard: View {
    let type: PreserveType
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.theme) var theme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? type.color : type.color.opacity(0.1))
                        .frame(width: 50, height: 50)

                    Image(systemName: type.icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? .white : type.color)
                }

                VStack(spacing: 4) {
                    Text(type.rawValue)
                        .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                        .foregroundColor(theme.textColor)

                    Text(type.description)
                        .font(.system(size: 11))
                        .foregroundColor(theme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? type.color.opacity(0.15) : theme.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? type.color : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Capture Target Card

struct CaptureTargetCard: View {
    let target: CaptureTarget
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.theme) var theme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? theme.accentColor : theme.accentColor.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: target.icon)
                        .font(.system(size: 18))
                        .foregroundColor(isSelected ? .white : theme.accentColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(target.rawValue)
                        .font(.system(size: 16, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(theme.textColor)

                    Text(target.description)
                        .font(.system(size: 13))
                        .foregroundColor(theme.secondaryTextColor)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(theme.accentColor)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? theme.accentColor.opacity(0.1) : theme.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? theme.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("Simple Welcome") {
    SimpleWelcomeView(coordinator: SimpleOnboardingCoordinator.preview)
        .themed(LightTheme())
}

#Preview("What To Preserve") {
    SimpleWhatToPreserveView(coordinator: SimpleOnboardingCoordinator.preview)
        .themed(DarkTheme())
}

#Preview("Who For") {
    SimpleWhoForView(coordinator: SimpleOnboardingCoordinator.preview)
        .themed(LightTheme())
}

#Preview("Start Capturing") {
    SimpleStartCapturingView(coordinator: SimpleOnboardingCoordinator.preview)
        .themed(DarkTheme())
}
