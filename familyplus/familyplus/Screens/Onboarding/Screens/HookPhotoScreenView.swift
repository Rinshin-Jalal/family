import SwiftUI

struct HookPhotoScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var scanLineOffset: CGFloat = -150
    @State private var showExtractedText = false
    @State private var extractedTextOpacity: Double = 0
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                ZStack {
                    PhotoStack()
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 30)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .frame(width: 240, height: 180)
                            .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(red: 1, green: 0.98, blue: 0.94))
                                .frame(width: 220, height: 160)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HandwrittenLine(text: "Recipe: Nana's Apple Pie", width: 160)
                                HandwrittenLine(text: "2 cups flour, 1 tsp salt", width: 140)
                                HandwrittenLine(text: "6 apples, peeled & sliced", width: 150)
                                HandwrittenLine(text: "Secret: pinch of love ♡", width: 130)
                            }
                            .frame(width: 200, alignment: .leading)
                        }
                        
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        theme.accentColor.opacity(0),
                                        theme.accentColor.opacity(0.6),
                                        theme.accentColor.opacity(0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 240, height: 8)
                            .offset(y: scanLineOffset)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .opacity(showContent ? 1 : 0)
                    
                    if showExtractedText {
                        ExtractedTextBubble()
                            .offset(x: 100, y: -60)
                            .opacity(extractedTextOpacity)
                    }
                }
                .frame(height: 280)
                
                Spacer()
                    .frame(height: 40)
                
                VStack(spacing: 16) {
                    Text("Photos tell stories")
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundColor(theme.textColor)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                    
                    Text("Snap a photo of handwritten notes,\nrecipes, or letters — we'll do the rest")
                        .font(theme.bodyFont)
                        .foregroundColor(theme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                    .frame(height: 24)
                
                HStack(spacing: 24) {
                    MiniStat(value: "50+", label: "Languages")
                    MiniStat(value: "99%", label: "Accuracy")
                    MiniStat(value: "< 5s", label: "Scan time")
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                
                Spacer()
                
                OnboardingCTAButton(
                    title: "Continue",
                    action: { coordinator.goToNextStep() }
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    scanLineOffset = 150
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showExtractedText = true
                withAnimation(.easeOut(duration: 0.5)) {
                    extractedTextOpacity = 1
                }
            }
        }
    }
}

private struct PhotoStack: View {
    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .frame(width: 200, height: 150)
                    .shadow(color: .black.opacity(0.1), radius: 8)
                    .rotationEffect(.degrees(Double(index - 1) * 8))
                    .offset(x: CGFloat(index - 1) * 15, y: CGFloat(index) * -8)
            }
        }
        .offset(y: 20)
        .opacity(0.3)
    }
}

private struct HandwrittenLine: View {
    let text: String
    let width: CGFloat
    
    var body: some View {
        ZStack(alignment: .leading) {
            Path { path in
                path.move(to: CGPoint(x: 0, y: 10))
                for x in stride(from: 0, to: width, by: 4) {
                    let y = 10 + sin(Double(x) * 0.15) * 1.5
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(Color.gray.opacity(0.4), lineWidth: 0.5)
            
            Text(text)
                .font(.custom("Bradley Hand", size: 14))
                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.3))
        }
        .frame(width: width, height: 20)
    }
}

private struct ExtractedTextBubble: View {
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                Text("Text extracted!")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            
            Text("\"Nana's Apple Pie\"")
                .font(.caption2)
                .foregroundColor(theme.secondaryTextColor)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.cardBackgroundColor)
                .shadow(color: .black.opacity(0.1), radius: 10)
        )
    }
}

private struct MiniStat: View {
    let value: String
    let label: String
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .foregroundColor(theme.accentColor)
            Text(label)
                .font(.caption2)
                .foregroundColor(theme.secondaryTextColor)
        }
    }
}

#Preview {
    HookPhotoScreenView(coordinator: .preview)
        .themed(LightTheme())
}
