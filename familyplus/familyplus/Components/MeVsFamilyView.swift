//
//  MeVsFamilyView.swift
//  StoryRide
//
//  Compare user responses with family wisdom - viral content generator
//

import SwiftUI

// MARK: - Me vs Family Models

struct MeVsFamilyComparison: Identifiable, Codable {
    let id: UUID
    let topic: String
    let question: String
    let userResponse: UserResponse
    let familyResponses: [FamilyResponse]
    let aiInsight: String
    let createdAt: Date
    
    struct UserResponse: Identifiable, Codable {
        let id: UUID
        let text: String
        let source: String // "app_audio", "app_text", "phone_ai"
        let timestamp: Date
    }
    
    struct FamilyResponse: Identifiable, Codable {
        let id: UUID
        let text: String
        let storyteller: String
        let generation: String
        let year: Int?
        let timestamp: Date
    }
}

struct MeVsFamilyTopic: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let icon: String
    let category: String
    let questionPrompt: String
    let familyQuestion: String
    let isAvailable: Bool
}

struct MeVsFamilyCreateRequest: Codable {
    let topicId: String
    let userResponse: String
    let source: String
}

enum InputMethod: String, CaseIterable {
    case text = "Text"
    case voice = "Voice"
}

// MARK: - Me vs Family View

struct MeVsFamilyView: View {
    @State private var availableTopics: [MeVsFamilyTopic] = []
    @State private var selectedTopic: MeVsFamilyTopic?
    @State private var showComparison = false
    @State private var comparisonResult: MeVsFamilyComparison?
    @State private var isLoading = false
    @State private var userResponse = ""
    @State private var inputMethod: InputMethod = .text
    
    @Environment(\.theme) var theme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if showComparison, let comparison = comparisonResult {
                    ComparisonResultView(comparison: comparison, onTryAnother: {
                        showComparison = false
                        comparisonResult = nil
                        selectedTopic = nil
                        userResponse = ""
                    })
                } else if selectedTopic != nil {
                    // Show input view
                    MeVsFamilyInputView(
                        topic: selectedTopic!,
                        response: $userResponse,
                        inputMethod: $inputMethod,
                        isLoading: isLoading,
                        onSubmit: submitResponse,
                        onBack: {
                            selectedTopic = nil
                        }
                    )
                } else {
                    // Show topic selection
                    TopicSelectionView(
                        topics: availableTopics,
                        onSelect: { topic in
                            selectedTopic = topic
                        }
                    )
                }
            }
            .padding(.vertical, 16)
        }
        .task {
            await loadTopics()
        }
    }
    
    private func loadTopics() async {
        // Load available topics
        availableTopics = generateMockTopics()
    }
    
    private func generateMockTopics() -> [MeVsFamilyTopic] {
        [
            MeVsFamilyTopic(
                id: UUID(),
                title: "First Job",
                description: "How did you get your first job vs how family members got theirs?",
                icon: "briefcase.fill",
                category: "Career",
                questionPrompt: "Tell us about your first job experience",
                familyQuestion: "How did you get your first job?",
                isAvailable: true
            ),
            MeVsFamilyTopic(
                id: UUID(),
                title: "Money Management",
                description: "Compare money lessons learned across generations",
                icon: "dollarsign.circle.fill",
                category: "Finance",
                questionPrompt: "How do you handle saving money?",
                familyQuestion: "What's the most important money lesson you learned?",
                isAvailable: true
            ),
            MeVsFamilyTopic(
                id: UUID(),
                title: "Relationship Advice",
                description: "What relationship advice would you give vs what family gave",
                icon: "heart.fill",
                category: "Relationships",
                questionPrompt: "What's your best relationship advice?",
                familyQuestion: "What relationship advice would you give to younger generations?",
                isAvailable: true
            ),
            MeVsFamilyTopic(
                id: UUID(),
                title: "Education",
                description: "Compare educational experiences and choices",
                icon: "graduationcap.fill",
                category: "Education",
                questionPrompt: "What's your educational background?",
                familyQuestion: "Tell us about your education journey",
                isAvailable: true
            ),
            MeVsFamilyTopic(
                id: UUID(),
                title: "Career Changes",
                description: "How did you navigate career changes?",
                icon: "arrow.triangle.2.circlepath",
                category: "Career",
                questionPrompt: "Have you changed careers? Tell us about it",
                familyQuestion: "Tell us about a time you changed careers or jobs",
                isAvailable: true
            ),
            MeVsFamilyTopic(
                id: UUID(),
                title: "Life Challenges",
                description: "Compare how different generations handled tough times",
                icon: "mountain.2",
                category: "Life",
                questionPrompt: "What's a challenge you overcame?",
                familyQuestion: "Tell us about a difficult time in your life",
                isAvailable: true
            )
        ]
    }
    
    private func submitResponse() {
        guard !userResponse.isEmpty else { return }
        isLoading = true
        
        Task {
            // Simulate API call
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            
            let comparison = MeVsFamilyComparison(
                id: UUID(),
                topic: selectedTopic!.title,
                question: selectedTopic!.questionPrompt,
                userResponse: MeVsFamilyComparison.UserResponse(
                    id: UUID(),
                    text: userResponse,
                    source: inputMethod == .text ? "app_text" : "app_audio",
                    timestamp: Date()
                ),
                familyResponses: generateMockFamilyResponses(for: selectedTopic!.title),
                aiInsight: generateMockInsight(for: selectedTopic!.title, userResponse: userResponse),
                createdAt: Date()
            )
            
            await MainActor.run {
                comparisonResult = comparison
                showComparison = true
                isLoading = false
            }
        }
    }
    
    private func generateMockFamilyResponses(for topic: String) -> [MeVsFamilyComparison.FamilyResponse] {
        [
            MeVsFamilyComparison.FamilyResponse(
                id: UUID(),
                text: "I got my first job at the local grocery store at 16. Saved every penny for college.",
                storyteller: "Grandma Rose",
                generation: "Grandparents",
                year: 1968,
                timestamp: Date()
            ),
            MeVsFamilyComparison.FamilyResponse(
                id: UUID(),
                text: "After college, I started as an intern and worked my way up. It took 3 years to get promoted.",
                storyteller: "Dad",
                generation: "Parents",
                year: 1995,
                timestamp: Date()
            )
        ]
    }
    
    private func generateMockInsight(for topic: String, userResponse: String) -> String {
        "Interesting! Your approach to \(topic.lowercased()) is \(userResponse.count > 50 ? "detailed and thoughtful" : "concise and direct"). Family members who shared their stories took a more traditional path, focusing on \(topic == "First Job" ? "saving for the future" : "building skills over time")."
    }
}

// MARK: - Topic Selection View

struct TopicSelectionView: View {
    let topics: [MeVsFamilyTopic]
    let onSelect: (MeVsFamilyTopic) -> Void
    
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "person.and.person.fill")
                    .font(.system(size: 48))
                    .foregroundColor(theme.accentColor)
                
                Text("Me vs Family")
                    .font(theme.headlineFont)
                    .foregroundColor(theme.textColor)
                
                Text("Compare your experiences with family wisdom")
                    .font(theme.bodyFont)
                    .foregroundColor(theme.secondaryTextColor)
            }
            .padding(.top, 8)
            
            // Topics Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(topics) { topic in
                    TopicCard(topic: topic) {
                        onSelect(topic)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Topic Card

struct TopicCard: View {
    let topic: MeVsFamilyTopic
    let onSelect: () -> Void
    
    @Environment(\.theme) var theme
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: topic.icon)
                    .font(.title2)
                    .foregroundColor(theme.accentColor)
                    .frame(width: 44, height: 44)
                    .background(theme.accentColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                Text(topic.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.textColor)
                    .multilineTextAlignment(.leading)
                
                Text(topic.description)
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                Spacer()
                
                Text("Compare")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.accentColor)
            }
            .padding(16)
            .frame(height: 180)
            .background(theme.cardBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(theme.secondaryTextColor.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Me vs Family Input View

struct MeVsFamilyInputView: View {
    let topic: MeVsFamilyTopic
    @Binding var response: String
    @Binding var inputMethod: InputMethod
    let isLoading: Bool
    let onSubmit: () -> Void
    let onBack: () -> Void
    
    @Environment(\.theme) var theme
    
    var canSubmit: Bool {
        !response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with back button
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .foregroundColor(theme.accentColor)
                
                Spacer()
            }
            .padding(.horizontal)
            
            // Topic Info
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: topic.icon)
                        .font(.title2)
                        .foregroundColor(theme.accentColor)
                    
                    Text(topic.title)
                        .font(theme.headlineFont)
                        .foregroundColor(theme.textColor)
                }
                
                Text(topic.questionPrompt)
                    .font(theme.bodyFont)
                    .foregroundColor(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            
            // Input Method Picker
            VStack(spacing: 12) {
                Picker("Input Method", selection: $inputMethod) {
                    ForEach(InputMethod.allCases, id: \.self) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
                .pickerStyle(.segmented)
                
                if inputMethod == .voice {
                    VoiceInputView(response: $response)
                } else {
                    TextEditor(text: $response)
                        .frame(minHeight: 150)
                        .padding(12)
                        .background(theme.cardBackgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(theme.secondaryTextColor.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal)
                }
            }
            
            // Family Responses Preview
            VStack(alignment: .leading, spacing: 8) {
                Text("What family says:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textColor)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FamilyResponsePreview(
                            name: "Grandma Rose",
                            generation: "Grandparents",
                            preview: "I got my first job at the local grocery store..."
                        )
                        FamilyResponsePreview(
                            name: "Dad",
                            generation: "Parents",
                            preview: "After college, I started as an intern..."
                        )
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top, 8)
            
            Spacer()
            
            // Submit Button
            Button(action: onSubmit) {
                Group {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Compare with Family")
                            .fontWeight(.semibold)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canSubmit ? theme.accentColor : theme.accentColor.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!canSubmit || isLoading)
            .padding(.horizontal, 32)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Voice Input View

struct VoiceInputView: View {
    @Binding var response: String
    @State private var isRecording = false
    @State private var recordingDuration: TimeInterval = 0
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(isRecording ? Color.red.opacity(0.15) : Color.secondary.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(isRecording ? 1.1 : 1.0)
                
                Image(systemName: isRecording ? "waveform" : "mic.fill")
                    .font(.system(size: 48))
                    .foregroundColor(isRecording ? .red : .accentColor)
                    .symbolEffect(.pulse, isActive: isRecording)
            }
            
            Text(isRecording ? "Recording..." : "Tap to record")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if isRecording {
                Text(formatDuration(recordingDuration))
                    .font(.system(size: 24, weight: .medium, design: .monospaced))
                    .foregroundColor(.red)
                
                Button("Stop") {
                    isRecording = false
                    response = "This is a sample voice transcription response."
                }
                .foregroundColor(.red)
                .padding(.top, 8)
            } else {
                Button("Start Recording") {
                    isRecording = true
                    recordingDuration = 0
                }
                .foregroundColor(.accentColor)
                .padding(.top, 8)
            }
        }
        .padding()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Family Response Preview

struct FamilyResponsePreview: View {
    let name: String
    let generation: String
    let preview: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(generation)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            Text(preview)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(12)
        .frame(width: 160)
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Comparison Result View

struct ComparisonResultView: View {
    let comparison: MeVsFamilyComparison
    let onTryAnother: () -> Void
    
    @Environment(\.theme) var theme
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "person.and.person.fill")
                    .font(.system(size: 40))
                    .foregroundColor(theme.accentColor)
                
                Text("You vs Family")
                    .font(theme.headlineFont)
                    .foregroundColor(theme.textColor)
                
                Text(comparison.topic)
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryTextColor)
            }
            .padding(.top, 8)
            
            // Tab Selector
            Picker("View", selection: $selectedTab) {
                Text("Side by Side").tag(0)
                Text("AI Insight").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // Content based on tab
            if selectedTab == 0 {
                SideBySideComparisonView(comparison: comparison)
            } else {
                AIInsightView(insight: comparison.aiInsight)
            }
            
            Spacer()
            
            // Try Another Button
            Button(action: onTryAnother) {
                Text("Try Another Topic")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(theme.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Side by Side Comparison View

struct SideBySideComparisonView: View {
    let comparison: MeVsFamilyComparison
    
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(spacing: 16) {
            // You
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.blue)
                    Text("You")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Text(comparison.userResponse.text)
                    .font(.body)
                    .foregroundColor(theme.textColor)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            
            // Divider
            HStack {
                Text("vs")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.secondary)
                    .clipShape(Capsule())
            }
            
            // Family Responses
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.green)
                    Text("Family")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                ForEach(comparison.familyResponses) { familyResponse in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(familyResponse.storyteller)
                                .font(.caption)
                                .fontWeight(.medium)
                            Text("(\(familyResponse.generation))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(familyResponse.text)
                            .font(.body)
                            .foregroundColor(theme.textColor)
                            .padding(12)
                            .background(Color.green.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - AI Insight View

struct AIInsightView: View {
    let insight: String
    
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("AI Analysis")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            Text(insight)
                .font(.body)
                .foregroundColor(theme.textColor)
                .padding()
                .background(Color.purple.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            HStack(spacing: 16) {
                Label("94% similar", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
                
                Label("2 unique insights", systemImage: "lightbulb.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(theme.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview {
    MeVsFamilyView()
}
