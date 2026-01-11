//
//  SupabaseService.swift
//  StoryRide
//
//  Supabase AUTH ONLY - All data and storage operations use Backend API
//  Audio files are stored in Cloudflare R2 via the backend API
//

import Foundation
import Supabase

// MARK: - Supabase Service (Auth Only)

/// Service for Supabase authentication operations only.
/// All data queries and file storage operations MUST go through APIService -> Backend API.
/// This ensures proper API boundaries, RLS enforcement, and schema encapsulation.
final class SupabaseService {
    static let shared = SupabaseService()

    /// Supabase client instance
    let client: SupabaseClient

    private init() {
        #if DEBUG
        // Development Supabase
        let url = URL(string: "https://subsznzkruecxudxpbzw.supabase.co")!
        let anonKey = "sb_publishable_wIMCgcwD-dyDwCkB0PhNlA_-ACMyTZQ"
        #else
        // Production Supabase
        let url = URL(string: "https://subsznzkruecxudxpbzw.supabase.co")!
        let anonKey = "sb_publishable_wIMCgcwD-dyDwCkB0PhNlA_-ACMyTZQ"
        #endif

        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: anonKey
        )
    }

    // MARK: - Authentication

    /// Get current user session
    func getCurrentSession() async throws -> AuthSession? {
        return try await client.auth.session
    }

    /// Sign in anonymously (guest auth for testing)
    func signInAnonymously() async throws -> AuthSession {
        let session = try await client.auth.signInAnonymously()

        // Store user ID for backend API requests
        UserDefaults.standard.set(session.user.id.uuidString, forKey: "auth_user_id")

        return session
    }

    /// Sign in with Apple OAuth
    func signInWithApple(idToken: String, nonce: String) async throws -> AuthSession {
        let session = try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )

        // Store user ID for backend API requests
        UserDefaults.standard.set(session.user.id.uuidString, forKey: "auth_user_id")

        return session
    }

    /// Sign up with email and password (for testing)
    func signUp(email: String, password: String) async throws -> AuthSession {
        let response = try await client.auth.signUp(email: email, password: password)

        guard let session = response.session else {
            throw SupabaseServiceError.signUpFailed
        }

        // Store user ID for backend API requests
        UserDefaults.standard.set(session.user.id.uuidString, forKey: "auth_user_id")

        return session
    }

    /// Sign in with email and password (for testing)
    func signIn(email: String, password: String) async throws -> AuthSession {
        let session = try await client.auth.signIn(email: email, password: password)

        // Store user ID for backend API requests
        UserDefaults.standard.set(session.user.id.uuidString, forKey: "auth_user_id")

        return session
    }

    /// Sign out current user
    func signOut() async throws {
        try await client.auth.signOut()
        UserDefaults.standard.removeObject(forKey: "auth_user_id")
        UserDefaults.standard.removeObject(forKey: "auth_token")
    }

    /// Get current user ID from session
    func getCurrentUserId() async throws -> String? {
        if let session = try await getCurrentSession() {
            return session.user.id.uuidString
        }
        return UserDefaults.standard.string(forKey: "auth_user_id")
    }

    /// Get access token for API requests
    func getAccessToken() async throws -> String? {
        return try await getCurrentSession()?.accessToken
    }
}

// MARK: - Errors

enum SupabaseServiceError: LocalizedError {
    case notConfigured
    case sdkNotInstalled
    case storageNotSupported
    case signUpFailed

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Supabase credentials not configured"
        case .sdkNotInstalled:
            return "Supabase SDK not installed - use APIService for all data operations"
        case .storageNotSupported:
            return "Direct storage access not supported - audio files must use backend API (R2)"
        case .signUpFailed:
            return "Sign up failed - no session returned"
        }
    }
}

// MARK: - Type Aliases for Compatibility

typealias AuthSession = Supabase.Session
