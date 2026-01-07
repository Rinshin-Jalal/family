import SwiftUI

struct OnboardingCTAButton: View {
    let title: String
    let action: () -> Void
    var icon: String? = "arrow.right"
    var style: CTAStyle = .primary
    
    @Environment(\.theme) private var theme
    
    enum CTAStyle: Equatable {
        case primary, secondary, tertiary
        case custom(Color)
    }
    
    var body: some View {
        Button(action: {
            triggerHaptic()
            action()
        }) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.headline)
                if let icon = icon, style == .primary || isCustomStyle {
                    Image(systemName: icon)
                        .font(.subheadline.weight(.semibold))
                }
            }
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(background)
            .cornerRadius(16)
            .shadow(color: shadowColor, radius: 12, x: 0, y: 6)
        }
        .accessibilityLabel(title)
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary, .custom: return .white
        case .secondary: return theme.accentColor
        case .tertiary: return theme.secondaryTextColor
        }
    }
    
    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:
            LinearGradient(
                colors: [theme.accentColor, theme.accentColor.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .custom(let color):
            LinearGradient(
                colors: [color, color.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .secondary:
            theme.cardBackgroundColor
        case .tertiary:
            Color.clear
        }
    }
    
    private var shadowColor: Color {
        switch style {
        case .primary:
            return theme.accentColor.opacity(0.3)
        case .custom(let color):
            return color.opacity(0.3)
        default:
            return .clear
        }
    }
    
    private var isCustomStyle: Bool {
        if case .custom = style { return true }
        return false
    }
    
    private func triggerHaptic() {
        #if os(iOS)
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        #endif
    }
}

struct OnboardingSecondaryButton: View {
    let title: String
    let action: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(theme.accentColor)
        }
        .accessibilityLabel(title)
    }
}

struct OnboardingFeatureRow: View {
    let icon: String
    let iconColor: Color
    let text: String
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            Text(text)
                .font(theme.bodyFont)
                .foregroundColor(theme.textColor)
            
            Spacer()
        }
    }
}

struct OnboardingStatBadge: View {
    let icon: String
    let iconColor: Color
    let text: String
    let subtext: String?
    
    @Environment(\.theme) private var theme
    
    init(icon: String, iconColor: Color = .orange, text: String, subtext: String? = nil) {
        self.icon = icon
        self.iconColor = iconColor
        self.text = text
        self.subtext = subtext
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                Text(text)
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            
            if let subtext = subtext {
                Text(subtext)
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
}

struct OnboardingHeroIcon: View {
    let systemName: String
    var size: CGFloat = 56
    var pulses: Bool = false
    
    @Environment(\.theme) private var theme
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            if pulses {
                Circle()
                    .fill(theme.accentColor.opacity(0.2))
                    .frame(width: 160, height: 160)
                    .scaleEffect(isPulsing ? 1.2 : 1.0)
                    .opacity(isPulsing ? 0.3 : 0.6)
            }
            
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
            
            Image(systemName: systemName)
                .font(.system(size: size))
                .foregroundColor(.white)
                .scaleEffect(pulses && isPulsing ? 1.1 : 1.0)
        }
        .onAppear {
            if pulses {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
        }
    }
}

#Preview("CTA Buttons") {
    VStack(spacing: 20) {
        OnboardingCTAButton(title: "Primary Action", action: {})
        OnboardingCTAButton(title: "Secondary Action", action: {}, style: .secondary)
        OnboardingCTAButton(title: "Tertiary Action", action: {}, style: .tertiary)
    }
    .padding()
    .themed(LightTheme())
}

#Preview("Components") {
    VStack(spacing: 20) {
        OnboardingHeroIcon(systemName: "heart.fill", pulses: true)
        OnboardingFeatureRow(icon: "mic.fill", iconColor: .blue, text: "Record audio memories")
        OnboardingStatBadge(icon: "clock", text: "10,000+ stories", subtext: "preserved daily")
    }
    .padding()
    .themed(LightTheme())
}
