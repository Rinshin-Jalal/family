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

