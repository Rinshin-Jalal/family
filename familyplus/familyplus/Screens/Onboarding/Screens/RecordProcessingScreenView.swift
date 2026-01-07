import SwiftUI
import Combine

struct RecordProcessingScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var currentStep = 0
    @State private var sparkleRotation: Double = 0
    
    private let processingSteps: [(icon: String, title: String, description: String)] = [
        ("waveform", "Transcribing Audio", "Converting speech to text..."),
        ("person.2.fill", "Identifying Speakers", "Recognizing who's talking..."),
        ("brain.head.profile", "Extracting Wisdom", "Finding life lessons and insights..."),
        ("tag.fill", "Adding Tags", "Categorizing emotions and topics...")
    ]
    
    let timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 32) {
                    ZStack {
                        Circle()
                            .stroke(theme.accentColor.opacity(0.2), lineWidth: 4)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(currentStep + 1) / CGFloat(processingSteps.count))
                            .stroke(theme.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                        
                        ZStack {
                            ForEach(0..<8) { i in
                                Image(systemName: "sparkle")
                                    .font(.system(size: 10))
                                    .foregroundColor(theme.accentColor.opacity(0.6))
                                    .offset(y: -45)
                                    .rotationEffect(.degrees(Double(i) * 45 + sparkleRotation))
                            }
                            
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(theme.accentColor)
                        }
                    }
                    .opacity(showContent ? 1 : 0)
                    .scaleEffect(showContent ? 1 : 0.5)
                    
                    VStack(spacing: 8) {
                        Text("AI Magic in Progress")
                            .font(theme.headlineFont)
                            .foregroundColor(theme.textColor)
                        
                        Text("This takes about 30 seconds")
                            .font(theme.bodyFont)
                            .foregroundColor(theme.secondaryTextColor)
                    }
                    .opacity(showContent ? 1 : 0)
                }
                
                Spacer().frame(height: 48)
                
                VStack(spacing: 12) {
                    ForEach(Array(processingSteps.enumerated()), id: \.offset) { index, step in
                        ProcessingStepRow(
                            icon: step.icon,
                            title: step.title,
                            description: step.description,
                            state: stepState(for: index)
                        )
                    }
                }
                .padding(.horizontal, 24)
                .opacity(showContent ? 1 : 0)
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
            
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                sparkleRotation = 360
            }
        }
        .onReceive(timer) { _ in
            if currentStep < processingSteps.count - 1 {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    currentStep += 1
                }
            } else {
                coordinator.goToStep(.recordReveal)
            }
        }
    }
    
    private func stepState(for index: Int) -> ProcessingStepState {
        if index < currentStep {
            return .completed
        } else if index == currentStep {
            return .active
        } else {
            return .pending
        }
    }
}

private enum ProcessingStepState {
    case pending, active, completed
}

private struct ProcessingStepRow: View {
    let icon: String
    let title: String
    let description: String
    let state: ProcessingStepState
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 44, height: 44)
                
                if state == .active {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else if state == .completed {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(theme.secondaryTextColor)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(state == .pending ? theme.secondaryTextColor : theme.textColor)
                
                if state == .active {
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(theme.accentColor)
                }
            }
            
            Spacer()
            
            if state == .completed {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
            }
        }
        .padding(14)
        .background(state == .active ? theme.accentColor.opacity(0.08) : theme.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(state == .active ? theme.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
    
    private var backgroundColor: Color {
        switch state {
        case .completed:
            return .green
        case .active:
            return theme.accentColor
        case .pending:
            return theme.secondaryTextColor.opacity(0.2)
        }
    }
}

#Preview {
    RecordProcessingScreenView(coordinator: .preview)
        .themed(LightTheme())
}
