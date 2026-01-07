//
//  WisdomSearchView.swift
//  StoryRide
//
//  Search for wisdom by asking questions
//

import SwiftUI
import AVFoundation

struct WisdomSearchView: View {
    @Environment(\.theme) private var theme
    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    @State private var searchResults: [WisdomSearchResult] = []
    @State private var errorMessage: String?
    @State private var showNoResults: Bool = false
    
    let onStorySelected: ((UUID) -> Void)?
    let onRequestStory: (() -> Void)?
    
    init(
        onStorySelected: ((UUID) -> Void)? = nil,
        onRequestStory: (() -> Void)? = nil
    ) {
        self.onStorySelected = onStorySelected
        self.onRequestStory = onRequestStory
    }
    
    var body: some View {
        VStack(spacing: 0) {
            searchHeader
            
            if showNoResults && !isSearching {
                noResultsView
            } else if !searchResults.isEmpty {
                searchResultsList
            } else {
                emptyStateView
            }
        }
        .onAppear {
            searchText = ""
        }
    }
    
    private var searchHeader: some View {
        VStack(spacing: 12) {
            Text("Ask the Family")
                .font(theme.headlineFont)
                .foregroundColor(theme.textColor)
            
            Text("Find wisdom from your family's stories")
                .font(theme.bodyFont)
                .foregroundColor(theme.textColor.opacity(0.7))
            
            HStack(spacing: 12) {
                TextField("Ask: \"How did family handle...\"", text: $searchText)
                    .font(theme.bodyFont)
                    .padding()
                    .background(theme.cardBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .foregroundColor(theme.textColor)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                
                Button(action: performSearch) {
                    Image(systemName: "magnifyingglass")
                        .font(theme.headlineFont)
                        .foregroundColor(.white)
                        .padding()
                        .background(searchText.isEmpty ? theme.accentColor.opacity(0.5) : theme.accentColor)
                        .clipShape(Circle())
                }
                .disabled(searchText.isEmpty || isSearching)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(theme.accentColor.opacity(0.5))
            
            Text("Ask your family")
                .font(theme.headlineFont)
                .foregroundColor(theme.textColor)
            
            Text("Search for wisdom by asking questions like:\n\"How did grandparents meet?\"\n\"Family advice about money\"")
                .font(theme.bodyFont)
                .foregroundColor(theme.textColor.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
    
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "questionmark.circle")
                .font(.system(size: 60))
                .foregroundColor(theme.accentColor.opacity(0.5))
            
            Text("No stories found")
                .font(theme.headlineFont)
                .foregroundColor(theme.textColor)
            
            Text("Would you like to request stories from your family about this topic?")
                .font(theme.bodyFont)
                .foregroundColor(theme.textColor.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button(action: { onRequestStory?() }) {
                Text("Request Stories")
                    .font(theme.headlineFont)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(theme.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
    }
    
    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(searchResults, id: \.storyId) { result in
                    WisdomResultCard(result: result)
                        .onTapGesture {
                            if let uuid = UUID(uuidString: result.storyId) {
                                onStorySelected?(uuid)
                            }
                        }
                }
            }
            .padding()
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        showNoResults = false
        searchResults = []
        errorMessage = nil
        
        // Mock search results for now
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run {
                // Add mock results
                searchResults = [
                    WisdomSearchResult(
                        storyId: UUID().uuidString,
                        title: "Sample Story",
                        summaryText: "This is a sample story summary.",
                        coverImageUrl: nil,
                        promptText: nil,
                        emotionTags: ["Nostalgia", "Love"],
                        situationTags: nil,
                        lessonTags: nil,
                        matchScore: 0.85
                    )
                ]
                showNoResults = searchResults.isEmpty
                isSearching = false
            }
        }
    }
}

struct WisdomResultCard: View {
    @Environment(\.theme) private var theme
    let result: WisdomSearchResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let title = result.title {
                    Text(title)
                        .font(theme.headlineFont)
                        .foregroundColor(theme.textColor)
                }
                Spacer()
                if let score = result.matchScore, score > 0 {
                    Text("\(Int(score * 100))% match")
                        .font(.caption)
                        .foregroundColor(theme.accentColor)
                }
            }
            
            if let summary = result.summaryText {
                Text(summary)
                    .font(theme.bodyFont)
                    .foregroundColor(theme.textColor.opacity(0.8))
                    .lineLimit(3)
            }
            
            if let tags = result.emotionTags, !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(tags.prefix(5), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.pink.opacity(0.2))
                                .foregroundColor(.pink)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            
            HStack {
                Image(systemName: "play.circle.fill")
                    .foregroundColor(theme.accentColor)
                Text("Listen to story")
                    .font(.caption)
                    .foregroundColor(theme.accentColor)
                Spacer()
            }
        }
        .padding()
        .background(theme.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
