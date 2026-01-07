import SwiftUI

extension Color {
    static let brandIndigo = Color(red: 0.345, green: 0.337, blue: 0.839)
}

struct QuoteShareLink: View {
    let quote: String
    let author: String
    let imageUrl: String?
    let onShare: () -> Void
    
    var shareText: String {
        if let imageUrl = imageUrl {
            return "\"\(quote)\"\n— \(author)\n\n\(imageUrl)"
        }
        return "\"\(quote)\"\n— \(author)"
    }
    
    var body: some View {
        ShareLink(
            item: shareText,
            subject: Text("Family Wisdom Quote"),
            message: Text(shareText)
        ) {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                Text("Share")
                    .font(.system(size: 16, weight: .medium))
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.brandIndigo)
    }
}

struct StoryShareLink: View {
    let storyTitle: String
    let storyId: String
    let onShare: (() -> Void)?
    
    private var shareUrl: URL {
        URL(string: "https://storyrd.app/story/\(storyId)")!
    }
    
    var body: some View {
        ShareLink(
            item: shareUrl,
            subject: Text("Family Story"),
            message: Text("Check out this family story: \(storyTitle)")
        ) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 18))
        }
        .tint(Color.brandIndigo)
    }
}

struct QuoteCardShareButton: View {
    let quote: String
    let author: String
    let onShare: () -> Void
    
    var body: some View {
        ShareLink(
            item: "\"\(quote)\"\n— \(author)",
            subject: Text("Family Wisdom"),
            message: Text("\"\\(quote)\"\n— \\(author)")
        ) {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                Text("Share Quote")
                    .font(.system(size: 16, weight: .medium))
            }
        }
        .buttonStyle(.bordered)
        .tint(Color.brandIndigo)
    }
}

struct GenericShareButton: View {
    let title: String
    let url: URL?
    let onShare: (() -> Void)?
    
    var body: some View {
        Group {
            if let url = url {
                ShareLink(
                    item: url,
                    subject: Text(title),
                    message: Text(title)
                ) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Share")
                            .font(.system(size: 16, weight: .medium))
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.brandIndigo)
            } else {
                ShareLink(
                    item: title,
                    subject: Text(title),
                    message: Text(title)
                ) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Share")
                            .font(.system(size: 16, weight: .medium))
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.brandIndigo)
            }
        }
    }
}

#Preview("Quote Share Link") {
    QuoteShareLink(
        quote: "The dress caught on fire and everyone screamed—except grandma.",
        author: "Grandma",
        imageUrl: nil,
        onShare: { print("shared") }
    )
    .padding()
}

#Preview("Story Share Link") {
    StoryShareLink(
        storyTitle: "The Great Fire of 1978",
        storyId: "abc-123",
        onShare: nil
    )
    .padding()
}
