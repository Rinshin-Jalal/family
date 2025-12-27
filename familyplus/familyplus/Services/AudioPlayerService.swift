//
//  AudioPlayerService.swift
//  StoryRide
//
//  Handles audio playback with AVPlayer
//

import Foundation
import AVFoundation
import Combine

// MARK: - Playlist Item

struct PlaylistItem {
    let id: String
    let url: URL
    let duration: TimeInterval
    let transcript: String?
}

// MARK: - Audio Player Service

@MainActor
class AudioPlayerService: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var playbackProgress: Double = 0 // 0.0 to 1.0

    // Playlist support
    @Published var currentResponseId: String?
    @Published var playlist: [PlaylistItem] = []
    @Published var currentIndex: Int = 0
    @Published var isAutoPlaying: Bool = false

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var currentURL: URL?
    private var endObserver: Any?

    // Shared state for timeline coordination
    private let playerState = TimelinePlayerState.shared

    nonisolated deinit {
        // Cleanup synchronously - safe because we're just removing observers and stopping player
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        player?.pause()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public Methods

    /// Load an audio file for playback
    func load(url: URL, responseId: String? = nil) {
        cleanup()

        currentURL = url
        currentResponseId = responseId

        // Update shared state
        if let responseId = responseId {
            playerState.setPlaying(responseId)
        }

        // Create player
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)

        // Setup audio session for playback
        setupAudioSession()

        // Get duration
        Task {
            await loadDuration(for: playerItem)
        }

        // Observe playback progress
        addTimeObserver()

        // Observe when playback finishes
        observePlaybackEnd()

        print("✅ Audio loaded: \(url.lastPathComponent)")
    }

    /// Play the loaded audio
    func play() {
        guard let player = player else {
            print("⚠️ No audio loaded to play")
            return
        }

        player.play()
        isPlaying = true
        playerState.isPlaying = true
        print("▶️ Playback started")
    }

    /// Pause playback
    func pause() {
        player?.pause()
        isPlaying = false
        playerState.isPlaying = false
        print("⏸️ Playback paused")
    }

    /// Toggle play/pause
    func togglePlayback() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    /// Seek to specific time (in seconds)
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime) { [weak self] completed in
            if completed {
                Task { @MainActor in
                    self?.currentTime = time
                    self?.updateProgress()
                }
            }
        }
    }

    /// Seek to progress (0.0 to 1.0)
    func seekToProgress(_ progress: Double) {
        let time = duration * progress
        seek(to: time)
    }

    /// Stop playback and reset
    func stop() {
        pause()
        seek(to: 0)
        isAutoPlaying = false
        playerState.clear()
        print("⏹️ Playback stopped")
    }

    /// Clean up player and observers
    func cleanup() {
        // Remove observer
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }

        // Stop and release player
        player?.pause()
        player = nil

        // Reset state
        isPlaying = false
        currentTime = 0
        duration = 0
        playbackProgress = 0
        currentURL = nil
        currentResponseId = nil

        // Remove notification observers
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Private Methods

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            print("❌ Failed to setup audio session: \(error)")
        }
    }

    private func loadDuration(for item: AVPlayerItem) async {
        // Wait for item to be ready
        do {
            let status = try await item.asset.load(.duration)
            let seconds = CMTimeGetSeconds(status)
            if seconds.isFinite {
                self.duration = seconds
                print("📊 Duration loaded: \(String(format: "%.1f", seconds))s")
            }
        } catch {
            print("❌ Failed to load duration: \(error)")
        }
    }

    private func addTimeObserver() {
        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                self?.currentTime = time.seconds
                self?.updateProgress()
            }
        }
    }

    private func updateProgress() {
        if duration > 0 {
            playbackProgress = min(1.0, currentTime / duration)
        }
    }

    private func observePlaybackEnd() {
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handlePlaybackEnd()
            }
        }
    }

    private func handlePlaybackEnd() {
        isPlaying = false
        playerState.isPlaying = false

        // Auto-advance to next track if enabled
        if isAutoPlaying {
            advanceToNextTrack()
        } else {
            seek(to: 0)
            print("✅ Playback finished")
        }
    }

    // MARK: - Playlist Methods

    /// Load a playlist starting from a specific index
    func loadPlaylist(_ items: [PlaylistItem], startIndex: Int = 0) {
        self.playlist = items
        self.currentIndex = startIndex

        // Load first item
        if let item = items[safe: startIndex] {
            load(url: item.url, responseId: item.id)
        }
    }

    /// Advance to next track in playlist
    private func advanceToNextTrack() {
        guard currentIndex < playlist.count - 1 else {
            // End of playlist
            isAutoPlaying = false
            playerState.clear()
            print("✅ Playlist finished")
            return
        }

        currentIndex += 1
        let nextItem = playlist[currentIndex]

        // Brief pause before next track
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
            await MainActor.run {
                load(url: nextItem.url, responseId: nextItem.id)
                play()
                print("▶️ Auto-advanced to track \(currentIndex + 1)/\(playlist.count)")
            }
        }
    }
}

// MARK: - Convenience Methods

extension AudioPlayerService {
    /// Play all responses from a starting point
    /// - Parameters:
    ///   - responses: Array of story segments to play as a playlist
    ///   - startId: ID of the response to start playing from
    func playFromHere(_ responses: [StorySegmentData], startId: String) {
        // Build playlist items
        let items = responses.compactMap { response -> PlaylistItem? in
            guard let urlString = response.mediaUrl,
                  let url = URL(string: urlString) else { return nil }
            return PlaylistItem(
                id: response.id,
                url: url,
                duration: TimeInterval(response.durationSeconds ?? 0),
                transcript: response.transcriptionText
            )
        }

        guard !items.isEmpty else {
            print("⚠️ No valid audio items in playlist")
            return
        }

        // Find starting index
        guard let startIndex = items.firstIndex(where: { $0.id == startId }) else {
            print("⚠️ Starting response not found in playlist")
            return
        }

        // Enable auto-play and load playlist
        isAutoPlaying = true
        loadPlaylist(items, startIndex: startIndex)
        play()

        print("▶️ Starting playlist from \(startIndex + 1)/\(items.count)")
    }

    /// Create player and immediately start playing
    func playImmediately(url: URL) {
        load(url: url)
        // Small delay to ensure player is ready
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            play()
        }
    }

    /// Formatted current time string (MM:SS)
    var formattedCurrentTime: String {
        formatTime(currentTime)
    }

    /// Formatted duration string (MM:SS)
    var formattedDuration: String {
        formatTime(duration)
    }

    /// Formatted remaining time string (MM:SS)
    var formattedRemainingTime: String {
        formatTime(duration - currentTime)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite && time >= 0 else { return "0:00" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Preview Helper

extension AudioPlayerService {
    /// Create a mock player for SwiftUI previews
    static var preview: AudioPlayerService {
        let service = AudioPlayerService()
        service.duration = 180 // 3 minutes
        service.currentTime = 45 // 45 seconds in
        service.playbackProgress = 0.25
        service.isPlaying = true
        return service
    }
}

// MARK: - Array Safe Subscript Extension

extension Array {
    /// Safe array subscript that returns nil for out-of-bounds access
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
