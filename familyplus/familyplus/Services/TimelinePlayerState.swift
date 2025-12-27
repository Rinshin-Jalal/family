//
//  TimelinePlayerState.swift
//  StoryRide
//
//  Shared state between audio player and timeline view
//  Coordinates which response is currently playing across the app
//

import SwiftUI
import Combine

// MARK: - Timeline Player State

/// Shared state singleton that coordinates playback state
/// between AudioPlayerService and ThreadedTimelineView
@MainActor
class TimelinePlayerState: ObservableObject {
    /// Singleton instance for app-wide access
    static let shared = TimelinePlayerState()

    /// ID of the response currently playing
    @Published var currentlyPlayingId: String?

    /// Whether audio is actively playing
    @Published var isPlaying: Bool = false

    /// Update the playing state
    func setPlaying(_ responseId: String?) {
        currentlyPlayingId = responseId
        isPlaying = responseId != nil
    }

    /// Clear playing state (when stopped)
    func clear() {
        currentlyPlayingId = nil
        isPlaying = false
    }

    private init() {}
}

// MARK: - Convenience Extensions

extension TimelinePlayerState {
    /// Check if a specific response is currently playing
    func isPlaying(_ responseId: String) -> Bool {
        return currentlyPlayingId == responseId && isPlaying
    }
}
