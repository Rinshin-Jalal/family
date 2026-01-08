import SwiftUI

// MARK: - Color Extension

extension Color {
    static let brandIndigoLight = Color(hex: "E1F0E6") // Soft green variant for light mode
    static let primaryLabel = Color.primary
    static let secondaryLabel = Color.gray
}

// MARK: - Liquid Glass Button Style

struct LiquidGlassButtonStyle: ButtonStyle {
    let tintColor: Color
    let intensity: CGFloat
    
    init(tintColor: Color = .burgundyRed, intensity: CGFloat = 0.15) {
        self.tintColor = tintColor
        self.intensity = intensity
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundColor(tintColor)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(tintColor.opacity(intensity), lineWidth: 1)
                    )
            )
            .shadow(
                color: .black.opacity(configuration.isPressed ? 0.05 : 0.1),
                radius: configuration.isPressed ? 4 : 8,
                x: 0,
                y: configuration.isPressed ? 2 : 4
            )
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.bouncy, value: configuration.isPressed)
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !configuration.isPressed {
                            #if os(iOS)
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                            #endif
                        }
                    }
            )
    }
}

extension ButtonStyle where Self == LiquidGlassButtonStyle {
    static var liquidGlass: LiquidGlassButtonStyle {
        LiquidGlassButtonStyle()
    }
}

// MARK: - Liquid Glass Card Style

struct LiquidGlassCardStyle: ViewModifier {
    let cornerRadius: CGFloat
    let borderOpacity: CGFloat
    let shadowOpacity: CGFloat
    
    init(
        cornerRadius: CGFloat = 16,
        borderOpacity: CGFloat = 0.2,
        shadowOpacity: CGFloat = 0.1
    ) {
        self.cornerRadius = cornerRadius
        self.borderOpacity = borderOpacity
        self.shadowOpacity = shadowOpacity
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(borderOpacity), lineWidth: 1)
            )
            .shadow(color: .black.opacity(shadowOpacity), radius: 12, x: 0, y: 6)
    }
}

extension View {
    func liquidGlassCard(
        cornerRadius: CGFloat = 16,
        borderOpacity: CGFloat = 0.2,
        shadowOpacity: CGFloat = 0.1
    ) -> some View {
        modifier(LiquidGlassCardStyle(
            cornerRadius: cornerRadius,
            borderOpacity: borderOpacity,
            shadowOpacity: shadowOpacity
        ))
    }
}

// MARK: - Animated Liquid Glass Background

struct LiquidGlassBackground: View {
    @State private var animate = false
    
    let primaryColor: Color
    let secondaryColor: Color
    
    init(
        primaryColor: Color = .burgundyRed,
        secondaryColor: Color = .softBurgundy
    ) {
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(primaryColor.opacity(0.3))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: animate ? 100 : -100, y: animate ? -50 : 50)
                .animation(
                    Animation.easeInOut(duration: 8)
                        .repeatForever(autoreverses: true),
                    value: animate
                )
            
            Circle()
                .fill(secondaryColor.opacity(0.25))
                .frame(width: 250, height: 250)
                .blur(radius: 50)
                .offset(x: animate ? -80 : 80, y: animate ? 80 : -80)
                .animation(
                    Animation.easeInOut(duration: 10)
                        .repeatForever(autoreverses: true),
                    value: animate
                )
        }
        .onAppear {
            animate = true
        }
        .ignoresSafeArea()
    }
}

// MARK: - Progress Indicator (HIG Compliant)

struct LiquidProgressView: View {
    let progress: Double
    let tint: Color
    
    init(progress: Double, tint: Color = .burgundyRed) {
        self.progress = progress
        self.tint = tint
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondaryLabel.opacity(0.2))
                    .frame(height: 8)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(tint.gradient)
                    .frame(width: geometry.size.width * progress, height: 8)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Empty State View (HIG Compliant)

struct LiquidEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
                .symbolEffect(.pulse, isActive: true)
            
            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundColor(.primaryLabel)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondaryLabel)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Error State View (HIG Compliant)

struct LiquidErrorState: View {
    let message: String
    let retryAction: (() -> Void)?
    
    init(message: String, retryAction: (() -> Void)? = nil) {
        self.message = message
        self.retryAction = retryAction
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            
            Text("Something Went Wrong")
                .font(.title3.weight(.semibold))
                .foregroundColor(.primaryLabel)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondaryLabel)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if let retryAction = retryAction {
                Button(action: retryAction) {
                    Label("Try Again", systemImage: "arrow.clockwise")
                        .font(.body.weight(.medium))
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
        }
        .padding()
    }
}

// MARK: - Loading State View (HIG Compliant)

struct LiquidLoadingState: View {
    let message: String
    
    init(_ message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.burgundyRed)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondaryLabel)
        }
        .padding()
    }
}

// MARK: - SF Symbol Button

struct SFSymbolButton: View {
    let icon: String
    let size: CGFloat
    let action: () -> Void
    
    init(icon: String, size: CGFloat = 24, action: @escaping () -> Void) {
        self.icon = icon
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size))
                .foregroundColor(.burgundyRed)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Countdown Timer View

struct CountdownView: View {
    let remaining: Int
    let total: Int
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondaryLabel.opacity(0.2), lineWidth: 4)
                .frame(width: 60, height: 60)
            
            Circle()
                .trim(from: 0, to: CGFloat(remaining) / CGFloat(total))
                .stroke(
                    remaining <= 5 ? Color.orange : Color.burgundyRed,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: remaining)
            
            Text("\(remaining)")
                .font(.title2.weight(.bold))
                .foregroundColor(remaining <= 5 ? .orange : .primaryLabel)
        }
    }
}

#Preview("Empty State") {
    LiquidEmptyState(
        icon: "tray",
        title: "No Polls Yet",
        message: "Family polls will appear here when someone creates one.",
        actionTitle: "Create Poll"
    ) {
        print("Create poll tapped")
    }
}

#Preview("Loading State") {
    LiquidLoadingState("Loading polls...")
}

#Preview("Error State") {
    LiquidErrorState(message: "Unable to connect to the server.") {
        print("Retry tapped")
    }
}
