import SwiftUI

struct HookSearchScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var searchQuery = ""
    @State private var showResults = false
    @State private var typingIndex = 0
    
    private let fullQuery = "How did grandpa propose?"
    private let mockResults = [
        SearchResult(title: "The Proposal Story", narrator: "Grandma Ruth", duration: "4:32", match: "He got down on one knee at the beach..."),
        SearchResult(title: "How We Met", narrator: "Grandpa Joe", duration: "6:15", match: "I knew from that moment I'd marry her...")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("What wisdom do you need")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(theme.textColor)
                    
                    Text("right now?")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(theme.accentColor)
                }
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1 : 0)
                
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(theme.secondaryTextColor)
                        
                        Text(searchQuery.isEmpty ? "Search family wisdom..." : searchQuery)
                            .foregroundColor(searchQuery.isEmpty ? theme.secondaryTextColor : theme.textColor)
                        
                        Spacer()
                        
                        if !searchQuery.isEmpty {
                            Image(systemName: "sparkles")
                                .foregroundColor(.yellow)
                        }
                    }
                    .font(theme.bodyFont)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.cardBackgroundColor)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                    )
                    
                    if showResults {
                        VStack(spacing: 12) {
                            ForEach(mockResults) { result in
                                SearchResultRow(result: result)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                    }
                }
                .frame(maxWidth: 340)
                .opacity(showContent ? 1 : 0)
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(theme.accentColor)
                    Text("AI-powered family wisdom search")
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryTextColor)
                }
                
                Text("Find the right story for any moment")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.cardBackgroundColor)
            )
            .opacity(showContent ? 1 : 0)
            
            Spacer()
            
            OnboardingCTAButton(
                title: "Continue",
                action: { coordinator.goToNextStep() }
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
            startTypingAnimation()
        }
    }
    
    private func startTypingAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { timer in
            if typingIndex < fullQuery.count {
                let index = fullQuery.index(fullQuery.startIndex, offsetBy: typingIndex)
                searchQuery = String(fullQuery[...index])
                typingIndex += 1
            } else {
                timer.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showResults = true
                    }
                }
            }
        }
    }
}

struct SearchResult: Identifiable {
    let id = UUID()
    let title: String
    let narrator: String
    let duration: String
    let match: String
}

struct SearchResultRow: View {
    let result: SearchResult
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(theme.accentColor.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "play.fill")
                    .font(.system(size: 14))
                    .foregroundColor(theme.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(result.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(theme.textColor)
                
                Text("\(result.narrator) • \(result.duration)")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
                
                Text("\"\(result.match)\"")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
                    .italic()
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.cardBackgroundColor)
        )
    }
}

#Preview {
    HookSearchScreenView(coordinator: OnboardingCoordinator.preview)
        .themed(LightTheme())
}
