import SwiftUI
import Combine

struct RecordCallScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var isRecording = false
    @State private var duration: TimeInterval = 0
    @State private var showContent = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var waveformHeights: [CGFloat] = Array(repeating: 0.3, count: 40)
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let waveformTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 24) {
                    if let question = coordinator.recordingState.question {
                        Text("\"\(question.text)\"")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(theme.textColor.opacity(0.8))
                            .italic()
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .opacity(showContent ? 1 : 0)
                    }
                    
                    ZStack {
                        if isRecording {
                            Circle()
                                .fill(Color.red.opacity(0.1))
                                .frame(width: 200, height: 200)
                                .scaleEffect(pulseScale)
                            
                            Circle()
                                .fill(Color.red.opacity(0.15))
                                .frame(width: 160, height: 160)
                                .scaleEffect(pulseScale * 0.95)
                        }
                        
                        Circle()
                            .fill(isRecording ? Color.red : theme.accentColor)
                            .frame(width: 120, height: 120)
                            .shadow(color: (isRecording ? Color.red : theme.accentColor).opacity(0.3), radius: 20, y: 10)
                        
                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 44, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if isRecording {
                                coordinator.stopRecording()
                            } else {
                                coordinator.startRecording()
                            }
                            isRecording.toggle()
                        }
                    }
                    .opacity(showContent ? 1 : 0)
                    .scaleEffect(showContent ? 1 : 0.5)
                    
                    if isRecording {
                        HStack(spacing: 2) {
                            ForEach(0..<40, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.red.opacity(0.7))
                                    .frame(width: 4, height: max(4, waveformHeights[index] * 40))
                            }
                        }
                        .frame(height: 50)
                        .padding(.horizontal, 40)
                        
                        Text(formatDuration(duration))
                            .font(.system(size: 48, weight: .light, design: .monospaced))
                            .foregroundColor(theme.textColor)
                        
                        Text("Recording...")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.red)
                    } else {
                        Text("Tap to Start")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(theme.textColor)
                        
                        Text("Share your story in your own words")
                            .font(.system(size: 15))
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }
                .opacity(showContent ? 1 : 0)
                
                Spacer()
                
                if !isRecording {
                    VStack(spacing: 16) {
                        Button(action: {
                            Task { await coordinator.uploadExistingAudio() }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Upload Existing Audio")
                            }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(theme.accentColor)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 24)
                            .background(theme.accentColor.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.bottom, 40)
                    .opacity(showContent ? 1 : 0)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
        .onReceive(timer) { _ in
            if isRecording {
                duration += 1
            }
        }
        .onReceive(waveformTimer) { _ in
            if isRecording {
                withAnimation(.easeInOut(duration: 0.1)) {
                    waveformHeights = (0..<40).map { _ in CGFloat.random(in: 0.2...1.0) }
                    pulseScale = CGFloat.random(in: 1.0...1.15)
                }
            }
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

#Preview {
    RecordCallScreenView(coordinator: .preview)
        .themed(LightTheme())
}
