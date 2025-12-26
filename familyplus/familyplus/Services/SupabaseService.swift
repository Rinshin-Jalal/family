//
//  SupabaseService.swift
//  StoryRide
//
//  Supabase AUTH + STORAGE - All data operations use Backend API
//

import Foundation
import Supabase
import SwiftUI

// MARK: - Supabase Service

final class SupabaseService {
    static let shared = SupabaseService()

    private let client: SupabaseClient

    // Storage bucket name for audio files
    private let audioStorageBucket = "story-audio"

    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: "https://your-project.supabase.co")!,
            supabaseKey: "your-anon-key"
        )
    }

    // MARK: - Authentication

    /// Get current user session
    func getCurrentSession() async throws -> Session? {
        return try await client.auth.session
    }

    /// Sign in with Apple
    func signInWithApple(idToken: String, nonce: String) async throws -> Session {
        return try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )
    }

    /// Sign out current user
    func signOut() async throws {
        try await client.auth.signOut()
    }

    /// Get current user ID from session
    func getCurrentUserId() async throws -> String? {
        let session = try await getCurrentSession()
        return session?.user.id.uuidString
    }

    // MARK: - Storage (Audio Files)

    /// Upload audio file to Supabase Storage
    /// - Parameters:
    ///   - fileURL: Local file URL to upload
    ///   - familyId: Family ID for organizing files
    ///   - storyId: Story ID for organizing files
    /// - Returns: Public URL of the uploaded file
    func uploadAudio(fileURL: URL, familyId: String, storyId: String) async throws -> String {
        // Read file data
        let fileData = try Data(contentsOf: fileURL)

        // Create unique file path
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileName = "\(familyId)/\(storyId)/\(timestamp).m4a"

        print("📤 Uploading audio: \(fileName) (\(fileData.count / 1024)KB)")

        // Upload to storage
        _ = try await client.storage
            .from(audioStorageBucket)
            .upload(
                path: fileName,
                file: fileData,
                options: FileOptions(
                    contentType: "audio/mp4"
                )
            )

        // Get public URL using the path we uploaded to
        let publicURL = try client.storage
            .from(audioStorageBucket)
            .getPublicURL(path: fileName)

        print("✅ Audio uploaded: \(publicURL)")

        return publicURL.absoluteString
    }

    /// Delete audio file from Supabase Storage
    /// - Parameter path: Storage path (e.g., "familyId/storyId/timestamp.m4a")
    func deleteAudio(path: String) async throws {
        try await client.storage
            .from(audioStorageBucket)
            .remove(paths: [path])

        print("🗑️ Audio deleted: \(path)")
    }

    /// Download audio file from Supabase Storage
    /// - Parameter path: Storage path
    /// - Returns: Data of the audio file
    func downloadAudio(path: String) async throws -> Data {
        let data = try await client.storage
            .from(audioStorageBucket)
            .download(path: path)

        print("⬇️ Audio downloaded: \(path) (\(data.count / 1024)KB)")

        return data
    }
}

// MARK: - Data Models (for type safety - all real data from API)

struct FamilyMemberData: Identifiable, Codable {
    let id: String
    let authUserId: String?
    let familyId: String
    let fullName: String?
    let avatarUrl: String?
    let role: String
    let phoneNumber: String?
    
    var personaRole: PersonaRole {
        switch role {
        case "teen": return .teen
        case "parent", "organizer": return .parent
        case "child": return .child
        case "elder": return .elder
        default: return .teen
        }
    }
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
    
    var storytellerColor: Color {
        guard let promptCategory = promptCategory else { return .storytellerBlue }
        switch promptCategory.lowercased() {
        case "childhood": return .storytellerOrange
        case "holidays": return .storytellerGreen
        case "funny": return .storytellerPurple
        default: return .storytellerBlue
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
    let replyToResponseId: String? // 🆕 For threading perspectives

    var storytellerColor: Color {
        switch role {
        case "teen": return .storytellerPurple
        case "parent", "organizer": return .storytellerBlue
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

    // Check if this is a root response (not a reply)
    var isRootResponse: Bool {
        replyToResponseId == nil
    }

    // Check if this is a reply to another response
    var isReply: Bool {
        replyToResponseId != nil
    }
}
