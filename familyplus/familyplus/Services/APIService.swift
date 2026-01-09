//
//  APIService.swift
//  StoryRide
//
//  HTTP client for backend API calls
//

import Foundation
import SwiftUI

// MARK: - API Service

final class APIService {
    static let shared = APIService()
    
    /// Backend API base URL
    /// - For local dev: http://localhost:8787
    /// - For production: Set your deployed Cloudflare Worker URL
    /// - Can be overridden via App Configuration or Environment
    private let baseURL: String
    
    private let session: URLSession
    
    private init() {
        // Detect environment and set appropriate URL
        #if DEBUG
        // Local development
        self.baseURL = "http://localhost:8787"
        #else
        // Production - REPLACE with your deployed Worker URL
        // Get from: wrangler deploy output or Cloudflare Dashboard
        // Example: https://family-plus-backend.your-subdomain.workers.dev
        self.baseURL = ProcessInfo.processInfo.environment["API_BASE_URL"]
            ?? "https://family-plus-backend.your-subdomain.workers.dev"
        #endif
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Authentication Headers

    private func createRequest(endpoint: String, method: String = "GET") async -> URLRequest {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            fatalError("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add user ID from auth token for backend validation
        if let userId = UserDefaults.standard.string(forKey: "auth_user_id") {
            request.setValue(userId, forHTTPHeaderField: "X-User-ID")
        }

        return request
    }
    
    // MARK: - Stories API
    
    /// Get family stories
    func getStories() async throws -> [StoryData] {
        let request = await createRequest(endpoint: "/api/stories")
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode([StoryData].self, from: data)
    }
    
    /// Get story by ID
    func getStory(id: UUID) async throws -> StoryDetailData {
        let request = await createRequest(endpoint: "/api/stories/\(id.uuidString)")
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(StoryDetailData.self, from: data)
    }
    
    /// Create new story
    func createStory(promptId: UUID) async throws -> StoryData {
        let body = CreateStoryAPIRequest(prompt_id: promptId.uuidString)
        var request = await createRequest(endpoint: "/api/stories", method: "POST")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, _) = try await session.data(for: request)
        let result = try JSONDecoder().decode(StoryData.self, from: data)

        // Track value analytics: story captured via prompt/type method
        Task { @MainActor in
            ValueAnalyticsService.shared.trackStoryCapture(method: .type)
        }

        return result
    }
    
    // MARK: - Family API

    /// Get current family info with invite slug
    func getFamily() async throws -> FamilyInfo {
        let request = await createRequest(endpoint: "/api/families")
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(FamilyInfo.self, from: data)
    }

    /// Get family members
    func getFamilyMembers(familyId: String) async throws -> [FamilyMemberData] {
        let request = await createRequest(endpoint: "/api/families/\(familyId)/members")
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode([FamilyMemberData].self, from: data)
    }

    /// Create a new family
    func createFamily(name: String) async throws -> FamilyResponse {
        let body = CreateFamilyRequest(name: name)
        var request = await createRequest(endpoint: "/api/families", method: "POST")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(FamilyResponse.self, from: data)
    }
    
    /// Join an existing family with invite code
    func joinFamily(inviteCode: String) async throws -> FamilyResponse {
        let body = JoinFamilyRequest(invite_code: inviteCode)
        var request = await createRequest(endpoint: "/api/families/join", method: "POST")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(FamilyResponse.self, from: data)
    }
    
    /// Complete story with AI-generated content
    func completeStory(id: UUID, title: String, summary: String, coverImageUrl: String, voiceCount: Int) async throws -> StoryData {
        let body = CompleteStoryRequest(
            title: title,
            summary: summary,
            cover_image_url: coverImageUrl,
            voice_count: voiceCount
        )
        var request = await createRequest(endpoint: "/api/stories/\(id.uuidString)/complete", method: "PATCH")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, _) = try await session.data(for: request)
        let result = try JSONDecoder().decode(StoryData.self, from: data)

        // Track value analytics: story completed
        Task { @MainActor in
            ValueAnalyticsService.shared.trackStoryComplete(storyId: id.uuidString, panelCount: voiceCount)
        }

        return result
    }

    /// Generate AI cover image for a story
    func generateStoryCover(id: UUID) async throws -> CoverGenerationResponse {
        var request = await createRequest(endpoint: "/api/stories/\(id.uuidString)/generate-cover", method: "POST")
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(CoverGenerationResponse.self, from: data)
    }

    // MARK: - Prompts API
    
    /// Get family prompts
    func getPrompts() async throws -> [PromptData] {
        let request = await createRequest(endpoint: "/api/prompts")
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode([PromptData].self, from: data)
    }
    
    /// Create custom prompt
    func createPrompt(text: String, category: String) async throws -> PromptData {
        let body = CreatePromptRequest(text: text, category: category)
        var request = await createRequest(endpoint: "/api/prompts", method: "POST")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(PromptData.self, from: data)
    }
    
    // MARK: - Responses API (Audio Upload)
    
    /// Upload audio response
    func uploadResponse(promptId: UUID, storyId: UUID?, audioData: Data, filename: String, source: String) async throws -> ResponseData {
        let boundary = UUID().uuidString

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)

        // Add audio file
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/mpeg\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)

        // Add prompt_id
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"prompt_id\"\r\n\r\n".data(using: .utf8)!)
        body.append(promptId.uuidString.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)

        // Add story_id (optional)
        if let storyId = storyId {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"story_id\"\r\n\r\n".data(using: .utf8)!)
            body.append(storyId.uuidString.data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
        }

        // Add source
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"source\"\r\n\r\n".data(using: .utf8)!)
        body.append(source.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        var request = await createRequest(endpoint: "/api/responses", method: "POST")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (data, _) = try await session.data(for: request)
        let result = try JSONDecoder().decode(ResponseData.self, from: data)

        // Track value analytics: audio captured via record method
        Task { @MainActor in
            ValueAnalyticsService.shared.trackStoryCapture(method: .record)
        }

        return result
    }
    
    /// Trigger transcription
    func transcribeResponse(responseId: UUID) async throws -> ResponseData {
        let request = await createRequest(endpoint: "/api/responses/\(responseId.uuidString)/transcribe", method: "POST")
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(ResponseData.self, from: data)
    }
    
    // MARK: - Profiles API
    
    /// Get family members
    func getFamilyMembers() async throws -> [FamilyMemberData] {
        let request = await createRequest(endpoint: "/api/profiles")
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode([FamilyMemberData].self, from: data)
    }
    
    /// Add elder (phone-only member)
    func addElder(name: String, phoneNumber: String) async throws -> FamilyMemberData {
        let body = AddElderRequest(name: name, phone_number: phoneNumber)
        var request = await createRequest(endpoint: "/api/profiles/elder", method: "POST")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(FamilyMemberData.self, from: data)
    }
    
    // MARK: - Reactions API
    
    /// Add reaction
    func addReaction(targetId: String, targetType: String, emoji: String) async throws -> ReactionData {
        let body = AddReactionRequest(target_id: targetId, target_type: targetType, emoji: emoji)
        var request = await createRequest(endpoint: "/api/reactions", method: "POST")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(ReactionData.self, from: data)
    }
    
    // MARK: - Settings API
    
    /// Update user profile
    func updateProfile(name: String, avatarEmoji: String, theme: String) async throws {
        let body = UpdateProfileRequest(name: name, avatar_emoji: avatarEmoji, theme: theme)
        var request = await createRequest(endpoint: "/api/settings/profile", method: "PATCH")
        request.httpBody = try JSONEncoder().encode(body)
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.updateFailed
        }
    }
    
    /// Update notification settings
    /// REMOVED: storyReminders, familyUpdates, weeklyDigest (engagement spam)
    func updateNotificationSettings(
        pushEnabled: Bool,
        emailEnabled: Bool
    ) async throws {
        let body = NotificationSettingsRequest(
            push_enabled: pushEnabled,
            email_enabled: emailEnabled,
            story_reminders: false,  // Deprecated
            family_updates: false,   // Deprecated
            weekly_digest: false     // Deprecated
        )
        var request = await createRequest(endpoint: "/api/settings/notifications", method: "PATCH")
        request.httpBody = try JSONEncoder().encode(body)
        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.updateFailed
        }
    }
    
    /// Update privacy settings
    func updatePrivacySettings(shareWithFamily: Bool, allowSuggestions: Bool, dataRetention: String) async throws {
        let body = PrivacySettingsRequest(
            share_with_family: shareWithFamily,
            allow_suggestions: allowSuggestions,
            data_retention: dataRetention
        )
        var request = await createRequest(endpoint: "/api/settings/privacy", method: "PATCH")
        request.httpBody = try JSONEncoder().encode(body)
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.updateFailed
        }
    }
    
    /// Update preference settings
    func updatePreferenceSettings(autoPlayAudio: Bool, hapticsEnabled: Bool, defaultPromptCategory: String) async throws {
        let body = PreferenceSettingsRequest(
            auto_play_audio: autoPlayAudio,
            haptics_enabled: hapticsEnabled,
            default_prompt_category: defaultPromptCategory
        )
        var request = await createRequest(endpoint: "/api/settings/preferences", method: "PATCH")
        request.httpBody = try JSONEncoder().encode(body)
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.updateFailed
        }
    }
    
    /// Export user data
    func exportUserData() async throws -> Data {
        let request = await createRequest(endpoint: "/api/settings/export", method: "POST")
        let (data, _) = try await session.data(for: request)

        // Track value analytics: data export completed
        Task { @MainActor in
            ValueAnalyticsService.shared.trackStoryExport(format: "json", storyId: "all")
        }

        return data
    }
    
    /// Delete user account
    func deleteAccount() async throws {
        var request = await createRequest(endpoint: "/api/settings/account", method: "DELETE")
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.deleteFailed
        }
    }
    
    // MARK: - Wisdom API
    
    /// Tag a story with wisdom categories using AI
    func tagStory(storyId: UUID) async throws -> WisdomTagsResponse {
        let request = await createRequest(endpoint: "/api/wisdom/tag/\(storyId.uuidString)", method: "POST")
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(WisdomTagsResponse.self, from: data)
    }
    
    /// Search stories by wisdom question
    func searchWisdom(query: String, limit: Int = 10) async throws -> WisdomSearchResponse {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let request = await createRequest(endpoint: "/api/wisdom/search?q=\(encodedQuery)&limit=\(limit)")
        let (data, _) = try await session.data(for: request)
        let result = try JSONDecoder().decode(WisdomSearchResponse.self, from: data)

        // Track value analytics: search performed
        Task { @MainActor in
            ValueAnalyticsService.shared.trackSearch(query: query, resultsCount: result.stories.count)
        }

        return result
    }
    
    /// Request a story from family members
    func createWisdomRequest(question: String, targetProfileIds: [UUID], relatedStoryId: UUID?) async throws -> WisdomRequestResponse {
        let body = CreateWisdomRequest(
            question: question,
            target_profile_ids: targetProfileIds.map { $0.uuidString },
            related_story_id: relatedStoryId?.uuidString
        )
        var request = await createRequest(endpoint: "/api/wisdom/request", method: "POST")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(WisdomRequestResponse.self, from: data)
    }
    
    /// Get pending wisdom requests for current user
    func getPendingWisdomRequests() async throws -> PendingWisdomRequestsResponse {
        let request = await createRequest(endpoint: "/api/wisdom/requests/pending")
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(PendingWisdomRequestsResponse.self, from: data)
    }
    
    /// Respond to a wisdom request (accept/decline)
    func respondToWisdomRequest(requestId: UUID, action: String) async throws {
        let body = RespondToRequestRequest(action: action)
        var request = await createRequest(endpoint: "/api/wisdom/request/\(requestId.uuidString)/respond", method: "PATCH")
        request.httpBody = try JSONEncoder().encode(body)
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.updateFailed
        }
    }
    
    /// Get tags for a story
    func getStoryTags(storyId: UUID) async throws -> WisdomTagsResponse {
        let request = await createRequest(endpoint: "/api/wisdom/tags/\(storyId.uuidString)")
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(WisdomTagsResponse.self, from: data)
    }
    
    /// Update tags manually for a story
    func updateStoryTags(
        storyId: UUID,
        emotionTags: [String]?,
        situationTags: [String]?,
        lessonTags: [String]?,
        guidanceTags: [String]?
    ) async throws {
        let body = UpdateWisdomTagsRequest(
            emotion_tags: emotionTags,
            situation_tags: situationTags,
            lesson_tags: lessonTags,
            guidance_tags: guidanceTags
        )
        var request = await createRequest(endpoint: "/api/wisdom/tags/\(storyId.uuidString)", method: "PUT")
        request.httpBody = try JSONEncoder().encode(body)
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.updateFailed
        }
    }
    
    // MARK: - Quote Cards API
    
    /// Generate a quote card from a story response
    func generateQuoteCard(
        storyId: UUID,
        responseId: UUID,
        theme: String? = nil,
        backgroundColor: String? = nil,
        textColor: String? = nil
    ) async throws -> QuoteCardResponse {
        let body = GenerateQuoteRequest(
            story_id: storyId.uuidString,
            response_id: responseId.uuidString,
            theme: theme,
            background_color: backgroundColor,
            text_color: textColor
        )
        var request = await createRequest(endpoint: "/api/quotes/generate", method: "POST")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(QuoteCardResponse.self, from: data)
    }
    
    /// Get popular quote cards for the user's family
    func getPopularQuoteCards(limit: Int = 10) async throws -> QuoteCardsResponse {
        let request = await createRequest(endpoint: "/api/quotes/popular?limit=\(limit)")
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(QuoteCardsResponse.self, from: data)
    }
    
    /// Get a specific quote card
    func getQuoteCard(id: UUID) async throws -> QuoteCardDetailResponse {
        let request = await createRequest(endpoint: "/api/quotes/\(id.uuidString)")
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(QuoteCardDetailResponse.self, from: data)
    }
    
    /// Share a quote card and get shareable URL
    func shareQuoteCard(id: UUID) async throws -> ShareQuoteResponse {
        var request = await createRequest(endpoint: "/api/quotes/\(id.uuidString)/share", method: "POST")
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(ShareQuoteResponse.self, from: data)
    }
    
    /// Save/bookmark a quote card
    func saveQuoteCard(id: UUID) async throws {
        let request = await createRequest(endpoint: "/api/quotes/\(id.uuidString)/save", method: "POST")
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.updateFailed
        }
    }
    
    /// Delete a quote card (owner only)
    func deleteQuoteCard(id: UUID) async throws {
        let request = await createRequest(endpoint: "/api/quotes/\(id.uuidString)", method: "DELETE")
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.deleteFailed
        }
    }
    
    // MARK: - Trivia Game API
    
    /// Get trivia questions for a category
    func getTriviaQuestions(category: String, count: Int = 5) async throws -> TriviaQuestionsResponse {
        let request = await createRequest(endpoint: "/api/trivia/questions?category=\(category)&count=\(count)")
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(TriviaQuestionsResponse.self, from: data)
    }
    
    /// Submit trivia answer
    func submitTriviaAnswer(questionId: UUID, selectedOptionId: UUID) async throws -> TriviaAnswerResponse {
        let body = TriviaAnswerRequest(question_id: questionId.uuidString, selected_option_id: selectedOptionId.uuidString)
        var request = await createRequest(endpoint: "/api/trivia/answer", method: "POST")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(TriviaAnswerResponse.self, from: data)
    }
    
    /// Submit completed trivia game
    func submitTriviaGame(sessionId: UUID, score: Int, answers: [String: String]) async throws {
        let body = TriviaGameSubmit(session_id: sessionId.uuidString, score: score, answers: answers)
        var request = await createRequest(endpoint: "/api/trivia/complete", method: "POST")
        request.httpBody = try JSONEncoder().encode(body)
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.updateFailed
        }
    }
    
    /// Get trivia leaderboard
    func getTriviaLeaderboard(limit: Int = 10) async throws -> TriviaLeaderboardResponse {
        let request = await createRequest(endpoint: "/api/trivia/leaderboard?limit=\(limit)")
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(TriviaLeaderboardResponse.self, from: data)
    }
    
    // MARK: - Me vs Family API
    
    /// Get available comparison topics
    func getComparisonTopics() async throws -> ComparisonTopicsResponse {
        let request = await createRequest(endpoint: "/api/comparison/topics")
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(ComparisonTopicsResponse.self, from: data)
    }
    
    /// Create a new comparison
    func createComparison(topicId: UUID, userResponse: String, source: String) async throws -> ComparisonResponse {
        let body = CreateComparisonRequest(topic_id: topicId.uuidString, user_response: userResponse, source: source)
        var request = await createRequest(endpoint: "/api/comparison/create", method: "POST")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(ComparisonResponse.self, from: data)
    }
    
    /// Get comparison by ID
    func getComparison(comparisonId: UUID) async throws -> ComparisonResponse {
        let request = await createRequest(endpoint: "/api/comparison/\(comparisonId.uuidString)")
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(ComparisonResponse.self, from: data)
    }
    
    /// Share comparison result
    func shareComparison(comparisonId: UUID, platform: String) async throws -> ShareComparisonResponse {
        let body = ShareRequest(comparison_id: comparisonId.uuidString, platform: platform)
        var request = await createRequest(endpoint: "/api/comparison/share", method: "POST")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(ShareComparisonResponse.self, from: data)
    }

    // MARK: - Diary Upload API

    /// Get all diary uploads for the current family
    func getDiaryUploads() async throws -> [DiaryUploadListItem] {
        let request = await createRequest(endpoint: "/api/diary")
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode([DiaryUploadListItem].self, from: data)
    }

    /// Get OCR status for a diary upload
    func getDiaryStatus(uploadId: String) async throws -> DiaryStatusResponse {
        let request = await createRequest(endpoint: "/api/diary/\(uploadId)/status")
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(DiaryStatusResponse.self, from: data)
    }

    /// Delete a diary upload
    func deleteDiaryUpload(uploadId: String) async throws {
        let request = await createRequest(endpoint: "/api/diary/\(uploadId)", method: "DELETE")
        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.deleteFailed
        }
    }
}

// MARK: - Diary API Models

struct DiaryUploadListItem: Codable, Identifiable {
    let id: String
    let source: String
    let title: String?
    let processingStatus: String
    let pageCount: Int
    let createdAt: String
    let storyId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case source
        case title
        case processingStatus = "processing_status"
        case pageCount = "page_count"
        case createdAt = "created_at"
        case storyId = "story_id"
    }
}

struct DiaryStatusResponse: Codable {
    let uploadId: String
    let status: String
    let pageCount: Int?
    let pages: [DiaryPageStatus]?
    let combinedText: String?
    let confidence: Double?
    let progress: DiaryProgress?

    enum CodingKeys: String, CodingKey {
        case uploadId = "upload_id"
        case status
        case pageCount = "page_count"
        case pages
        case combinedText = "combined_text"
        case confidence
        case progress
    }
}

struct DiaryPageStatus: Codable {
    let pageIndex: Int
    let imageUrl: String
    let extractedText: String?
    let confidence: Double?

    enum CodingKeys: String, CodingKey {
        case pageIndex = "page_index"
        case imageUrl = "image_url"
        case extractedText = "extracted_text"
        case confidence
    }
}

struct DiaryProgress: Codable {
    let completed: Int
    let total: Int
    let percentage: Int
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case updateFailed
    case deleteFailed
    case exportFailed
    
    var errorDescription: String? {
        switch self {
        case .updateFailed:
            return "Failed to update settings"
        case .deleteFailed:
            return "Failed to delete account"
        case .exportFailed:
            return "Failed to export data"
        }
    }
}

// MARK: - Request Models

struct CreateStoryAPIRequest: Codable {
    let prompt_id: String
}

struct CompleteStoryRequest: Codable {
    let title: String
    let summary: String
    let cover_image_url: String
    let voice_count: Int
}

struct CreatePromptRequest: Codable {
    let text: String
    let category: String
}

struct AddElderRequest: Codable {
    let name: String
    let phone_number: String
}

struct AddReactionRequest: Codable {
    let target_id: String
    let target_type: String
    let emoji: String
}

// MARK: - Settings Request Models

struct UpdateProfileRequest: Codable {
    let name: String
    let avatar_emoji: String
    let theme: String
}

struct NotificationSettingsRequest: Codable {
    let push_enabled: Bool
    let email_enabled: Bool
    let story_reminders: Bool
    let family_updates: Bool
    let weekly_digest: Bool
}

struct PrivacySettingsRequest: Codable {
    let share_with_family: Bool
    let allow_suggestions: Bool
    let data_retention: String
}

struct PreferenceSettingsRequest: Codable {
    let auto_play_audio: Bool
    let haptics_enabled: Bool
    let default_prompt_category: String
}

// MARK: - Response Models

public struct PromptData: Identifiable, Codable {
    public var id: String
    public var text: String
    public var category: String?
    public var isCustom: Bool
    public var createdAt: String

    public init(id: String, text: String, category: String?, isCustom: Bool, createdAt: String) {
        self.id = id
        self.text = text
        self.category = category
        self.isCustom = isCustom
        self.createdAt = createdAt
    }

    public var createdAtDate: Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: createdAt) ?? Date()
    }
}

public struct ResponseData: Identifiable, Codable {
    public var id: String
    public var promptId: String
    public var storyId: String?
    public var userId: String
    public var source: String
    public var mediaUrl: String?
    public var transcriptionText: String?
    public var durationSeconds: Int?
    public var processingStatus: String
    public var createdAt: String
    
    public init(id: String, promptId: String, storyId: String?, userId: String, source: String, mediaUrl: String?, transcriptionText: String?, durationSeconds: Int?, processingStatus: String, createdAt: String) {
        self.id = id
        self.promptId = promptId
        self.storyId = storyId
        self.userId = userId
        self.source = source
        self.mediaUrl = mediaUrl
        self.transcriptionText = transcriptionText
        self.durationSeconds = durationSeconds
        self.processingStatus = processingStatus
        self.createdAt = createdAt
    }
    
    public var createdAtDate: Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: createdAt) ?? Date()
    }
}

struct ReactionData: Identifiable, Codable {
    let id: String
    let userId: String
    let targetId: String
    let targetType: String
    let emoji: String
    let createdAt: String
    
    var createdAtDate: Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: createdAt) ?? Date()
    }
}

struct FamilyMemberData: Identifiable, Codable {
    let id: String
    let authUserId: String?
    let familyId: String
    let fullName: String?
    let avatarUrl: String?
    let role: String
    let phoneNumber: String?
}

struct StoryData: Identifiable, Codable {
    let id: String
    let promptId: String?
    let familyId: String
    let title: String?
    let summaryText: String?
    let coverImageUrl: String?
    let voiceCount: Int
    let isCompleted: Bool
    let createdAt: String
    let promptText: String?
    let promptCategory: String?
    
    var storytellerColorName: String {
        guard let promptCategory = promptCategory else { return "blue" }
        switch promptCategory.lowercased() {
        case "childhood": return "orange"
        case "holidays": return "green"
        case "funny": return "purple"
        default: return "blue"
        }
    }
    
    var createdAtDate: Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: createdAt) ?? Date()
    }
}

struct StoryDetailData: Codable {
    let story: StoryData
    let responses: [StorySegmentData]
}

struct StorySegmentData: Identifiable, Codable {
    let id: String
    let userId: String
    let source: String
    let mediaUrl: String?
    let transcriptionText: String?
    let durationSeconds: Int?
    let createdAt: String
    let fullName: String
    let role: String
    let avatarUrl: String?
    let replyToResponseId: String?
    
    var storytellerColorName: String {
        switch role {
        case "dark": return "purple"
        case "light", "organizer": return "blue"
        case "child": return "green"
        case "elder": return "orange"
        default: return "blue"
        }
    }
    
    var storytellerColor: Color {
        switch role {
        case "dark": return .storytellerTeen
        case "light", "organizer": return .storytellerParent
        case "child": return .storytellerChild
        case "elder": return .storytellerElder
        default: return .storytellerParent
        }
    }
    
    var createdAtDate: Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: createdAt) ?? Date()
    }
    
    var isRootResponse: Bool {
        replyToResponseId == nil
    }
    
    var isReply: Bool {
        replyToResponseId != nil
    }
}

struct FamilyResponse: Codable {
    let id: String
    let name: String
    let inviteSlug: String?
}

struct FamilyInfo: Codable {
    let id: String
    let name: String
    let invite_slug: String
    let plan_tier: String?
    let created_at: String?

    var inviteUrl: String {
        return "https://storyrd.app/join/\(invite_slug)"
    }
}

struct CreateFamilyRequest: Codable {
    let name: String
}

struct JoinFamilyRequest: Codable {
    let invite_code: String
}

struct CoverGenerationResponse: Codable {
    let success: Bool
    let coverImageUrl: String?
    let revisedPrompt: String?
}

// MARK: - Wisdom API Models

struct WisdomTagsResponse: Codable {
    let success: Bool?
    let storyId: String?
    let tags: WisdomTags?
    let confidence: Double?
    let message: String?
}

struct WisdomTags: Codable {
    let emotions: [String]?
    let situations: [String]?
    let lessons: [String]?
    let guidance: [String]?
    let keywords: [String]?
}

struct WisdomSearchResponse: Codable {
    let query: String
    let stories: [WisdomSearchResult]
    let count: Int
}

struct WisdomSearchResult: Codable, Identifiable {
    var id: String { storyId }
    
    let storyId: String
    let title: String?
    let summaryText: String?
    let coverImageUrl: String?
    let promptText: String?
    let emotionTags: [String]?
    let situationTags: [String]?
    let lessonTags: [String]?
    let matchScore: Double?
}

struct WisdomRequestResponse: Codable {
    let success: Bool
    let request: WisdomRequestDetail
}

struct WisdomRequestDetail: Codable {
    let id: String
    let question: String
    let targets: [WisdomRequestTarget]
    let status: String
    let createdAt: String
}

struct WisdomRequestTarget: Codable {
    let id: String
    let name: String
}

struct PendingWisdomRequestsResponse: Codable {
    let requests: [PendingWisdomRequest]
    let count: Int
}

struct PendingWisdomRequest: Codable {
    let id: String
    let question: String
    let requester: RequesterInfo?
    let createdAt: String
    let expiresAt: String
}

struct RequesterInfo: Codable {
    let fullName: String?
    let avatarUrl: String?
}

struct CreateWisdomRequest: Codable {
    let question: String
    let target_profile_ids: [String]
    let related_story_id: String?
}

struct RespondToRequestRequest: Codable {
    let action: String
}

struct UpdateWisdomTagsRequest: Codable {
    let emotion_tags: [String]?
    let situation_tags: [String]?
    let lesson_tags: [String]?
    let guidance_tags: [String]?
}

// MARK: - Quote Cards Models

struct GenerateQuoteRequest: Codable {
    let story_id: String
    let response_id: String
    let theme: String?
    let background_color: String?
    let text_color: String?
}

struct QuoteCardResponse: Codable {
    let id: String
    let quote: String
    let author: String
    let role: String?
    let theme: String
}

struct QuoteCardsResponse: Codable {
    let quotes: [QuoteCardData]
    let count: Int
}

struct QuoteCardDetailResponse: Codable {
    let quote: QuoteCardData
}

struct ShareQuoteResponse: Codable {
    let url: String
    let quote: String
    let author: String
    let imageUrl: String?
}

struct QuoteCardData: Identifiable, Codable {
    let id: String
    let quoteText: String
    let authorName: String
    let authorRole: String?
    let theme: String
    let imageUrl: String?
    let viewsCount: Int
    let sharesCount: Int
    let savesCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case quoteText = "quote_text"
        case authorName = "author_name"
        case authorRole = "author_role"
        case theme
        case imageUrl = "image_url"
        case viewsCount = "views_count"
        case sharesCount = "shares_count"
        case savesCount = "saves_count"
    }
}

// MARK: - AI Wisdom Summary Models


struct RelatedStoryData: Codable {
    let id: String
    let title: String
    let storyteller: String
    let year: Int?
}

struct FollowUpRequest: Codable {
    let summary_id: String
    let question: String
}

// MARK: - Trivia Game Models

struct TriviaQuestionsResponse: Codable {
    let questions: [TriviaQuestionData]
    let sessionId: String
}

struct TriviaQuestionData: Codable {
    let id: String
    let question: String
    let options: [TriviaOptionData]
    let correctOptionId: String
    let explanation: String
    let category: String
    let difficulty: String
    let points: Int
}

struct TriviaOptionData: Codable {
    let id: String
    let text: String
    let label: String
    let generation: String?
}

struct TriviaAnswerRequest: Codable {
    let question_id: String
    let selected_option_id: String
}

struct TriviaAnswerResponse: Codable {
    let isCorrect: Bool
    let correctOptionId: String
    let explanation: String
    let pointsEarned: Int
}

struct TriviaGameSubmit: Codable {
    let session_id: String
    let score: Int
    let answers: [String: String]
}

struct TriviaLeaderboardResponse: Codable {
    let entries: [TriviaLeaderboardEntryData]
}

struct TriviaLeaderboardEntryData: Codable {
    let id: String
    let memberName: String
    let score: Int
    let correctAnswers: Int
    let streak: Int
    let avatarEmoji: String?
}

// MARK: - Me vs Family Models

struct ComparisonTopicsResponse: Codable {
    let topics: [ComparisonTopicData]
}

struct ComparisonTopicData: Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let category: String
    let questionPrompt: String
    let familyQuestion: String
    let isAvailable: Bool
}

struct CreateComparisonRequest: Codable {
    let topic_id: String
    let user_response: String
    let source: String
}

struct ComparisonResponse: Codable {
    let comparison: ComparisonData
    let userResponse: UserResponseData
    let familyResponses: [FamilyResponseData]
    let aiInsight: String
}

struct ComparisonData: Codable {
    let id: String
    let topic: String
    let question: String
}

struct UserResponseData: Codable {
    let id: String
    let text: String
    let source: String
    let timestamp: String
}

struct FamilyResponseData: Codable {
    let id: String
    let text: String
    let storyteller: String
    let generation: String
    let year: Int?
    let timestamp: String
}

struct ShareRequest: Codable {
    let comparison_id: String
    let platform: String
}

struct ShareComparisonResponse: Codable {
    let shareUrl: String
    let imageUrl: String?
}
