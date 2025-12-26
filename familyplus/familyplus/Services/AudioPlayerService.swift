//
//  AudioPlayerService.swift
//  StoryRide
//
//  Handles audio playback with AVPlayer
//

import Foundation
import AVFoundation
import Combine

// MARK: - Audio Player Service

@MainActor
class AudioPlayerService: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var playbackProgress: Double = 0 // 0.0 to 1.0

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var currentURL: URL?

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
    func load(url: URL) {
        cleanup()

        currentURL = url

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
        print("▶️ Playback started")
    }

    /// Pause playback
    func pause() {
        player?.pause()
        isPlaying = false
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
        seek(to: 0)
        print("✅ Playback finished")
    }
}

// MARK: - Convenience Methods

extension AudioPlayerService {
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
