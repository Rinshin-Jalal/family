//
//  LoadingStates.swift
//  StoryRide
//
//  Loading states, skeleton loaders, and empty states for all personas
//

import SwiftUI

// MARK: - Loading State Enum

enum LoadingState<T>: Equatable {
    case loading
    case empty
    case loaded(T)
    case error(String)

    static func == (lhs: LoadingState<T>, rhs: LoadingState<T>) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading), (.empty, .empty):
            return true
        case (.loaded(let lhsValue), .loaded(let rhsValue)):
            if let lhsHashable = lhsValue as? any Hashable,
               let rhsHashable = rhsValue as? any Hashable {
                return lhsHashable.hashValue == rhsHashable.hashValue
            }
            // For non-hashable types, just return false
            return false
        case (.error(let lhsMsg), .error(let rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var isEmpty: Bool {
        if case .empty = self { return true }
        return false
    }

    var data: T? {
        if case .loaded(let data) = self { return data }
        return nil
    }
}

// MARK: - Shimmer Effect

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.4),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: phase * geometry.size.width * 2 - geometry.size.width)
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - Skeleton Shape

struct SkeletonShape: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat

    init(width: CGFloat? = nil, height: CGFloat = 16, cornerRadius: CGFloat = 8) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.gray.opacity(0.2))
            .frame(width: width, height: height)
            .shimmer()
    }
}

// MARK: - Teen Feed Card Skeleton

struct TeenFeedCardSkeleton: View {
    @Environment(\.theme) var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image placeholder
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.gray.opacity(0.15))
                .frame(height: 400)
                .shimmer()

            // Text section
            VStack(alignment: .leading, spacing: 12) {
                // Title skeleton
                SkeletonShape(height: 24, cornerRadius: 6)
                SkeletonShape(width: 200, height: 24, cornerRadius: 6)

                // Storyteller skeleton
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 10, height: 10)
                        .shimmer()

                    SkeletonShape(width: 100, height: 14, cornerRadius: 4)

                    Spacer()

                    SkeletonShape(width: 60, height: 12, cornerRadius: 4)
                }
            }
            .padding(16)
            .background(theme.cardBackgroundColor)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
    }
}

// MARK: - Parent Grid Card Skeleton

struct ParentGridCardSkeleton: View {
    @Environment(\.theme) var theme
    let isLarge: Bool

    var cardHeight: CGFloat {
        isLarge ? 280 : 220
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image placeholder
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.gray.opacity(0.12))
                .frame(height: cardHeight * 0.6)
                .shimmer()

            // Text section
            VStack(alignment: .leading, spacing: 8) {
                SkeletonShape(height: 16, cornerRadius: 4)
                SkeletonShape(width: 80, height: 16, cornerRadius: 4)

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 8, height: 8)
                        .shimmer()

                    SkeletonShape(width: 60, height: 12, cornerRadius: 3)
                }

                SkeletonShape(width: 50, height: 10, cornerRadius: 3)
            }
            .padding(12)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
    }
}

// MARK: - Child Card Skeleton

struct ChildCardSkeleton: View {
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 24) {
            // Story counter skeleton
            SkeletonShape(width: 120, height: 20, cornerRadius: 10)
                .padding(.top, theme.screenPadding)

            Spacer()

            // Large card skeleton
            VStack(spacing: 16) {
                // Image area
                RoundedRectangle(cornerRadius: theme.cardRadius)
                    .fill(Color.gray.opacity(0.15))
                    .aspectRatio(1, contentMode: .fit)
                    .shimmer()

                // Title skeleton
                SkeletonShape(height: 28, cornerRadius: 8)
                SkeletonShape(width: 150, height: 20, cornerRadius: 6)
            }
            .padding(.horizontal, theme.screenPadding)

            // Listen button skeleton
            RoundedRectangle(cornerRadius: theme.cardRadius)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 80)
                .padding(.horizontal, theme.screenPadding)
                .shimmer()

            Spacer()

            // Navigation arrows skeleton
            HStack(spacing: 60) {
                Circle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 64, height: 64)
                    .shimmer()

                Circle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 64, height: 64)
                    .shimmer()
            }
            .padding(.bottom, theme.screenPadding)
        }
    }
}

// MARK: - Elder Skeleton

struct ElderSkeleton: View {
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Icon skeleton
            Circle()
                .fill(Color.gray.opacity(0.15))
                .frame(width: 120, height: 120)
                .shimmer()

            // Text skeleton
            VStack(spacing: 16) {
                SkeletonShape(width: 200, height: 36, cornerRadius: 8)
                SkeletonShape(width: 250, height: 24, cornerRadius: 6)
            }

            Spacer()

            // Button skeleton
            RoundedRectangle(cornerRadius: theme.cardRadius)
                .fill(Color.gray.opacity(0.2))
                .frame(height: theme.buttonHeight)
                .padding(.horizontal, theme.screenPadding)
                .shimmer()
                .padding(.bottom, 60)
        }
    }
}

// MARK: - Progress Banner Skeleton (Parent)

struct ProgressBannerSkeleton: View {
    @Environment(\.theme) var theme

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.gray.opacity(0.15))
                .frame(width: 48, height: 48)
                .shimmer()

            VStack(alignment: .leading, spacing: 8) {
                SkeletonShape(width: 80, height: 18, cornerRadius: 4)
                SkeletonShape(width: 140, height: 14, cornerRadius: 4)
            }

            Spacer()

            Circle()
                .fill(Color.gray.opacity(0.15))
                .frame(width: 36, height: 36)
                .shimmer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackgroundColor)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
}

// MARK: - Empty State Base

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String?
    let action: (() -> Void)?

    @Environment(\.theme) var theme

    init(
        icon: String,
        title: String,
        subtitle: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundColor(theme.accentColor.opacity(0.6))

            VStack(spacing: 12) {
                Text(title)
                    .font(theme.headlineFont)
                    .foregroundColor(theme.textColor)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(theme.bodyFont)
                    .foregroundColor(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(height: 50)
                        .padding(.horizontal, 32)
                        .background(theme.accentColor)
                        .clipShape(Capsule())
                }
                .padding(.top, 8)
            }

            Spacer()
        }
    }
}

// MARK: - Teen Empty State

struct TeenEmptyState: View {
    @Environment(\.theme) var theme
    let onCreateStory: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Aesthetic minimal icon
            ZStack {
                Circle()
                    .stroke(theme.accentColor.opacity(0.2), lineWidth: 2)
                    .frame(width: 140, height: 140)

                Circle()
                    .stroke(theme.accentColor.opacity(0.1), lineWidth: 1)
                    .frame(width: 180, height: 180)

                Image(systemName: "waveform.path")
                    .font(.system(size: 48))
                    .foregroundColor(theme.accentColor)
            }

            VStack(spacing: 16) {
                Text("No Stories Yet")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(theme.textColor)

                Text("Start your family's story archive.\nBe the first to capture a memory.")
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer()

            // Minimal create button
            Button(action: onCreateStory) {
                HStack(spacing: 12) {
                    Image(systemName: "plus")
                        .font(.title3.bold())

                    Text("Create Story")
                        .font(.headline)
                }
                .foregroundColor(theme.backgroundColor)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(theme.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, theme.screenPadding)
            .padding(.bottom, 40)
        }
        .background(theme.backgroundColor)
    }
}

// MARK: - Parent Empty State

struct ParentEmptyState: View {
    @Environment(\.theme) var theme
    let onCreateStory: () -> Void
    let onInviteFamily: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Organized icon with family imagery
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(theme.accentColor.opacity(0.1))
                    .frame(width: 160, height: 160)

                VStack(spacing: 8) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 48))
                        .foregroundColor(theme.accentColor)

                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 24))
                        .foregroundColor(theme.accentColor.opacity(0.6))
                }
            }

            VStack(spacing: 12) {
                Text("Start Your Family Archive")
                    .font(.title2.bold())
                    .foregroundColor(theme.textColor)

                Text("Capture stories from every generation.\nInvite family members to share their memories.")
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            // Two action buttons
            VStack(spacing: 12) {
                Button(action: onCreateStory) {
                    HStack(spacing: 8) {
                        Image(systemName: "mic.fill")
                        Text("Record First Story")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(theme.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button(action: onInviteFamily) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                        Text("Invite Family Members")
                    }
                    .font(.headline)
                    .foregroundColor(theme.accentColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(theme.accentColor, lineWidth: 2)
                    )
                }
            }
            .padding(.horizontal, theme.screenPadding)

            Spacer()
        }
        .background(theme.backgroundColor)
    }
}

// MARK: - Child Empty State

struct ChildEmptyState: View {
    @Environment(\.theme) var theme
    let onRecordStory: () -> Void

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Playful animated icon
            ZStack {
                // Bouncing circles
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(theme.accentColor.opacity(0.2 - Double(index) * 0.05))
                        .frame(width: CGFloat(180 + index * 40), height: CGFloat(180 + index * 40))
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: isAnimating
                        )
                }

                // Star icon
                Image(systemName: "sparkles")
                    .font(.system(size: 64))
                    .foregroundColor(theme.accentColor)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isAnimating)
            }
            .onAppear { isAnimating = true }

            // Kid-friendly text
            VStack(spacing: 16) {
                Text("No Stories Yet!")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textColor)

                Text("Be the first to tell a story!")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(theme.secondaryTextColor)
            }

            Spacer()

            // Giant record button
            Button(action: onRecordStory) {
                HStack(spacing: 16) {
                    Image(systemName: "mic.circle.fill")
                        .font(.system(size: 40))

                    Text("Tell a Story!")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background(theme.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: theme.accentColor.opacity(0.4), radius: 20)
            }
            .padding(.horizontal, theme.screenPadding)
            .padding(.bottom, 60)
        }
        .background(theme.backgroundColor)
    }
}

// MARK: - Elder Empty State

struct ElderEmptyState: View {
    @Environment(\.theme) var theme
    let onCallMe: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Simple phone icon
            ZStack {
                Circle()
                    .fill(theme.accentColor.opacity(0.1))
                    .frame(width: 180, height: 180)

                Image(systemName: "phone.arrow.down.left")
                    .font(.system(size: 72))
                    .foregroundColor(theme.accentColor)
            }

            // Clear, large text
            VStack(spacing: 20) {
                Text("No Stories Yet")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(theme.textColor)

                Text("We'll call you when your family\nwants to hear a story from you.")
                    .font(.title3)
                    .foregroundColor(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }

            Spacer()

            // Large call button
            Button(action: onCallMe) {
                HStack(spacing: 16) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 28))

                    Text("Call Me Now")
                        .font(.title2.bold())
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background(theme.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .padding(.horizontal, theme.screenPadding)
            .padding(.bottom, 60)
        }
        .background(theme.backgroundColor)
    }
}

// MARK: - Error State

struct ErrorStateView: View {
    let message: String
    let onRetry: () -> Void

    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 64))
                .foregroundColor(.orange)

            VStack(spacing: 12) {
                Text("Something Went Wrong")
                    .font(theme.headlineFont)
                    .foregroundColor(theme.textColor)

                Text(message)
                    .font(theme.bodyFont)
                    .foregroundColor(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button(action: onRetry) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(height: 50)
                .padding(.horizontal, 32)
                .background(theme.accentColor)
                .clipShape(Capsule())
            }

            Spacer()
        }
    }
}

// MARK: - Preview

struct LoadingStates_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Skeleton previews
            ScrollView {
                VStack(spacing: 16) {
                    TeenFeedCardSkeleton()
                    TeenFeedCardSkeleton()
                }
                .padding()
            }
            .background(Color.black)
            .themed(TeenTheme())
            .previewDisplayName("Teen Skeleton")

            // Empty state previews
            TeenEmptyState(onCreateStory: {})
                .themed(TeenTheme())
                .previewDisplayName("Teen Empty")

            ParentEmptyState(onCreateStory: {}, onInviteFamily: {})
                .themed(ParentTheme())
                .previewDisplayName("Parent Empty")

            ChildEmptyState(onRecordStory: {})
                .themed(ChildTheme())
                .previewDisplayName("Child Empty")

            ElderEmptyState(onCallMe: {})
                .themed(ElderTheme())
                .previewDisplayName("Elder Empty")
        }
    }
}
