//
//  WisdomTagView.swift
//  StoryRide
//
//  Displays wisdom tags on stories
//

import SwiftUI

struct WisdomTagView: View {
    let tags: WisdomTagCategory
    let onTagTapped: ((String) -> Void)?
    
    init(tags: WisdomTagCategory, onTagTapped: ((String) -> Void)? = nil) {
        self.tags = tags
        self.onTagTapped = onTagTapped
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let emotions = tags.emotions, !emotions.isEmpty {
                createTagSection(title: "Emotions", tags: emotions, color: .pink)
            }
            
            if let situations = tags.situations, !situations.isEmpty {
                createTagSection(title: "Situations", tags: situations, color: .blue)
            }
            
            if let lessons = tags.lessons, !lessons.isEmpty {
                createTagSection(title: "Lessons", tags: lessons, color: .green)
            }
            
            if let guidance = tags.guidance, !guidance.isEmpty {
                createTagSection(title: "Guidance", tags: guidance, color: .orange)
            }
        }
    }
    
    private func createTagSection(title: String, tags: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            FlowLayout(spacing: 6) {
                ForEach(tags, id: \.self) { tag in
                    WisdomTagChip(tag: tag, color: color)
                        .onTapGesture {
                            onTagTapped?(tag)
                        }
                }
            }
        }
    }
}

struct WisdomTagChip: View {
    let tag: String
    let color: Color
    
    var body: some View {
        Text(tag)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > width && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: width, height: y + rowHeight)
        }
    }
}

struct WisdomTagCategory {
    let emotions: [String]?
    let situations: [String]?
    let lessons: [String]?
    let guidance: [String]?
    
    init(
        emotions: [String]? = nil,
        situations: [String]? = nil,
        lessons: [String]? = nil,
        guidance: [String]? = nil
    ) {
        self.emotions = emotions
        self.situations = situations
        self.lessons = lessons
        self.guidance = guidance
    }
    
    var isEmpty: Bool {
        (emotions?.isEmpty ?? true) &&
        (situations?.isEmpty ?? true) &&
        (lessons?.isEmpty ?? true) &&
        (guidance?.isEmpty ?? true)
    }
    
    var allTags: [String] {
        var all: [String] = []
        all.append(contentsOf: emotions ?? [])
        all.append(contentsOf: situations ?? [])
        all.append(contentsOf: lessons ?? [])
        all.append(contentsOf: guidance ?? [])
        return all
    }
}

#Preview {
    WisdomTagView(tags: WisdomTagCategory(
        emotions: ["hope", "resilience"],
        situations: ["job-loss", "immigration"],
        lessons: ["persistence", "family-togetherness"],
        guidance: ["what-to-do", "advice"]
    ))
    .padding()
}
