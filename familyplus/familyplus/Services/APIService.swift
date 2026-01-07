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
        let body = CreateStoryRequest(prompt_id: promptId.uuidString)
        var request = await createRequest(endpoint: "/api/stories", method: "POST")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(StoryData.self, from: data)
    }
    
    // MARK: - Family API
    
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
        return try JSONDecoder().decode(StoryData.self, from: data)
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
        return try JSONDecoder().decode(ResponseData.self, from: data)
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
    func updateNotificationSettings(
        pushEnabled: Bool,
        emailEnabled: Bool,
        storyReminders: Bool,
        familyUpdates: Bool,
        weeklyDigest: Bool
    ) async throws {
        let body = NotificationSettingsRequest(
            push_enabled: pushEnabled,
            email_enabled: emailEnabled,
            story_reminders: storyReminders,
            family_updates: familyUpdates,
            weekly_digest: weeklyDigest
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
        return try JSONDecoder().decode(WisdomSearchResponse.self, from: data)
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
        var request = await createRequest(endpoint: "/api/quotes/\(id.uuidString)", method: "DELETE")
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.deleteFailed
        }
    }
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

struct CreateStoryRequest: Codable {
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

struct PromptData: Identifiable, Codable {
    let id: String
    let text: String
    let category: String?
    let isCustom: Bool
    let createdAt: String

    var createdAtDate: Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: createdAt) ?? Date()
    }
}

struct ResponseData: Identifiable, Codable {
    let id: String
    let promptId: String
    let storyId: String?
    let userId: String
    let source: String
    let mediaUrl: String?
    let transcriptionText: String?
    let durationSeconds: Int?
    let processingStatus: String
    let createdAt: String
    
    var createdAtDate: Date {
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
        case "dark": return .storytellerPurple
        case "light", "organizer": return .storytellerBlue
        case "child": return .storytellerGreen
        case "elder": return .storytellerOrange
        default: return .storytellerBlue
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

struct CreateFamilyRequest: Codable {
    let name: String
}

struct JoinFamilyRequest: Codable {
    let invite_code: String
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

struct WisdomSearchResult: Codable {
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
