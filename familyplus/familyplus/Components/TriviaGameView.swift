//
//  TriviaGameView.swift
//  StoryRide
//
//  Family trivia game component - learn while having fun
//

import SwiftUI

// MARK: - Trivia Game Models

struct TriviaQuestion: Identifiable, Codable {
    let id: UUID
    let question: String
    let options: [TriviaOption]
    let correctOptionId: UUID
    let explanation: String
    let category: TriviaCategory
    let difficulty: TriviaDifficulty
    let relatedStoryId: UUID?
    let points: Int
    
    struct TriviaOption: Identifiable, Codable {
        let id: UUID
        let text: String
        let generation: String?
    }
    
    enum TriviaCategory: String, Codable, CaseIterable {
        case familyHistory = "Family History"
        case traditions = "Traditions"
        case milestones = "Milestones"
        case wisdom = "Wisdom"
        case fun = "Fun"
        
        var icon: String {
            switch self {
            case .familyHistory: return "clock.arrow.circlepath"
            case .traditions: return "leaf"
            case .milestones: return "star"
            case .wisdom: return "brain"
            case .fun: return "gamecontroller"
            }
        }
        
        var color: Color {
            switch self {
            case .familyHistory: return .blue
            case .traditions: return .green
            case .milestones: return .purple
            case .wisdom: return .orange
            case .fun: return .pink
            }
        }
    }
    
    enum TriviaDifficulty: String, Codable {
        case easy, medium, hard
        
        var points: Int {
            switch self {
            case .easy: return 10
            case .medium: return 20
            case .hard: return 30
            }
        }
        
        var color: Color {
            switch self {
            case .easy: return .green
            case .medium: return .orange
            case .hard: return .red
            }
        }
    }
}

struct TriviaGameSession: Identifiable, Codable {
    let id: UUID
    let questions: [TriviaQuestion]
    var currentQuestionIndex: Int
    var score: Int
    var streak: Int
    var answers: [UUID: UUID] // questionId -> selectedOptionId
    var startedAt: Date
    var completedAt: Date?
    
    var isComplete: Bool {
        currentQuestionIndex >= questions.count
    }
    
    var correctAnswers: Int {
        answers.filter { questionId, selectedOptionId in
            questions.first { $0.id == questionId }?.correctOptionId == selectedOptionId
        }.count
    }
}

// LEADERBOARD ENTRY REMOVED: No longer needed after leaderboard removal

// MARK: - Trivia Game View

struct TriviaGameView: View {
    @State private var gameSession: TriviaGameSession?
    @State private var selectedCategory: TriviaQuestion.TriviaCategory?
    @State private var showResults = false
    @State private var selectedOptionId: UUID?
    @State private var showExplanation = false
    @State private var isLoading = false
    
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(spacing: 0) {
            if let session = gameSession {
                if session.isComplete || showResults {
                    TriviaResultsView(
                        session: session,
                        onPlayAgain: {
                            gameSession = nil
                            selectedCategory = nil
                            showResults = false
                        }
                    )
                } else {
                    TriviaQuestionView(
                        question: session.questions[session.currentQuestionIndex],
                        questionNumber: session.currentQuestionIndex + 1,
                        totalQuestions: session.questions.count,
                        score: session.score,
                        streak: session.streak,
                        selectedOptionId: $selectedOptionId,
                        showExplanation: $showExplanation,
                        onAnswer: { optionId in
                            selectedOptionId = optionId
                            showExplanation = true
                            
                            let isCorrect = optionId == session.questions[session.currentQuestionIndex].correctOptionId
                            let points = isCorrect ? session.questions[session.currentQuestionIndex].points : 0
                            let newStreak = isCorrect ? session.streak + 1 : 0
                            
                            gameSession?.answers[session.questions[session.currentQuestionIndex].id] = optionId
                            gameSession?.score += points
                            gameSession?.streak = newStreak
                        },
                        onNext: {
                            selectedOptionId = nil
                            showExplanation = false
                            gameSession?.currentQuestionIndex += 1
                            
                            if gameSession!.isComplete {
                                showResults = true
                            }
                        }
                    )
                }
            } else {
                TriviaCategorySelectionView(
                    selectedCategory: $selectedCategory,
                    isLoading: isLoading,
                    onStartGame: {
                        startGame()
                    }
                )
            }
        }
    }

    private func startGame() {
        guard let category = selectedCategory else { return }
        isLoading = true
        
        Task {
            // Simulate loading - would call API in production
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            let questions = generateMockQuestions(for: category)
            let session = TriviaGameSession(
                id: UUID(),
                questions: questions,
                currentQuestionIndex: 0,
                score: 0,
                streak: 0,
                answers: [:],
                startedAt: Date(),
                completedAt: nil
            )
            
            await MainActor.run {
                gameSession = session
                isLoading = false
            }
        }
    }
    
private func generateMockQuestions(for category: TriviaQuestion.TriviaCategory) -> [TriviaQuestion] {
        var questions: [TriviaQuestion] = []
        
        switch category {
        case .familyHistory:
            questions = [
                TriviaQuestion(id: UUID(), question: "What was the name of the family dog from the 1980s?", options: [
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Buddy", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Max", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Rex", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Spot", generation: nil)
                ], correctOptionId: UUID(), explanation: "Buddy was the golden retriever who lived for 15 years!", category: category, difficulty: .easy, relatedStoryId: nil, points: 10),
                TriviaQuestion(id: UUID(), question: "Which city did the family first live in?", options: [
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Chicago", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "New York", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Los Angeles", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Miami", generation: nil)
                ], correctOptionId: UUID(), explanation: "The family settled in Chicago in 1972.", category: category, difficulty: .medium, relatedStoryId: nil, points: 20),
                TriviaQuestion(id: UUID(), question: "What was Grandma's famous holiday tradition?", options: [
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Making tamales", generation: "Grandparents"),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Christmas caroling", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Decorating tree", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Gift wrapping", generation: nil)
                ], correctOptionId: UUID(), explanation: "Making tamales is a 3-day tradition!", category: category, difficulty: .easy, relatedStoryId: nil, points: 10),
                TriviaQuestion(id: UUID(), question: "How many siblings does Dad have?", options: [
                    TriviaQuestion.TriviaOption(id: UUID(), text: "3", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "2", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "4", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "1", generation: nil)
                ], correctOptionId: UUID(), explanation: "Dad has 2 sisters and 1 brother.", category: category, difficulty: .easy, relatedStoryId: nil, points: 10),
                TriviaQuestion(id: UUID(), question: "What year did the family buy their first computer?", options: [
                    TriviaQuestion.TriviaOption(id: UUID(), text: "1995", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "1990", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "2000", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "1988", generation: nil)
                ], correctOptionId: UUID(), explanation: "It was a Windows 95 PC everyone was fascinated with!", category: category, difficulty: .medium, relatedStoryId: nil, points: 20),
            ]
            
        case .traditions:
            questions = [
                TriviaQuestion(id: UUID(), question: "What special dish for Christmas Eve?", options: [
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Tamales", generation: "Grandparents"),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Turkey", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Ham", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Pizza", generation: nil)
                ], correctOptionId: UUID(), explanation: "Making tamales involves the whole family!", category: category, difficulty: .easy, relatedStoryId: nil, points: 10),
                TriviaQuestion(id: UUID(), question: "Family summer vacation spot?", options: [
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Lake Tahoe", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Disney World", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Grandma's Cabin", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Beach House", generation: nil)
                ], correctOptionId: UUID(), explanation: "Lake Tahoe for over 20 years!", category: category, difficulty: .medium, relatedStoryId: nil, points: 20),
                TriviaQuestion(id: UUID(), question: "What game on Thanksgiving?", options: [
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Football", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Basketball", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Card games", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Board games", generation: nil)
                ], correctOptionId: UUID(), explanation: "Annual Turkey Bowl since 1985!", category: category, difficulty: .easy, relatedStoryId: nil, points: 10),
                TriviaQuestion(id: UUID(), question: "Secret ingredient in Grandma's apple pie?", options: [
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Cinnamon", generation: "Grandparents"),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "More sugar", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Vanilla", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Lemon zest", generation: nil)
                ], correctOptionId: UUID(), explanation: "A pinch of cinnamon makes all the difference!", category: category, difficulty: .medium, relatedStoryId: nil, points: 20),
                TriviaQuestion(id: UUID(), question: "Birthday tradition?", options: [
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Sing 3 times", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Presents last", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Cake breakfast", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Wearing hats", generation: nil)
                ], correctOptionId: UUID(), explanation: "Happy Birthday in 3 languages!", category: category, difficulty: .easy, relatedStoryId: nil, points: 10),
            ]
            
        case .milestones:
            questions = [
                TriviaQuestion(id: UUID(), question: "First to graduate college?", options: [
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Aunt Maria", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Dad", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Uncle John", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Mom", generation: nil)
                ], correctOptionId: UUID(), explanation: "Aunt Maria in 1990!", category: category, difficulty: .medium, relatedStoryId: nil, points: 20),
                TriviaQuestion(id: UUID(), question: "First family car?", options: [
                    TriviaQuestion.TriviaOption(id: UUID(), text: "1978 Chevrolet Nova", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Ford Taurus", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Honda Civic", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Toyota Camry", generation: nil)
                ], correctOptionId: UUID(), explanation: "Blue Nova with 200,000 miles!", category: category, difficulty: .hard, relatedStoryId: nil, points: 30),
                TriviaQuestion(id: UUID(), question: "Anniversary celebrated?", options: [
                    TriviaQuestion.TriviaOption(id: UUID(), text: "50 years", generation: "Grandparents"),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "45 years", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "55 years", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "40 years", generation: nil)
                ], correctOptionId: UUID(), explanation: "Golden anniversary in 2018!", category: category, difficulty: .medium, relatedStoryId: nil, points: 20),
                TriviaQuestion(id: UUID(), question: "First pet?", options: [
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Hamster Whiskers", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Cat Mittens", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Dog Rex", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Fish Goldie", generation: nil)
                ], correctOptionId: UUID(), explanation: "Whiskers the hamster was first!", category: category, difficulty: .easy, relatedStoryId: nil, points: 10),
                TriviaQuestion(id: UUID(), question: "Where was the wedding?", options: [
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Backyard garden", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Fancy hotel", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "The beach", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "A church", generation: nil)
                ], correctOptionId: UUID(), explanation: "Beautiful garden wedding!", category: category, difficulty: .hard, relatedStoryId: nil, points: 30),
            ]
            
        case .wisdom:
            questions = [
                TriviaQuestion(id: UUID(), question: "Grandpa's famous quote?", options: [
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Early bird catches worm", generation: "Grandpa"),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Work hard play hard", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Better late never", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Fortune favors bold", generation: nil)
                ], correctOptionId: UUID(), explanation: "He credits this to his father.", category: category, difficulty: .easy, relatedStoryId: nil, points: 10),
                TriviaQuestion(id: UUID(), question: "Most important family value?", options: [
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Family comes first", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Success at all costs", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Money isn't everything", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Be the best", generation: nil)
                ], correctOptionId: UUID(), explanation: "Guides every family decision.", category: category, difficulty: .medium, relatedStoryId: nil, points: 20),
                TriviaQuestion(id: UUID(), question: "Grandma's life lesson?", options: [
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Never give up dreams", generation: "Grandma"),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Take risks daily", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Save everything", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Don't trust anyone", generation: nil)
                ], correctOptionId: UUID(), explanation: "Helped Mom through tough times.", category: category, difficulty: .easy, relatedStoryId: nil, points: 10),
                TriviaQuestion(id: UUID(), question: "Family motto on the wall?", options: [
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Together We Thrive", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Success Through Unity", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Family Forever", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Love Conquers All", generation: nil)
                ], correctOptionId: UUID(), explanation: "Painted at 2005 reunion!", category: category, difficulty: .medium, relatedStoryId: nil, points: 20),
                TriviaQuestion(id: UUID(), question: "Oldest generation on money?", options: [
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Save for rainy day", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Spend while have it", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Money doesn't matter", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Borrow from others", generation: nil)
                ], correctOptionId: UUID(), explanation: "Helped through tough times.", category: category, difficulty: .hard, relatedStoryId: nil, points: 30),
            ]
            
        case .fun:
            questions = [
                TriviaQuestion(id: UUID(), question: "Funny nickname & who?", options: [
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Sparky - Uncle Bob", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Speedy - Dad", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Sneaky - Mom", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Sleepy - The dog", generation: nil)
                ], correctOptionId: UUID(), explanation: "From fireworks incident 1998!", category: category, difficulty: .easy, relatedStoryId: nil, points: 10),
                TriviaQuestion(id: UUID(), question: "Family karaoke song?", options: [
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Sweet Caroline", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Bohemian Rhapsody", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Don't Stop Believin'", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Living on a Prayer", generation: nil)
                ], correctOptionId: UUID(), explanation: "Every gathering ends with this!", category: category, difficulty: .medium, relatedStoryId: nil, points: 20),
                TriviaQuestion(id: UUID(), question: "Embarrassing thing Dad did?", options: [
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Fell in pool", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Spilled wine", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Locked in bathroom", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Sang off-key", generation: nil)
                ], correctOptionId: UUID(), explanation: "Caught on video!", category: category, difficulty: .easy, relatedStoryId: nil, points: 10),
                TriviaQuestion(id: UUID(), question: "Secret family talent?", options: [
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Grandma's opera", generation: "Grandma"),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Dad's magic", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Mom's dancing", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "Kids comedy", generation: nil)
                ], correctOptionId: UUID(), explanation: "Amazing voice revealed!", category: category, difficulty: .hard, relatedStoryId: nil, points: 30),
                TriviaQuestion(id: UUID(), question: "What's the family joke?", options: [
                    TriviaQuestion.TriviaOption(id: UUID(), text: "The leftover pizza story", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "The camping disaster", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "The mistaken identity", generation: nil),
                    TriviaQuestion.TriviaOption(id: UUID(), text: "The lost keys saga", generation: nil)
                ], correctOptionId: UUID(), explanation: "This joke has been told for years!", category: category, difficulty: .easy, relatedStoryId: nil, points: 10),
            ]
        }
        
        return questions.shuffled().prefix(5).map { q in
            TriviaQuestion(id: q.id, question: q.question, options: q.options, correctOptionId: q.correctOptionId, explanation: q.explanation, category: q.category, difficulty: q.difficulty, relatedStoryId: q.relatedStoryId, points: q.points)
        }
    }
}

// MARK: - Trivia Category Selection View

struct TriviaCategorySelectionView: View {
    @Binding var selectedCategory: TriviaQuestion.TriviaCategory?
    let isLoading: Bool
    let onStartGame: () -> Void
    
    @Environment(\.theme) var theme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 48))
                        .foregroundColor(theme.accentColor)
                    
                    Text("Family Trivia")
                        .font(theme.headlineFont)
                        .foregroundColor(theme.textColor)
                    
                    Text("Test your knowledge about family stories!")
                        .font(theme.bodyFont)
                        .foregroundColor(theme.secondaryTextColor)
                }
                .padding(.top, 24)
                
                // Category Selection
                VStack(spacing: 12) {
                    Text("Choose a Category")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.secondaryTextColor)
                    
                    ForEach(TriviaQuestion.TriviaCategory.allCases, id: \.self) { category in
                        CategoryButton(
                            category: category,
                            isSelected: selectedCategory == category,
                            onSelect: {
                                withAnimation(.spring(response: 0.2)) {
                                    selectedCategory = category
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
                
                // Start Button
                Button(action: onStartGame) {
                    Group {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Start Game")
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(selectedCategory == nil ? theme.accentColor.opacity(0.5) : theme.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(selectedCategory == nil || isLoading)
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
        }
    }
}

// MARK: - Category Button

struct CategoryButton: View {
    let category: TriviaQuestion.TriviaCategory
    let isSelected: Bool
    let onSelect: () -> Void
    
    @Environment(\.theme) var theme
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundColor(category.color)
                    .frame(width: 32, height: 32)
                    .background(category.color.opacity(0.15))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.textColor)
                    
                    Text("5 questions")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? theme.accentColor : theme.secondaryTextColor)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? theme.accentColor.opacity(0.1) : theme.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? theme.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Trivia Question View

struct TriviaQuestionView: View {
    let question: TriviaQuestion
    let questionNumber: Int
    let totalQuestions: Int
    let score: Int
    let streak: Int
    @Binding var selectedOptionId: UUID?
    @Binding var showExplanation: Bool
    let onAnswer: (UUID) -> Void
    let onNext: () -> Void
    
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with progress
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Question \(questionNumber) of \(totalQuestions)")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                    
                    ProgressView(value: Double(questionNumber), total: Double(totalQuestions))
                        .tint(theme.accentColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Text("\(score)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(theme.accentColor)
                        
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                    
                    if streak >= 3 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text("\(streak) streak!")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            // Category & Difficulty
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: question.category.icon)
                        .font(.caption)
                        .foregroundColor(question.category.color)
                    Text(question.category.rawValue)
                        .font(.caption)
                        .foregroundColor(question.category.color)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(question.category.color.opacity(0.15))
                .clipShape(Capsule())
                
                Spacer()
                
                Text(question.difficulty.rawValue.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(question.difficulty.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(question.difficulty.color.opacity(0.15))
                    .clipShape(Capsule())
            }
            .padding(.horizontal)
            
            // Question
            Text(question.question)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(theme.textColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            // Options
            VStack(spacing: 12) {
                ForEach(question.options) { option in
                    TriviaOptionButton(
                        option: option,
                        isSelected: selectedOptionId == option.id,
                        isCorrect: question.correctOptionId == option.id,
                        showResult: showExplanation,
                        onSelect: {
                            if !showExplanation {
                                onAnswer(option.id)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Explanation & Next Button
            if showExplanation {
                VStack(spacing: 12) {
                    Text(question.explanation)
                        .font(.subheadline)
                        .foregroundColor(theme.textColor)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(theme.cardBackgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Button(action: onNext) {
                        Text(questionNumber < totalQuestions ? "Next Question" : "See Results")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(theme.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.top, 16)
        .animation(.spring(response: 0.3), value: showExplanation)
    }
}

// MARK: - Trivia Option Button

struct TriviaOptionButton: View {
    let option: TriviaQuestion.TriviaOption
    let isSelected: Bool
    let isCorrect: Bool
    let showResult: Bool
    let onSelect: () -> Void
    
    @Environment(\.theme) var theme
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Option Letter Badge
                let letter = ["A", "B", "C", "D"][Int.random(in: 0...3)] // Would use actual index in production
                Text(letter)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(backgroundColor)
                    .clipShape(Circle())
                
                Text(option.text)
                    .font(.subheadline)
                    .foregroundColor(theme.textColor)
                    .multilineTextAlignment(.leading)
                
                if let generation = option.generation {
                    Spacer()
                    Text(generation)
                        .font(.caption2)
                        .foregroundColor(theme.secondaryTextColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                }
                
                // Result Icon
                if showResult {
                    if isCorrect {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else if isSelected {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(showResult)
    }
    
    private var backgroundColor: Color {
        if showResult {
            if isCorrect {
                return .green
            } else if isSelected {
                return .red
            }
        }
        return theme.accentColor
    }
    
    private var cardBackgroundColor: Color {
        if showResult {
            if isCorrect {
                return .green.opacity(0.1)
            } else if isSelected {
                return .red.opacity(0.1)
            }
        }
        return theme.cardBackgroundColor
    }
    
    private var borderColor: Color {
        if showResult {
            if isCorrect {
                return .green
            } else if isSelected {
                return .red
            }
        }
        return isSelected ? theme.accentColor : .clear
    }
}

// MARK: - Trivia Results View

struct TriviaResultsView: View {
    let session: TriviaGameSession
    let onPlayAgain: () -> Void
    
    @Environment(\.theme) var theme
    @State private var showConfetti = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Score Circle
            ZStack {
                Circle()
                    .stroke(theme.accentColor.opacity(0.2), lineWidth: 8)
                    .frame(width: 160, height: 160)
                
                Circle()
                    .trim(from: 0, to: CGFloat(session.correctAnswers) / CGFloat(session.questions.count))
                    .stroke(theme.accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text("\(session.score)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(theme.textColor)
                    
                    Text("points")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
            }
            .padding(.vertical, 24)
            
            // Stats
            HStack(spacing: 32) {
                TriviaStatItem(value: "\(session.correctAnswers)/\(session.questions.count)", label: "Correct", icon: "checkmark.circle.fill", color: .green)
                TriviaStatItem(value: "\(session.streak)", label: "Best Streak", icon: "flame.fill", color: .orange)
                TriviaStatItem(value: "\(session.score)", label: "Points", icon: "star.fill", color: .yellow)
            }
            .padding()
            
            // Message
            Text(resultMessage)
                .font(theme.headlineFont)
                .foregroundColor(theme.textColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 12) {
                Button(action: onPlayAgain) {
                    Text("Play Again")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(theme.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .onAppear {
            showConfetti = true
        }
    }
    
    private var resultMessage: String {
        let percentage = Double(session.correctAnswers) / Double(session.questions.count)
        if percentage >= 0.8 {
            return "🎉 Amazing! You really know your family!"
        } else if percentage >= 0.6 {
            return "👏 Great job! Keep learning about family stories!"
        } else if percentage >= 0.4 {
            return "💪 Good effort! There's more to discover!"
        } else {
            return "📚 Time to listen to more family stories!"
        }
    }
}

// MARK: - Trivia Stat Item

struct TriviaStatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(theme.textColor)
            
            Text(label)
                .font(.caption)
                .foregroundColor(theme.secondaryTextColor)
        }
    }
}

// LEADERBOARD REMOVED: Leaderboards promoted toxic competition in family dynamics.
// The app should focus on value extraction (learning family stories) not social comparison.

// MARK: - Preview

#Preview {
    TriviaGameView()
}
