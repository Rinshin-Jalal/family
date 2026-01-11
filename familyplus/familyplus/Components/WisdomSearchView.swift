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
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Find Family Wisdom")
                    .font(theme.headlineFont.weight(.bold))
                    .foregroundColor(theme.textColor)

                Text("Reconnect with the stories and advice shared by your loved ones.")
                    .font(theme.bodyFont)
                    .foregroundColor(theme.textColor.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            // Search Bar with icon and focus styling
            HStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(theme.textColor.opacity(0.5))
                        .font(.system(size: 18, weight: .medium))

                    TextField("Try: \"What did grandpa say about love?\"", text: $searchText)
                        .font(theme.bodyFont)
                        .foregroundColor(theme.textColor)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onSubmit {
                            performSearch()
                        }

                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(theme.textColor.opacity(0.3))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(theme.cardBackgroundColor)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(theme.accentColor.opacity(isSearching ? 0.5 : 0.1), lineWidth: 1)
                )

                if !searchText.isEmpty {
                    Button(action: performSearch) {
                        ZStack {
                            if isSearching {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Search")
                                    .font(theme.bodyFont.weight(.semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(theme.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .padding(.horizontal)
            .animation(.spring(response: 0.3), value: searchText.isEmpty)

            // Topic Chips
            VStack(alignment: .leading, spacing: 12) {
                Text("Browse by topic")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.textColor.opacity(0.6))
                    .padding(.horizontal, 20)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(["Childhood", "Traditions", "Advice", "Holidays", "Love", "Travel", "Lessons"], id: \.self) { topic in
                            Button(action: {
                                searchText = topic
                                performSearch()
                            }) {
                                Text(topic)
                                    .font(.system(size: 14, weight: .medium))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(theme.accentColor.opacity(0.08))
                                    .foregroundColor(theme.accentColor)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(theme.accentColor.opacity(0.15), lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 4) // Prevents shadow/bottom cropping
                }
            }
        }
        .padding(.vertical, 20)
    }

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(theme.accentColor.opacity(0.05))
                    .frame(width: 120, height: 120)

                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundColor(theme.accentColor.opacity(0.6))
                    .offset(x: 30, y: -30)

                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 60))
                    .foregroundColor(theme.accentColor.opacity(0.8))
            }

            VStack(spacing: 8) {
                Text("Your Family's Memory Space")
                    .font(theme.headlineFont)
                    .foregroundColor(theme.textColor)

                Text("Search for specific memories or ask questions to discover wisdom from your family's past.")
                    .font(theme.bodyFont)
                    .foregroundColor(theme.textColor.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            VStack(spacing: 12) {
                Text("Try asking about:")
                    .font(.caption)
                    .foregroundColor(theme.textColor.opacity(0.5))

                VStack(spacing: 8) {
                    suggestionRow(icon: "house.fill", text: "Grandpa's first house")
                    suggestionRow(icon: "gift.fill", text: "Holiday traditions we love")
                    suggestionRow(icon: "figure.walk", text: "Advice for starting a new job")
                }
            }

            Spacer()
        }
        .padding()
    }

    private func suggestionRow(icon: String, text: String) -> some View {
        Button(action: {
            searchText = text
            performSearch()
        }) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(theme.accentColor)
                    .frame(width: 24)
                Text(text)
                    .font(theme.bodyFont)
                    .foregroundColor(theme.textColor)
                Spacer()
                Image(systemName: "arrow.up.left")
                    .font(.caption2)
                    .foregroundColor(theme.textColor.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(theme.cardBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(theme.textColor.opacity(0.05), lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
    }

    private var noResultsView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 80))
                .foregroundColor(theme.textColor.opacity(0.1))

            VStack(spacing: 12) {
                Text("A new story waiting to be told")
                    .font(theme.headlineFont)
                    .foregroundColor(theme.textColor)

                Text("We couldn't find any memories about \"\(searchText)\" yet, but that just means it's time to capture one!")
                    .font(theme.bodyFont)
                    .foregroundColor(theme.textColor.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 16) {
                Button(action: { onRequestStory?() }) {
                    HStack {
                        Image(systemName: "paperplane.fill")
                        Text("Request this Story")
                    }
                    .font(theme.headlineFont)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(theme.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: theme.accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
                }

                Text("We'll notify your family and invite them to share their memories about this topic.")
                    .font(.caption)
                    .foregroundColor(theme.textColor.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.horizontal, 20)

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
                    Image(systemName: result.type == "quote" ? "quote.bubble.fill" : "book.closed.fill")
                        .font(.caption2)
                    Text(result.type == "quote" ? "Family Wisdom" : "Family Story")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .textCase(.uppercase)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(result.type == "quote" ? theme.accentColor.opacity(0.15) : Color.forestGreen.opacity(0.15))
                .foregroundColor(result.type == "quote" ? theme.accentColor : Color.forestGreen)
                .clipShape(Capsule())

                Spacer()

                // Similarity score - warmer language
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                    Text(resonanceText(for: result.similarity))
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundColor(theme.textColor.opacity(0.5))
            }

            // Quote-specific display
            if result.type == "quote" {
                VStack(alignment: .leading, spacing: 10) {
                    Text("\"\(result.content)\"")
                        .font(theme.bodyFont.italic())
                        .foregroundColor(theme.textColor)
                        .lineSpacing(4)

                    if let author = result.author {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(theme.accentColor.opacity(0.2))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Text(String(author.prefix(1)))
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(theme.accentColor)
                                )

                            VStack(alignment: .leading, spacing: 0) {
                                Text(author)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(theme.textColor)

                                if let role = result.role {
                                    Text(role.capitalized)
                                        .font(.system(size: 10))
                                        .foregroundColor(theme.textColor.opacity(0.6))
                                }
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
                        .lineSpacing(3)
                }
            }

            Divider()
                .background(theme.textColor.opacity(0.05))

            // Action hint
            HStack {
                Label(result.type == "quote" ? "Share wisdom" : "Listen to story",
                      systemImage: result.type == "quote" ? "square.and.arrow.up" : "play.fill")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.accentColor)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(theme.textColor.opacity(0.3))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
        )
    }

    private func resonanceText(for similarity: Double) -> String {
        if similarity > 0.85 { return "Strong resonance" }
        if similarity > 0.7 { return "Found a connection" }
        return "Possible memory"
    }
}
