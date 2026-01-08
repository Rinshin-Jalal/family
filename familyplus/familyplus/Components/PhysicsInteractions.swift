//
//  PhysicsInteractions.swift
//  StoryRide
//
//  Physics-based UI components following Apple HIG:
//  - Spring animations with bouncy feel
//  - Haptic feedback system
//  - Squircle shapes (continuous corner curves)
//  - Press feedback modifiers
//

import SwiftUI

// MARK: - Haptic Manager

/// Centralized haptic feedback system for consistent tactile experiences
final class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    /// Trigger an impact haptic (light, medium, heavy)
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
        #endif
    }
    
    /// Trigger a selection haptic (for toggles, pickers)
    func selection() {
        #if os(iOS)
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        #endif
    }
    
    /// Trigger a notification haptic (success, error, warning)
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
        #endif
    }
    
    /// Success haptic for completed actions
    func success() {
        notification(.success)
    }
    
    /// Error haptic for failed actions
    func error() {
        notification(.error)
    }
    
    /// Warning haptic for cautionary actions
    func warning() {
        notification(.warning)
    }
}

// MARK: - Spring Animation Presets

extension Animation {
    /// Bouncy spring - for major interactions and state changes
    /// Response: 0.35s, Damping: 0.6 (20% overshoot for bounce)
    static let bouncy = Animation.spring(response: 0.35, dampingFraction: 0.6, blendDuration: 0.25)
    
    /// Snappy spring - for quick, responsive interactions
    /// Response: 0.25s, Damping: 0.75 (minimal overshoot)
    static let snappy = Animation.spring(response: 0.25, dampingFraction: 0.75)
    
    /// Smooth spring - for fluid, gentle movements
    /// Response: 0.4s, Damping: 0.85 (no overshoot, very smooth)
    static let smooth = Animation.spring(response: 0.4, dampingFraction: 0.85)
    
    /// Rubber band effect - for pull-to-refresh and scroll bounce
    /// Response: 0.5s, Damping: 0.5 (30% overshoot for strong bounce)
    static let rubberBand = Animation.spring(response: 0.5, dampingFraction: 0.5)
    
    /// Default press animation - quick and subtle
    static let pressAnimation = Animation.bouncy
}

// MARK: - Squircle Shape

/// Squircle shape with continuous corner curves (like Apple's design)
struct Squircle: Shape {
    let cornerRadius: CGFloat
    
    var animatableData: CGFloat {
        get { cornerRadius }
        set { _ = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        let minX = rect.minX
        let minY = rect.minY
        let maxX = rect.maxX
        let maxY = rect.maxY
        let radius = min(cornerRadius, min(rect.width, rect.height) / 2)
        
        var path = Path()
        path.move(to: CGPoint(x: minX + radius, y: minY))
        
        // Top edge to top-right corner
        path.addLine(to: CGPoint(x: maxX - radius, y: minY))
        
        // Top-right corner (continuous curve)
        path.addQuadCurve(
            to: CGPoint(x: maxX, y: minY + radius),
            control: CGPoint(x: maxX, y: minY)
        )
        
        // Right edge to bottom-right corner
        path.addLine(to: CGPoint(x: maxX, y: maxY - radius))
        
        // Bottom-right corner (continuous curve)
        path.addQuadCurve(
            to: CGPoint(x: maxX - radius, y: maxY),
            control: CGPoint(x: maxX, y: maxY)
        )
        
        // Bottom edge to bottom-left corner
        path.addLine(to: CGPoint(x: minX + radius, y: maxY))
        
        // Bottom-left corner (continuous curve)
        path.addQuadCurve(
            to: CGPoint(x: minX, y: maxY - radius),
            control: CGPoint(x: minX, y: maxY)
        )
        
        // Left edge to top-left corner
        path.addLine(to: CGPoint(x: minX, y: minY + radius))
        
        // Top-left corner (continuous curve)
        path.addQuadCurve(
            to: CGPoint(x: minX + radius, y: minY),
            control: CGPoint(x: minX, y: minY)
        )
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Squircle Convenience

extension View {
    /// Apply squircle shape with continuous corners
    func squircle(cornerRadius: CGFloat) -> some View {
        clipShape(Squircle(cornerRadius: cornerRadius))
    }
}

// MARK: - Pressable View Modifier

/// Interactive press feedback with scale and optional haptic
struct PressableModifier: ViewModifier {
    let scaleAmount: CGFloat
    let hapticEnabled: Bool
    let shadowLift: CGFloat
    
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scaleAmount : 1.0)
            .shadow(
                color: .black.opacity(isPressed ? 0.05 : 0.1),
                radius: isPressed ? shadowLift / 2 : shadowLift,
                x: 0,
                y: isPressed ? shadowLift / 4 : shadowLift / 2
            )
            .animation(.pressAnimation, value: isPressed)
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            if hapticEnabled {
                                HapticManager.shared.impact(.light)
                            }
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.pressAnimation) {
                            isPressed = false
                        }
                    }
            )
    }
}

extension View {
    /// Add press feedback to any view
    /// - Parameters:
    ///   - scale: Scale amount on press (0.96 for cards, 0.94 for buttons)
    ///   - haptic: Whether to trigger haptic feedback
    func pressable(scale: CGFloat = 0.96, haptic: Bool = true) -> some View {
        modifier(PressableModifier(scaleAmount: scale, hapticEnabled: haptic, shadowLift: 4))
    }
    
    /// Pressable for buttons (more pronounced feedback)
    func buttonPressable(haptic: Bool = true) -> some View {
        pressable(scale: 0.94, haptic: haptic)
    }
    
    /// Pressable for cards (subtle feedback)
    func cardPressable(haptic: Bool = true) -> some View {
        pressable(scale: 0.97, haptic: haptic)
    }
}

// MARK: - Bounce Effect Modifier

/// Trigger a bounce animation on state change
struct BounceModifier: ViewModifier {
    let trigger: Bool
    let scale: CGFloat
    
    @State private var bounceState: Bool = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(bounceState ? scale : 1.0)
            .animation(.bouncy, value: bounceState)
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    withAnimation(.bouncy) {
                        bounceState = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.bouncy) {
                            bounceState = false
                        }
                    }
                }
            }
    }
}

extension View {
    /// Trigger a bounce animation when trigger becomes true
    func bounce(on trigger: Bool, scale: CGFloat = 1.08) -> some View {
        modifier(BounceModifier(trigger: trigger, scale: scale))
    }
}

// MARK: - Scale on Appear Modifier

/// Subtle scale animation when view appears
struct ScaleInModifier: ViewModifier {
    let delay: Double
    let initialScale: CGFloat
    let animation: Animation
    
    @State private var hasAppeared = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(hasAppeared ? 1.0 : initialScale)
            .opacity(hasAppeared ? 1.0 : 0.0)
            .animation(animation, value: hasAppeared)
            .onAppear {
                withAnimation(animation) {
                    hasAppeared = true
                }
            }
    }
}

extension View {
    /// Animate view appearing with a subtle scale
    func scaleIn(delay: Double = 0, initialScale: CGFloat = 0.95) -> some View {
        modifier(ScaleInModifier(
            delay: delay,
            initialScale: initialScale,
            animation: .smooth
        ))
    }
    
    /// Animate view appearing with a bouncy scale
    func bounceIn(delay: Double = 0, initialScale: CGFloat = 0.9) -> some View {
        modifier(ScaleInModifier(
            delay: delay,
            initialScale: initialScale,
            animation: .bouncy
        ))
    }
}

// MARK: - Toggle Style with Haptics

/// Toggle style with haptic feedback and spring animation
struct PhysicsToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
            HapticManager.shared.selection()
        }) {
            HStack(spacing: 12) {
                configuration.label
                
                RoundedRectangle(cornerRadius: 16)
                    .fill(configuration.isOn ? Color.accentColor : Color.gray.opacity(0.3))
                    .frame(width: 50, height: 30)
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .padding(2)
                            .offset(x: configuration.isOn ? 10 : -10)
                    )
                    .animation(.bouncy, value: configuration.isOn)
            }
        }
        .buttonStyle(.plain)
    }
}

extension ToggleStyle where Self == PhysicsToggleStyle {
    static var physics: PhysicsToggleStyle {
        PhysicsToggleStyle()
    }
}

// MARK: - Preview

#Preview("Physics Interactions") {
    ScrollView {
        VStack(spacing: 24) {
            // Pressable buttons
            VStack(spacing: 12) {
                Text("Pressable Buttons")
                    .font(.headline)
                
                Button("Button (0.94 scale)") {}
                    .buttonPressable()
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                
                Text("Card (0.96 scale)")
                    .padding()
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(12)
                    .cardPressable()
            }
            
            Divider()
            
            // Toggle with haptics
            VStack(spacing: 12) {
                Text("Toggle with Haptics")
                    .font(.headline)
                
                Toggle(isOn: .constant(true)) {
                    Label("Enable Notifications", systemImage: "bell.fill")
                }
                .toggleStyle(.physics)
            }
            
            Divider()
            
            // Bounce effect
            VStack(spacing: 12) {
                Text("Bounce Effect")
                    .font(.headline)
                
                Button("Trigger Bounce") {
                    HapticManager.shared.success()
                }
                .buttonStyle(.borderedProminent)
            }
            
            Divider()
            
            // Scale in animation
            VStack(spacing: 12) {
                Text("Scale In Animations")
                    .font(.headline)
                
                Text("Bounce In")
                    .padding()
                    .background(Color.accentColor.opacity(0.2))
                    .cornerRadius(12)
                    .bounceIn()
                
                Text("Scale In")
                    .padding()
                    .background(Color.accentColor.opacity(0.2))
                    .cornerRadius(12)
                    .scaleIn()
            }
        }
        .padding()
    }
}
