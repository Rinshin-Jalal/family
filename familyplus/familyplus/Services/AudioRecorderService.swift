//
//  AudioRecorderService.swift
//  StoryRide
//
//  Handles audio recording with AVAudioRecorder
//

import Foundation
import AVFoundation
import Combine

// MARK: - Audio Recorder Service

@MainActor
class AudioRecorderService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var currentRecordingURL: URL?

    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var startTime: Date?

    // MARK: - Public Methods

    /// Start recording audio to a file
    func startRecording() async throws {
        // Stop any existing recording
        stopRecording()

        // Request permission
        let granted = await requestMicrophonePermission()
        guard granted else {
            throw AudioRecorderError.permissionDenied
        }

        // Setup audio session
        try setupAudioSession()

        // Create recording URL
        let recordingURL = createRecordingURL()

        // Configure recorder settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 128000
        ]

        // Create and configure recorder
        audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.prepareToRecord()

        // Start recording
        guard audioRecorder?.record() == true else {
            throw AudioRecorderError.recordingFailed
        }

        // Update state
        isRecording = true
        currentRecordingURL = recordingURL
        startTime = Date()
        recordingDuration = 0

        // Start duration timer
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateDuration()
            }
        }

        print("✅ Recording started: \(recordingURL.lastPathComponent)")
    }

    /// Stop recording and return the file URL
    @discardableResult
    func stopRecording() -> URL? {
        guard isRecording else { return nil }

        // Stop timer
        recordingTimer?.invalidate()
        recordingTimer = nil

        // Stop recorder
        audioRecorder?.stop()

        // Update state
        isRecording = false

        let recordedURL = currentRecordingURL
        print("✅ Recording stopped: \(recordedURL?.lastPathComponent ?? "unknown")")

        return recordedURL
    }

    /// Cancel recording and delete the file
    func cancelRecording() {
        let recordingURL = currentRecordingURL
        stopRecording()

        // Delete the file
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
            print("🗑️ Recording cancelled and deleted")
        }

        currentRecordingURL = nil
        recordingDuration = 0
    }

    /// Get current audio power level for visualization (0.0 to 1.0)
    func getCurrentLevel() -> Float {
        guard let recorder = audioRecorder, isRecording else { return 0.0 }

        recorder.updateMeters()
        let averagePower = recorder.averagePower(forChannel: 0)

        // Normalize from dB range (-60 to 0) to 0.0 - 1.0
        let minLevel: Float = -60.0
        let maxLevel: Float = 0.0
        let clampedLevel = max(minLevel, min(maxLevel, averagePower))
        let normalized = (clampedLevel - minLevel) / (maxLevel - minLevel)

        return max(0.1, pow(normalized, 0.6))
    }

    // MARK: - Private Methods

    private func setupAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)
    }

    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func createRecordingURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let timestamp = Date().timeIntervalSince1970
        let fileName = "recording_\(Int(timestamp)).m4a"
        return documentsPath.appendingPathComponent(fileName)
    }

    private func updateDuration() {
        guard let startTime = startTime else { return }
        recordingDuration = Date().timeIntervalSince(startTime)
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecorderService: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            if !flag {
                print("⚠️ Recording finished unsuccessfully")
            }
        }
    }

    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            if let error = error {
                print("❌ Recording encoding error: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Errors

enum AudioRecorderError: LocalizedError {
    case permissionDenied
    case recordingFailed
    case noActiveRecording

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission was denied. Please enable it in Settings."
        case .recordingFailed:
            return "Failed to start recording. Please try again."
        case .noActiveRecording:
            return "No active recording to stop."
        }
    }
}
