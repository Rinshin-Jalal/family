import SwiftUI

struct HowToCollectScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var showCards: [Bool] = [false, false, false, false, false]
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(theme.accentColor.opacity(0.1))
                                .frame(width: 120, height: 120)
                                .scaleEffect(showContent ? 1.2 : 0.8)
                            
                            Circle()
                                .fill(theme.accentColor.opacity(0.15))
                                .frame(width: 90, height: 90)
                            
                            Image(systemName: "square.stack.3d.up.fill")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(theme.accentColor)
                                .rotationEffect(.degrees(showContent ? 0 : -10))
                        }
                        .opacity(showContent ? 1 : 0)
                        .scaleEffect(showContent ? 1 : 0.5)
                        
                        Text("Choose Your Method")
                            .font(theme.headlineFont)
                            .foregroundColor(theme.textColor)
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                        
                        Text("Pick the way that works best for your family")
                            .font(theme.bodyFont)
                            .foregroundColor(theme.secondaryTextColor)
                            .multilineTextAlignment(.center)
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                    }
                    .padding(.top, 32)
                    .padding(.horizontal, 24)
                    
                    VStack(spacing: 16) {
                        CollectionMethodCard(
                            icon: "mic.fill",
                            iconColor: theme.accentColor,
                            title: "Record Audio",
                            description: "Capture their voice telling stories",
                            badge: "Most Popular",
                            badgeColor: theme.accentColor,
                            isVisible: showCards[0]
                        ) {
                            coordinator.goToStep(.recordQuestion)
                        }
                        
                        CollectionMethodCard(
                            icon: "square.and.pencil",
                            iconColor: .blue,
                            title: "Write Story",
                            description: "Type or paste from memory",
                            badge: nil,
                            badgeColor: .blue,
                            isVisible: showCards[1]
                        ) {
                            coordinator.goToStep(.recordQuestion)
                        }
                        
                        CollectionMethodCard(
                            icon: "camera.fill",
                            iconColor: .green,
                            title: "Scan Document",
                            description: "Photo of letters, diaries, recipes",
                            badge: nil,
                            badgeColor: .green,
                            isVisible: showCards[2]
                        ) {
                            coordinator.goToStep(.recordQuestion)
                        }
                        
                        CollectionMethodCard(
                            icon: "doc.fill",
                            iconColor: .orange,
                            title: "Upload File",
                            description: "PDF, Word, or text documents",
                            badge: nil,
                            badgeColor: .orange,
                            isVisible: showCards[3]
                        ) {
                            coordinator.goToStep(.recordQuestion)
                        }
                        
                        CollectionMethodCard(
                            icon: "waveform.circle.fill",
                            iconColor: .purple,
                            title: "Voice Clone Magic",
                            description: "Hear them read their own words",
                            badge: "✨ Premium",
                            badgeColor: .purple,
                            isVisible: showCards[4]
                        ) {
                            coordinator.goToStep(.recordVoiceCloneResult)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
            
            for i in 0..<5 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(i) * 0.1) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showCards[i] = true
                    }
                }
            }
        }
    }
}

private struct CollectionMethodCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let badge: String?
    let badgeColor: Color
    let isVisible: Bool
    let action: () -> Void
    
    @Environment(\.theme) private var theme
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            action()
        }) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(theme.textColor)
                        
                        if let badge = badge {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(badgeColor)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(theme.secondaryTextColor)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.secondaryTextColor.opacity(0.5))
            }
            .padding(16)
            .background(theme.cardBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(iconColor.opacity(isPressed ? 0.4 : 0.15), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.98 : 1)
        }
        .buttonStyle(PlainButtonStyle())
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 30)
    }
}

#Preview {
    HowToCollectScreenView(coordinator: .preview)
        .themed(LightTheme())
}
