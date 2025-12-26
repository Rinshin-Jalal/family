//
//  AudioLevelMonitor.swift
//  StoryRide
//
//  Monitors real-time microphone audio levels for speech-reactive waveforms
//

import Foundation
import AVFoundation
import Combine

// MARK: - Audio Level Monitor

@MainActor
class AudioLevelMonitor: ObservableObject {
    @Published var currentLevel: Float = 0.0
    @Published var recentLevels: [CGFloat] = Array(repeating: 0.1, count: 60)
    @Published var isMonitoring = false

    private var audioRecorder: AVAudioRecorder?
    private var levelTimer: Timer?
    private let sampleRate: TimeInterval = 0.05 // 20 samples per second

    init() {
        setupAudioSession()
    }

    // Note: Cleanup happens via stopMonitoring() which should be called explicitly
    // The view calling this is responsible for stopping monitoring when done

    // MARK: - Public Methods

    func startMonitoring() {
        guard !isMonitoring else { return }

        Task {
            do {
                let granted = await requestMicrophonePermission()
                guard granted else {
                    print("Microphone permission denied")
                    return
                }

                try setupRecorder()
                audioRecorder?.record()
                audioRecorder?.isMeteringEnabled = true
                isMonitoring = true
                startLevelTimer()
            } catch {
                print("Failed to start audio monitoring: \(error)")
            }
        }
    }

    func stopMonitoring() {
        levelTimer?.invalidate()
        levelTimer = nil
        audioRecorder?.stop()
        audioRecorder = nil
        isMonitoring = false

        // Reset levels
        currentLevel = 0.0
        recentLevels = Array(repeating: 0.1, count: 60)
    }

    // MARK: - Private Methods

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func setupRecorder() throws {
        // Create temp file for recording (we won't actually save it)
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "audio_level_monitor_\(UUID().uuidString).m4a"
        let audioURL = tempDir.appendingPathComponent(fileName)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]

        audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.prepareToRecord()
    }

    private func startLevelTimer() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: sampleRate, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateLevels()
            }
        }
    }

    private func updateLevels() {
        guard let recorder = audioRecorder, isMonitoring else { return }

        recorder.updateMeters()

        // Get average power level (in dB, typically -160 to 0)
        let averagePower = recorder.averagePower(forChannel: 0)

        // Normalize to 0.0 - 1.0 range
        // Speech typically ranges from -60 dB to 0 dB
        let normalizedLevel = normalizeAudioLevel(averagePower)

        currentLevel = normalizedLevel

        // Shift array and add new level
        recentLevels.removeFirst()
        recentLevels.append(CGFloat(normalizedLevel))
    }

    private func normalizeAudioLevel(_ level: Float) -> Float {
        // Clamp to reasonable speech range
        let minLevel: Float = -60.0
        let maxLevel: Float = 0.0
        let clampedLevel = max(minLevel, min(maxLevel, level))

        // Normalize to 0.0 - 1.0
        var normalized = (clampedLevel - minLevel) / (maxLevel - minLevel)

        // Apply curve for more visual responsiveness to speech
        // This makes quiet sounds more visible and loud sounds less extreme
        normalized = pow(normalized, 0.6)

        // Add minimum floor so bars are always slightly visible
        normalized = max(0.1, normalized)

        return normalized
    }
}

// MARK: - Preview Helper

extension AudioLevelMonitor {
    /// Creates a mock monitor with simulated levels for SwiftUI previews
    static var preview: AudioLevelMonitor {
        let monitor = AudioLevelMonitor()
        // Simulate some audio levels
        monitor.recentLevels = (0..<60).map { _ in CGFloat.random(in: 0.2...0.8) }
        return monitor
    }
}
