//
//  WelcomeScreenView.swift
//  StoryRd
//

import SwiftUI

struct WelcomeScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var pulseHeart = false
    @State private var floatingPhotos: [FloatingPhoto] = []
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    theme.backgroundColor,
                    theme.accentColor.opacity(0.1),
                    theme.backgroundColor
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ForEach(floatingPhotos) { photo in
                FloatingPhotoView(photo: photo)
            }
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(theme.accentColor.opacity(0.2))
                            .frame(width: 160, height: 160)
                            .scaleEffect(pulseHeart ? 1.2 : 1.0)
                            .opacity(pulseHeart ? 0.3 : 0.6)
                        
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
                            .scaleEffect(pulseHeart ? 1.1 : 1.0)
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    
                    VStack(spacing: 12) {
                        Text("Your grandmother's voice.")
                            .font(.system(size: 32, weight: .bold, design: .serif))
                            .foregroundColor(theme.textColor)
                        
                        Text("Forever.")
                            .font(.system(size: 32, weight: .bold, design: .serif))
                            .foregroundColor(theme.accentColor)
                    }
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 30)
                    
                    Text("Every day, stories disappear that can never be told again.\nStoryRd helps your family capture them before it's too late.")
                        .font(theme.bodyFont)
                        .foregroundColor(theme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 40)
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.badge.exclamationmark")
                            .foregroundColor(.orange)
                        Text("10,000+ family stories")
                            .fontWeight(.semibold)
                        Text("lost every day")
                            .foregroundColor(theme.secondaryTextColor)
                    }
                    .font(.subheadline)
                    
                    Text("Don't let yours be one of them.")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(theme.cardBackgroundColor)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                )
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 50)
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button(action: {
                        triggerHaptic()
                        coordinator.goToNextStep()
                    }) {
                        HStack(spacing: 12) {
                            Text("Start Preserving Stories")
                                .font(.headline)
                            Image(systemName: "arrow.right.circle.fill")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [theme.accentColor, theme.accentColor.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: theme.accentColor.opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                    .accessibilityLabel("Start preserving your family stories")
                    
                    Button(action: {
                        coordinator.goToStep(.familyCreateOrJoin)
                    }) {
                        Text("I have an invite code")
                            .font(.subheadline)
                            .foregroundColor(theme.accentColor)
                    }
                    .accessibilityLabel("Join existing family with invite code")
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 60)
            }
        }
        .onAppear {
            setupFloatingPhotos()
            
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
            
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseHeart = true
            }
        }
    }
    
    private func triggerHaptic() {
        #if os(iOS)
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        #endif
    }
    
    private func setupFloatingPhotos() {
        let icons = ["person.crop.circle.fill", "person.2.circle.fill", "heart.circle.fill", "star.circle.fill"]
        floatingPhotos = (0..<6).map { index in
            FloatingPhoto(
                id: index,
                icon: icons[index % icons.count],
                x: CGFloat.random(in: 0.1...0.9),
                y: CGFloat.random(in: 0.1...0.4),
                size: CGFloat.random(in: 30...50),
                opacity: Double.random(in: 0.1...0.25),
                delay: Double(index) * 0.3
            )
        }
    }
}

// MARK: - Supporting Types

struct FloatingPhoto: Identifiable {
    let id: Int
    let icon: String
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let opacity: Double
    let delay: Double
}

struct FloatingPhotoView: View {
    let photo: FloatingPhoto
    @State private var isFloating = false
    @Environment(\.theme) private var theme
    
    var body: some View {
        GeometryReader { geometry in
            Image(systemName: photo.icon)
                .font(.system(size: photo.size))
                .foregroundColor(theme.accentColor.opacity(photo.opacity))
                .position(
                    x: geometry.size.width * photo.x,
                    y: geometry.size.height * photo.y + (isFloating ? -10 : 10)
                )
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 3)
                        .repeatForever(autoreverses: true)
                        .delay(photo.delay)
                    ) {
                        isFloating = true
                    }
                }
        }
    }
}

// MARK: - Preview

#Preview {
    WelcomeScreenView(coordinator: OnboardingCoordinator.preview)
        .themed(LightTheme())
}

#Preview("Dark") {
    WelcomeScreenView(coordinator: OnboardingCoordinator.preview)
        .themed(DarkTheme())
}
