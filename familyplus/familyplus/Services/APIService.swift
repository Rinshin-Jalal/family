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
    
    // TODO: Replace with actual backend URL when deployed
    private let baseURL = "http://localhost:8787"
    
    private let session: URLSession
    
    private init() {
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

        // Add user ID from Supabase auth for backend validation
        if let userId = try? await SupabaseService.shared.getCurrentUserId() {
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

// MARK: - Response Models (reused from SupabaseService for consistency)

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
