//
//  StoryCard.swift
//  StoryRide
//
//  Adaptive story card that changes based on persona
//

import SwiftUI

// MARK: - Story Model

struct Story: Identifiable {
    let id = UUID()
    let title: String
    let storyteller: String
    let imageURL: String?
    let voiceCount: Int
    let timestamp: Date
    let storytellerRole: PersonaRole

    var storytellerColor: Color {
        switch storytellerRole {
        case .elder:
            return .storytellerOrange
        case .parent:
            return .storytellerBlue
        case .teen:
            return .storytellerPurple
        case .child:
            return .storytellerGreen
        }
    }
}

// MARK: - Story Card

struct StoryCard: View {
    @Environment(\.theme) var theme
    let story: Story

    var body: some View {
        switch theme.role {
        case .teen:
            TeenStoryCard(story: story, theme: theme)
        case .parent:
            ParentStoryCard(story: story, theme: theme)
        case .child:
            ChildStoryCard(story: story, theme: theme)
        case .elder:
            ElderStoryCard(story: story, theme: theme)
        }
    }
}

// MARK: - Teen Story Card (Full Bleed, Minimalist)

struct TeenStoryCard: View {
    let story: Story
    let theme: PersonaTheme

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Full screen background
                AsyncImage(url: URL(string: story.imageURL ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    case .failure(_), .empty:
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        story.storytellerColor.opacity(0.6),
                                        story.storytellerColor
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    @unknown default:
                        Color.gray
                    }
                }

                // Text overlay at bottom
                VStack(alignment: .leading, spacing: 12) {
                    Text(story.title)
                        .font(theme.headlineFont)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .shadow(color: .black.opacity(0.5), radius: 4, y: 2)

                    HStack(spacing: 8) {
                        Circle()
                            .fill(story.storytellerColor)
                            .frame(width: 10, height: 10)

                        Text(story.storyteller)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.95))

                        if story.voiceCount > 1 {
                            Text("+ \(story.voiceCount - 1) more")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [
                            .clear,
                            .black.opacity(0.4),
                            .black.opacity(0.75),
                            .black.opacity(0.95)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 250)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                )
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(story.title) by \(story.storyteller)")
        .accessibilityHint("Double tap to view story")
    }
}

// MARK: - Parent Story Card (Clean Separation)

struct ParentStoryCard: View {
    let story: Story
    let theme: PersonaTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image section
            AsyncImage(url: URL(string: story.imageURL ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(4/3, contentMode: .fill)
                case .failure(_), .empty:
                    Rectangle()
                        .fill(story.storytellerColor.opacity(0.2))
                        .aspectRatio(4/3, contentMode: .fill)
                @unknown default:
                    Color.gray
                }
            }
            .clipped()

            // Text section
            VStack(alignment: .leading, spacing: 8) {
                Text(story.title)
                    .font(theme.headlineFont)
                    .foregroundColor(theme.textColor)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Circle()
                        .fill(story.storytellerColor)
                        .frame(width: 12, height: 12)

                    Text(story.storyteller)
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryTextColor)

                    if story.voiceCount > 1 {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor)
                        Text("\(story.voiceCount)")
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor)
                    }

                    Spacer()

                    Text(story.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
            }
            .padding(16)
        }
        .background(theme.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: theme.cardRadius))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(story.title) by \(story.storyteller)")
    }
}

// MARK: - Child Story Card (Giant, Readable)

struct ChildStoryCard: View {
    let story: Story
    let theme: PersonaTheme

    var body: some View {
        VStack(spacing: 16) {
            // Image takes up 80% of card
            AsyncImage(url: URL(string: story.imageURL ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                case .failure(_), .empty:
                    Rectangle()
                        .fill(story.storytellerColor.opacity(0.3))
                        .aspectRatio(1, contentMode: .fill)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 64))
                                .foregroundColor(.white)
                        )
                @unknown default:
                    Color.gray
                }
            }
            .frame(height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Huge readable text
            Text(story.title)
                .font(theme.headlineFont)
                .foregroundColor(theme.textColor)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .padding(.horizontal)
        }
        .padding(theme.screenPadding)
        .frame(maxWidth: .infinity)
        .background(theme.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: theme.cardRadius))
        .shadow(color: story.storytellerColor.opacity(0.3), radius: 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(story.title)
    }
}

// MARK: - Elder Story Card (Single, Centered)

struct ElderStoryCard: View {
    let story: Story
    let theme: PersonaTheme

    var body: some View {
        VStack(spacing: 24) {
            // Large image
            AsyncImage(url: URL(string: story.imageURL ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(4/3, contentMode: .fit)
                case .failure(_), .empty:
                    Rectangle()
                        .fill(story.storytellerColor.opacity(0.2))
                        .aspectRatio(4/3, contentMode: .fit)
                @unknown default:
                    Color.gray
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: theme.cardRadius))
            .shadow(color: .black.opacity(0.1), radius: 12)

            // Large, clear text
            VStack(spacing: 16) {
                Text(story.title)
                    .font(theme.headlineFont)
                    .foregroundColor(theme.textColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)

                Text("by \(story.storyteller)")
                    .font(theme.bodyFont)
                    .foregroundColor(theme.secondaryTextColor)
            }
            .padding(.horizontal, theme.screenPadding)
        }
        .padding(theme.screenPadding)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(story.title) by \(story.storyteller)")
        .accessibilityHint("This story will be read aloud to you")
    }
}

// MARK: - Preview

struct StoryCard_Previews: PreviewProvider {
    static let sampleStory = Story(
        title: "The Summer Road Trip of '68",
        storyteller: "Grandma Rose",
        imageURL: nil,
        voiceCount: 3,
        timestamp: Date(),
        storytellerRole: .elder
    )

    static var previews: some View {
        Group {
            ScrollView {
                StoryCard(story: sampleStory)
                    .padding()
            }
            .themed(TeenTheme())
            .previewDisplayName("Teen")

            ScrollView {
                StoryCard(story: sampleStory)
                    .padding()
            }
            .themed(ParentTheme())
            .previewDisplayName("Parent")

            StoryCard(story: sampleStory)
                .themed(ChildTheme())
                .previewDisplayName("Child")

            StoryCard(story: sampleStory)
                .themed(ElderTheme())
                .previewDisplayName("Elder")
        }
    }
}
