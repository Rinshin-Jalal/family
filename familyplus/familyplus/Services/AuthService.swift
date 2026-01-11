//
//  AuthService.swift
//  StoryRide
//
//  Manages authentication state and tokens
//

import Foundation
import Combine

// MARK: - Auth Service

final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var isAuthenticated = false
    @Published var currentToken: String?
    @Published var currentUserId: String?

    private init() {
        loadToken()
    }
    
    // MARK: - Token Management
    
    /// Save auth token from Supabase
    func setToken(_ token: String, userId: String? = nil) {
        currentToken = token
        if let userId = userId {
            currentUserId = userId
            UserDefaults.standard.set(userId, forKey: "auth_user_id")
        }
        isAuthenticated = true
        UserDefaults.standard.set(token, forKey: "auth_token")
    }

    /// Clear auth token (logout)
    func clearToken() {
        currentToken = nil
        currentUserId = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "auth_token")
        UserDefaults.standard.removeObject(forKey: "auth_user_id")
    }
    
    /// Load saved token from UserDefaults
    private func loadToken() {
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            currentToken = token
            currentUserId = UserDefaults.standard.string(forKey: "auth_user_id")
            isAuthenticated = true
        }
    }
    
    // MARK: - Authorization Header
    
    /// Get Bearer token for API requests
    func getAuthHeader() -> String? {
        guard let token = currentToken else {
            return nil
        }
        return "Bearer \(token)"
    }
}
