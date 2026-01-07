import SwiftUI

struct RecordTagsScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var showSections: [Bool] = [false, false, false]
    
    private let tagSections: [(title: String, icon: String, tags: [String], color: Color)] = [
        ("Emotions", "heart.fill", ["Nostalgia", "Hope", "Courage", "Love"], .pink),
        ("Life Events", "calendar", ["Immigration", "New Beginnings", "Family History"], .blue),
        ("Wisdom", "lightbulb.fill", ["Perseverance", "Family Values", "Sacrifice"], .green)
    ]
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(theme.accentColor.opacity(0.1))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "tag.fill")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(theme.accentColor)
                            }
                            .opacity(showContent ? 1 : 0)
                            .scaleEffect(showContent ? 1 : 0.5)
                            
                            Text("Story Tags")
                                .font(theme.headlineFont)
                                .foregroundColor(theme.textColor)
                                .opacity(showContent ? 1 : 0)
                            
                            Text("AI discovered these themes in your story")
                                .font(theme.bodyFont)
                                .foregroundColor(theme.secondaryTextColor)
                                .opacity(showContent ? 1 : 0)
                        }
                        .padding(.top, 24)
                        
                        VStack(spacing: 20) {
                            ForEach(Array(tagSections.enumerated()), id: \.offset) { index, section in
                                TagSectionCard(
                                    title: section.title,
                                    icon: section.icon,
                                    tags: section.tags,
                                    color: section.color,
                                    isVisible: showSections[index]
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        VStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 12))
                                Text("Tags help your family find relevant stories")
                            }
                            .font(.system(size: 13))
                            .foregroundColor(theme.secondaryTextColor)
                        }
                        .padding(.top, 8)
                        .opacity(showContent ? 1 : 0)
                        
                        Spacer(minLength: 120)
                    }
                }
                
                OnboardingCTAButton(
                    title: "Continue",
                    action: {
                        coordinator.goToNextStep()
                    }
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
            
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(i) * 0.15) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        showSections[i] = true
                    }
                }
            }
        }
    }
}

private struct TagSectionCard: View {
    let title: String
    let icon: String
    let tags: [String]
    let color: Color
    let isVisible: Bool
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
                
                Text(title.uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(color)
                    .tracking(0.5)
            }
            
            FlowLayout(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(color)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(color.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
    }
}

#Preview {
    RecordTagsScreenView(coordinator: .preview)
        .themed(LightTheme())
}
