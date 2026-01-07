import SwiftUI

private struct QuoteCardColor {
    static let brandIndigo = SwiftUI.Color(red: 0.345, green: 0.337, blue: 0.839)
    static let storytellerOrange = SwiftUI.Color(red: 1.0, green: 0.584, blue: 0.0)
}

struct QuoteCardDisplay: View {
    let quote: String
    let author: String
    let authorRole: String?
    let accentColor: SwiftUI.Color
    let onShare: (() -> Void)?
    let onSave: (() -> Void)?

    @Environment(\.theme) private var theme

    init(
        quote: String,
        author: String,
        authorRole: String? = nil,
        accentColor: SwiftUI.Color = QuoteCardColor.brandIndigo,
        onShare: (() -> Void)? = nil,
        onSave: (() -> Void)? = nil
    ) {
        self.quote = quote
        self.author = author
        self.authorRole = authorRole
        self.accentColor = accentColor
        self.onShare = onShare
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "quote.opening")
                .font(.system(size: 40))
                .foregroundColor(accentColor.opacity(0.3))

            Text("\"\(quote)\"")
                .font(.custom("Georgia", size: 22).italic())
                .foregroundColor(theme.textColor)
                .multilineTextAlignment(.center)
                .lineSpacing(6)

            HStack(spacing: 12) {
                Circle()
                    .fill(accentColor)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(author.prefix(1)))
                            .font(.headline)
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("— \(author)")
                        .font(.subheadline)
                        .foregroundColor(theme.textColor)

                    if let role = authorRole, !role.isEmpty {
                        Text(role)
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }
            }

            if onShare != nil || onSave != nil {
                HStack(spacing: 12) {
                    if let onShare = onShare {
                        Button(action: onShare) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 20))
                                .foregroundColor(QuoteCardColor.brandIndigo)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                )
                        }
                    }
                    if let onSave = onSave {
                        Button(action: onSave) {
                            Image(systemName: "bookmark")
                                .font(.system(size: 20))
                                .foregroundColor(QuoteCardColor.brandIndigo)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                )
                        }
                    }
                }
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: theme.cardRadius * 2)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cardRadius * 2)
                        .stroke(accentColor.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: accentColor.opacity(0.15), radius: 20, x: 0, y: 10)
        )
    }
}

struct QuoteCardSelector: View {
    let quote: QuoteCardData
    let isSelected: Bool
    let onTap: () -> Void

    @Environment(\.theme) private var theme

    private let brandIndigo = SwiftUI.Color(red: 0.345, green: 0.337, blue: 0.839)

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? brandIndigo.opacity(0.15) : SwiftUI.Color.clear)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "quote.opening")
                            .font(.system(size: 20))
                            .foregroundColor(isSelected ? brandIndigo : theme.secondaryTextColor)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(quote.quote)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.textColor)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text("— \(quote.author)")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(brandIndigo)
                        .symbolEffect(.bounce, value: isSelected)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: theme.cardRadius)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.cardRadius)
                    .stroke(isSelected ? brandIndigo : SwiftUI.Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct QuoteCardData: Identifiable, Codable {
    let id: String
    let quote: String
    let author: String
    let authorRole: String?
    let theme: String
    let imageUrl: String?
    let viewsCount: Int
    let sharesCount: Int
    let savesCount: Int
}
