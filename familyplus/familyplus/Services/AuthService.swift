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
    
    private init() {
        loadToken()
    }
    
    // MARK: - Token Management
    
    /// Save auth token from Supabase
    func setToken(_ token: String) {
        currentToken = token
        isAuthenticated = true
        UserDefaults.standard.set(token, forKey: "auth_token")
    }
    
    /// Clear auth token (logout)
    func clearToken() {
        currentToken = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "auth_token")
    }
    
    /// Load saved token from UserDefaults
    private func loadToken() {
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            currentToken = token
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
