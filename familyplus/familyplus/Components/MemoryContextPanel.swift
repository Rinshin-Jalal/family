//
//  MemoryContextPanel.swift
//  StoryRide
//
//  Slide-up panel showing memory context and metadata
//

import SwiftUI

// MARK: - Memory Context Data

struct MemoryContextData {
    let contributors: [Contributor]
    let yearsSpanned: YearsSpan
    let relatedPrompts: [RelatedPrompt]
    let emotionalTags: [EmotionalTag]

    struct Contributor: Hashable {
        let name: String
        let avatarColor: Color  // Direct color instead of PersonaRole
    }

    struct YearsSpan {
        let startYear: Int
        let endYear: Int?
        let displayString: String
    }

    struct RelatedPrompt {
        let id: String
        let title: String
        let responseCount: Int
    }

    struct EmotionalTag {
        let emoji: String
        let name: String
        let count: Int
    }
}

// MARK: - Memory Context Panel

struct MemoryContextPanel: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    let context: MemoryContextData

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // MARK: - People Section (Leading, as humans anchor meaning)
                    ContributorsSection(
                        contributors: context.contributors,
                        theme: theme
                    )
                    .padding(.bottom, 24)

                    // MARK: - Time Section
                    YearsSpannedSection(
                        yearsSpan: context.yearsSpanned,
                        theme: theme
                    )
                    .padding(.bottom, 24)

                    // MARK: - Emotional Summary Section (Muted, restrained)
                    if !context.emotionalTags.isEmpty {
                        EmotionalSummarySection(
                            tags: context.emotionalTags,
                            theme: theme
                        )
                        .padding(.bottom, 24)
                    }

                    // MARK: - Related Memories Section
                    if !context.relatedPrompts.isEmpty {
                        RelatedPromptsSection(
                            prompts: context.relatedPrompts,
                            theme: theme
                        )
                    }
                }
                .padding(20)
            }
            .background(theme.backgroundColor)
            .navigationTitle("Memory Context")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.accentColor)
                    .font(.system(size: 17, weight: .semibold))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Contributors Section

struct ContributorsSection: View {
    let contributors: [MemoryContextData.Contributor]
    let theme: PersonaTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            Text("Contributors")
                .font(theme.headlineFont)
                .foregroundColor(theme.textColor)
                .fixedSize(horizontal: false, vertical: true)

            // Contextual description
            Text("\(contributors.count) family member\(contributors.count == 1 ? "" : "s") contributed to this memory")
                .font(.system(size: 14))
                .foregroundColor(theme.secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            // Horizontal scrollable avatars with proper spacing
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(contributors, id: \.name) { contributor in
                        ContributorAvatar(contributor: contributor, theme: theme)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: theme.cardRadius)
                .fill(theme.cardBackgroundColor)
        )
    }
}

// MARK: - Contributor Avatar

struct ContributorAvatar: View {
    let contributor: MemoryContextData.Contributor
    let theme: PersonaTheme

    var body: some View {
        VStack(spacing: 8) {
            // Avatar circle
            Circle()
                .fill(contributor.avatarColor.opacity(0.15))
                .frame(width: 60, height: 60)
                .overlay(
                    Circle()
                        .stroke(contributor.avatarColor, lineWidth: 2)
                )
                .overlay {
                    Text(String(contributor.name.prefix(1)).uppercased())
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(contributor.avatarColor)
                }

            // Name and role (defensive: fixed vertical, horizontal expands)
            VStack(spacing: 2) {
                Text(contributor.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(theme.textColor)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .frame(minWidth: 60, maxWidth: 80)
        }
    }
}

// MARK: - Years Spanned Section

struct YearsSpannedSection: View {
    let yearsSpan: MemoryContextData.YearsSpan
    let theme: PersonaTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time Span")
                .font(theme.headlineFont)
                .foregroundColor(theme.textColor)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(yearsSpan.displayString)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(theme.accentColor)

                    Text(yearsSpan.endYear == nil ? "From \(yearsSpan.startYear)" : "Spanning \(yearsSpan.startYear)")
                        .font(.system(size: 13))
                        .foregroundColor(theme.secondaryTextColor)
                }

                Spacer()

                // Timeline indicator
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(index < 3 ? theme.accentColor : theme.secondaryTextColor.opacity(0.3))
                            .frame(width: 5, height: 20)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: theme.cardRadius)
                .fill(theme.cardBackgroundColor)
        )
    }
}

// MARK: - Related Prompts Section

struct RelatedPromptsSection: View {
    let prompts: [MemoryContextData.RelatedPrompt]
    let theme: PersonaTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Related Memories")
                .font(theme.headlineFont)
                .foregroundColor(theme.textColor)

            VStack(spacing: 0) {
                ForEach(Array(prompts.enumerated()), id: \.element.id) { index, prompt in
                    PromptRow(prompt: prompt, theme: theme)

                    if index < prompts.count - 1 {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: theme.cardRadius)
                    .fill(theme.cardBackgroundColor)
            )
        }
    }
}

// MARK: - Prompt Row

struct PromptRow: View {
    let prompt: MemoryContextData.RelatedPrompt
    let theme: PersonaTheme

    var body: some View {
        Button(action: {
            // TODO: Navigate to related prompt
        }) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(prompt.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(theme.textColor)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text("\(prompt.responseCount) perspective\(prompt.responseCount == 1 ? "" : "s")")
                        .font(.system(size: 12))
                        .foregroundColor(theme.secondaryTextColor)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(theme.secondaryTextColor.opacity(0.4))
            }
            .padding(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Emotional Summary Section

struct EmotionalSummarySection: View {
    let tags: [MemoryContextData.EmotionalTag]
    let theme: PersonaTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            Text("Emotional Themes")
                .font(theme.headlineFont)
                .foregroundColor(theme.textColor)
                .fixedSize(horizontal: false, vertical: true)

            // Muted summary text (1-2 dominant emotions only)
            if let dominantTag = tags.max(by: { $0.count < $1.count }) {
                let secondaryTag = tags.filter { $0.name != dominantTag.name }.max(by: { $0.count < $1.count })

                if let secondary = secondaryTag {
                    Text("Mostly remembered as: \(dominantTag.name), \(secondary.name)")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(theme.secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Mostly remembered as: \(dominantTag.name)")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(theme.secondaryTextColor)
                }
            }

            // Subtle chip row (show top 3 only, no emojis, muted style)
            HStack(spacing: 8) {
                ForEach(tags.prefix(3), id: \.name) { tag in
                    Text(tag.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(theme.textColor.opacity(0.8))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(theme.secondaryTextColor.opacity(0.1))
                        )
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: theme.cardRadius)
                .fill(theme.cardBackgroundColor)
        )
    }
}

// MARK: - Emotional Tags Section (Original - kept for reference but not used)

struct EmotionalTagsSection: View {
    let tags: [MemoryContextData.EmotionalTag]
    let theme: PersonaTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Emotional Themes")
                .font(theme.headlineFont)
                .foregroundColor(theme.textColor)

            FlowLayout(spacing: 10) {
                ForEach(tags, id: \.name) { tag in
                    EmotionalTagChip(tag: tag, theme: theme)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: theme.cardRadius)
                .fill(theme.cardBackgroundColor)
        )
    }
}

// MARK: - Emotional Tag Chip

struct EmotionalTagChip: View {
    let tag: MemoryContextData.EmotionalTag
    let theme: PersonaTheme

    var body: some View {
        HStack(spacing: 5) {
            Text(tag.emoji)
                .font(.system(size: 14))

            Text(tag.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.textColor)

            Text("×\(tag.count)")
                .font(.system(size: 12))
                .foregroundColor(theme.secondaryTextColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    private var backgroundColor: Color {
        switch tag.emoji {
        case "❤️": return Color.red.opacity(0.1)
        case "🎉": return Color.orange.opacity(0.1)
        case "😂": return Color.yellow.opacity(0.1)
        case "😢": return Color.blue.opacity(0.1)
        case "😮": return Color.purple.opacity(0.1)
        default: return theme.secondaryTextColor.opacity(0.1)
        }
    }

    private var borderColor: Color {
        switch tag.emoji {
        case "❤️": return Color.red.opacity(0.3)
        case "🎉": return Color.orange.opacity(0.3)
        case "😂": return Color.yellow.opacity(0.3)
        case "😢": return Color.blue.opacity(0.3)
        case "😮": return Color.purple.opacity(0.3)
        default: return Color.clear
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )

        for (index, subview) in subviews.enumerated() {
            subview.place(at: result.positions[index], proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))

                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

// MARK: - Preview Helper

extension MemoryContextData {
    static let mock = MemoryContextData(
        contributors: [
            Contributor(name: "Grandma Rose",  avatarColor: .storytellerOrange),
            Contributor(name: "Dad", avatarColor: .storytellerBlue),
            Contributor(name: "Mom", avatarColor: .storytellerBlue),
            Contributor(name: "Jake", avatarColor: .storytellerPurple)
        ],
        yearsSpanned: YearsSpan(
            startYear: 2019,
            endYear: 2024,
            displayString: "2019-2024"
        ),
        relatedPrompts: [
            RelatedPrompt(id: "1", title: "What was your favorite holiday tradition?", responseCount: 5),
            RelatedPrompt(id: "2", title: "Tell us about a memorable family trip", responseCount: 3),
            RelatedPrompt(id: "3", title: "What's your earliest childhood memory?", responseCount: 7)
        ],
        emotionalTags: [
            EmotionalTag(emoji: "❤️", name: "Love", count: 12),
            EmotionalTag(emoji: "🎉", name: "Celebration", count: 8),
            EmotionalTag(emoji: "😂", name: "Humor", count: 5),
            EmotionalTag(emoji: "😢", name: "Nostalgia", count: 3)
        ]
    )
}

// MARK: - Preview

struct MemoryContextPanel_Previews: PreviewProvider {
    static var previews: some View {
        MemoryContextPanel(context: .mock)
            .themed(LightTheme())
            .previewDisplayName("light Theme")

        MemoryContextPanel(context: .mock)
            .themed(DarkTheme())
            .previewDisplayName("dark Theme")
    }
}
