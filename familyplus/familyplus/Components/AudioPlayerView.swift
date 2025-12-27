//
//  AudioPlayerView.swift
//  StoryRide
//
//  Reusable audio player component with playback controls
//

import SwiftUI

// MARK: - Audio Player View

struct AudioPlayerView: View {
    @ObservedObject private var player = AudioPlayerService.shared
    @Environment(\.theme) var theme

    let audioURL: String // Remote URL from Supabase Storage
    let storytellerName: String
    let storytellerColor: Color

    var body: some View {
        VStack(spacing: 16) {
            // Waveform visualization
            AudioWaveformView(
                isPlaying: player.isPlaying,
                color: storytellerColor,
                barCount: 40
            )
            .frame(height: 60)

            // Progress bar
            VStack(spacing: 8) {
                // Playback slider
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Track
                        Capsule()
                            .fill(storytellerColor.opacity(0.2))
                            .frame(height: 4)

                        // Progress
                        Capsule()
                            .fill(storytellerColor)
                            .frame(width: geometry.size.width * player.playbackProgress, height: 4)
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let progress = max(0, min(1, value.location.x / geometry.size.width))
                                player.seekToProgress(progress)
                            }
                    )
                }
                .frame(height: 4)

                // Time labels
                HStack {
                    Text(player.formattedCurrentTime)
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                        .monospacedDigit()

                    Spacer()

                    Text(player.formattedDuration)
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                        .monospacedDigit()
                }
            }

            // Playback controls
            HStack(spacing: 32) {
                // Skip back 15s
                Button(action: {
                    player.seek(to: max(0, player.currentTime - 15))
                }) {
                    Image(systemName: "gobackward.15")
                        .font(.system(size: 24))
                        .foregroundColor(storytellerColor)
                }
                .disabled(player.currentTime < 15)

                // Play/Pause button
                Button(action: {
                    player.togglePlayback()
                }) {
                    ZStack {
                        Circle()
                            .fill(storytellerColor)
                            .frame(width: 64, height: 64)

                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .offset(x: player.isPlaying ? 0 : 2) // Visual alignment for play icon
                    }
                }
                .shadow(color: storytellerColor.opacity(0.3), radius: 8, y: 4)

                // Skip forward 15s
                Button(action: {
                    player.seek(to: min(player.duration, player.currentTime + 15))
                }) {
                    Image(systemName: "goforward.15")
                        .font(.system(size: 24))
                        .foregroundColor(storytellerColor)
                }
                .disabled(player.currentTime + 15 > player.duration)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.cardBackgroundColor)
        )
        .onAppear {
            loadAudio()
        }
        .onDisappear {
            player.cleanup()
        }
    }

    private func loadAudio() {
        guard let url = URL(string: audioURL) else {
            print("❌ Invalid audio URL: \(audioURL)")
            return
        }

        // For remote URLs, we need to download first or use AVPlayer with remote URL
        // AVPlayer can stream remote URLs directly
        player.load(url: url)
    }
}

// MARK: - Compact Audio Player (for lists)

struct CompactAudioPlayerView: View {
    @ObservedObject private var player = AudioPlayerService.shared
    @Environment(\.theme) var theme

    let audioURL: String
    let storytellerColor: Color
    let onPlaybackStateChanged: ((Bool) -> Void)? // Callback when play/pause changes

    var body: some View {
        HStack(spacing: 16) {
            // Play/Pause button
            Button(action: {
                player.togglePlayback()
                onPlaybackStateChanged?(player.isPlaying)
            }) {
                ZStack {
                    Circle()
                        .fill(storytellerColor)
                        .frame(width: 44, height: 44)

                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .offset(x: player.isPlaying ? 0 : 2)
                }
            }
            .shadow(color: storytellerColor.opacity(0.3), radius: 4, y: 2)

            VStack(alignment: .leading, spacing: 4) {
                // Mini waveform
                HStack(spacing: 1) {
                    ForEach(0..<20, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(storytellerColor.opacity(player.isPlaying ? 1.0 : 0.6))
                            .frame(width: 2, height: CGFloat.random(in: 4...16))
                    }
                }
                .frame(height: 20)

                // Progress
                HStack {
                    Text(player.formattedCurrentTime)
                        .font(.caption2)
                        .foregroundColor(theme.secondaryTextColor)
                        .monospacedDigit()

                    Text("•")
                        .font(.caption2)
                        .foregroundColor(theme.secondaryTextColor.opacity(0.5))

                    Text(player.formattedDuration)
                        .font(.caption2)
                        .foregroundColor(theme.secondaryTextColor.opacity(0.7))
                        .monospacedDigit()
                }
            }
        }
        .onAppear {
            if let url = URL(string: audioURL) {
                player.load(url: url)
            }
        }
        .onDisappear {
            player.cleanup()
        }
    }
}

// MARK: - Preview

struct AudioPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AudioPlayerView(
                audioURL: "https://example.com/audio.m4a",
                storytellerName: "Grandma",
                storytellerColor: .storytellerOrange
            )
            .padding()

            CompactAudioPlayerView(
                audioURL: "https://example.com/audio.m4a",
                storytellerColor: .storytellerBlue,
                onPlaybackStateChanged: nil
            )
            .padding()
        }
        .themed(ParentTheme())
    }
}
