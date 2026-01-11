//
//  SimpleOnboardingView.swift
//  Family+
//
//  Simple temporary onboarding - will be redesigned later
//

import SwiftUI

struct SimpleOnboardingView: View {
    @Environment(\.theme) private var theme
    let onComplete: () -> Void

    @State private var currentPage = 0

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Logo/Icon
            Image(systemName: "heart.fill")
                .font(.system(size: 60))
                .foregroundColor(theme.accentColor)

            // Content based on page
            VStack(spacing: 16) {
                Text(titles[currentPage])
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(theme.textColor)

                Text(descriptions[currentPage])
                    .font(.system(size: 16))
                    .foregroundColor(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            // Page indicator
            HStack(spacing: 8) {
                ForEach(0..<titles.count) { index in
                    Circle()
                        .fill(index == currentPage ? theme.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }

            // CTA button
            Button(action: {
                if currentPage < titles.count - 1 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    onComplete()
                }
            }) {
                Text(currentPage < titles.count - 1 ? "Next" : "Get Started")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.accentColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .background(theme.backgroundColor)
        .ignoresSafeArea()
    }

    private let titles = ["Welcome to Family+", "Preserve Memories", "Get Started"]
    private let descriptions = [
        "Your family's stories, safe forever.",
        "Record, transcribe, and search your family wisdom.",
        "Start building your legacy today."
    ]
}

#Preview {
    SimpleOnboardingView {
        print("Complete")
    }
}
