//
//  WisdomSearchView.swift
//  StoryRide
//
//  Search for wisdom by asking questions - Now with Supermemory-style semantic search!
//

import SwiftUI
import AVFoundation

struct WisdomSearchView: View {
    @Environment(\.theme) private var theme
    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    @State private var searchResults: [SemanticSearchResult] = []
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

            if isSearching {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
            } else if showNoResults {
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

            Text("Find wisdom using semantic search - understands meaning, not just keywords!")
                .font(theme.bodyFont)
                .foregroundColor(theme.textColor.opacity(0.7))
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                TextField("Ask: \"What did grandpa say about love?\"", text: $searchText)
                    .font(theme.bodyFont)
                    .padding()
                    .background(theme.cardBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .foregroundColor(theme.textColor)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onSubmit {
                        performSearch()
                    }

                Button(action: performSearch) {
                    if isSearching {
                        ProgressView()
                            .foregroundColor(.white)
                            .padding()
                    } else {
                        Image(systemName: "magnifyingglass")
                            .font(theme.headlineFont)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                .disabled(searchText.isEmpty || isSearching)
            }
            .padding(.horizontal)

            // Quick search suggestions
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(["childhood memories", "family traditions", "advice about love", "grandparents", "holiday stories"], id: \.self) { suggestion in
                        Button(action: {
                            searchText = suggestion
                            performSearch()
                        }) {
                            Text(suggestion)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(theme.accentColor.opacity(0.1))
                                .foregroundColor(theme.accentColor)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(theme.accentColor.opacity(0.5))

            Text("Semantic Memory Search")
                .font(theme.headlineFont)
                .foregroundColor(theme.textColor)

            Text("Ask anything to find relevant stories and wisdom.\nSearches by meaning, not just keywords!")
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
                ForEach(searchResults) { result in
                    SemanticResultCard(result: result)
                        .onTapGesture {
                            if result.type == "story", let uuid = UUID(uuidString: result.id) {
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

        Task {
            do {
                // Use real semantic search API
                let response = try await APIService.shared.semanticSearch(query: searchText, limit: 10)
                await MainActor.run {
                    searchResults = response.results
                    showNoResults = searchResults.isEmpty
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showNoResults = true
                    isSearching = false
                }
            }
        }
    }
}

struct SemanticResultCard: View {
    @Environment(\.theme) private var theme
    let result: SemanticSearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with type badge and match score
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: result.type == "quote" ? "quote.bubble.fill" : "book.fill")
                        .font(.caption)
                    Text(result.type == "quote" ? "Quote" : "Story")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(result.type == "quote" ? Color.pink.opacity(0.2) : Color.blue.opacity(0.2))
                .foregroundColor(result.type == "quote" ? .pink : .blue)
                .clipShape(Capsule())

                Spacer()

                // Similarity score
                Text("\(Int(result.similarity * 100))% match")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Quote-specific display
            if result.type == "quote" {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\"\(result.content)\"")
                        .font(theme.bodyFont)
                        .foregroundColor(theme.textColor)
                        .italic()

                    if let author = result.author {
                        HStack(spacing: 6) {
                            Text("— \(author)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if let role = result.role {
                                Text("(\(role.capitalized))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            } else {
                // Story display
                VStack(alignment: .leading, spacing: 8) {
                    if !result.title.isEmpty {
                        Text(result.title)
                            .font(theme.headlineFont)
                            .foregroundColor(theme.textColor)
                    }

                    Text(result.content)
                        .font(theme.bodyFont)
                        .foregroundColor(theme.textColor.opacity(0.8))
                        .lineLimit(3)
                }
            }

            // Action hint
            HStack {
                Image(systemName: result.type == "quote" ? "square.and.arrow.up" : "play.circle.fill")
                    .font(.caption)
                    .foregroundColor(theme.accentColor)
                Text(result.type == "quote" ? "Tap to share" : "Tap to listen")
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
