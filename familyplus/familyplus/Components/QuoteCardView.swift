import SwiftUI

struct QuoteCardDisplay: View {
    let quote: String
    let author: String
    let accentColor: Color
    
    init(
        quote: String,
        author: String,
        accentColor: Color = .accentColor
    ) {
        self.quote = quote
        self.author = author
        self.accentColor = accentColor
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("\"\(quote)\"")
                .font(.body)
                .multilineTextAlignment(.center)
            
            Text("— \(author)")
                .font(.caption)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}
