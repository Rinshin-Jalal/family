//
//  SupabaseService.swift
//  StoryRide
//
//  Supabase AUTH ONLY - All data and storage operations use Backend API
//  Audio files are stored in Cloudflare R2 via the backend API
//

import Foundation

// MARK: - Supabase Service (Auth Only)

/// Service for Supabase authentication operations only.
/// All data queries and file storage operations MUST go through APIService -> Backend API.
/// This ensures proper API boundaries, RLS enforcement, and schema encapsulation.
final class SupabaseService {
    static let shared = SupabaseService()
    
    // Placeholder values - replace with environment-specific credentials
    private let supabaseURL = "https://your-project.supabase.co"
    private let anonKey = "your-anon-key"
    
    private init() {}
    
    // MARK: - Authentication
    
    /// Get current user session
    func getCurrentSession() async throws -> Session? {
        return nil
    }
    
    /// Sign in with Apple OAuth
    func signInWithApple(idToken: String, nonce: String) async throws -> Session {
        throw SupabaseServiceError.notConfigured
    }
    
    /// Sign out current user
    func signOut() async throws {}
    
    /// Get current user ID from stored token
    func getCurrentUserId() async throws -> String? {
        // Read from UserDefaults directly to avoid circular dependency
        return UserDefaults.standard.string(forKey: "auth_token")
    }
}

// MARK: - Errors

enum SupabaseServiceError: LocalizedError {
    case notConfigured
    case sdkNotInstalled
    case storageNotSupported
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Supabase credentials not configured"
        case .sdkNotInstalled:
            return "Supabase SDK not installed - use APIService for all data operations"
        case .storageNotSupported:
            return "Direct storage access not supported - audio files must use backend API (R2)"
        }
    }
}

// MARK: - Session Model

struct Session {
    let accessToken: String
    let refreshToken: String?
    let user: User
    
    struct User {
        let id: UUID
        let email: String?
    }
}
