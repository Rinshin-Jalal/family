//
//  ThemeToggle.swift
//  familyplus
//
//  Simple theme toggle for dark/light mode
//

import SwiftUI

// MARK: - Theme Toggle

struct ThemeToggle: View {
    @Binding var currentTheme: AppTheme
    
    var body: some View {
        Button(action: {
            #if os(iOS)
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            #endif
            withAnimation(.bouncy) {
                currentTheme = currentTheme == .dark ? .light : .dark
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: currentTheme.icon)
                    .font(.system(size: 14, weight: .semibold))
                
                Text(currentTheme.displayName)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.primary.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Switch theme. Current: \(currentTheme.displayName)")
        .accessibilityHint("Double tap to toggle between dark and light mode")
    }
}

// MARK: - Preview

struct ThemeToggle_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ThemeToggle(currentTheme: .constant(.dark))
            ThemeToggle(currentTheme: .constant(.light))
        }
        .padding()
        .themed(LightTheme())
    }
}
