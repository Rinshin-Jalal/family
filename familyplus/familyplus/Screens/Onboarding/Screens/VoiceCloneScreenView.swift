//
//  VoiceCloneScreenView.swift
//  StoryRd
//
//  Voice cloning magic - upload written story + voice sample
//

import SwiftUI
import UniformTypeIdentifiers

struct VoiceCloneScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var writtenText: String = ""
    @State private var hasVoiceSample: Bool = false
    @State private var isProcessing: Bool = false
    @State private var showDocumentPicker: Bool = false
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Text("🎭")
                        .font(.system(size: 60))
                    
                    Text("VOICE CLONING MAGIC")
                        .font(theme.headlineFont)
                        .foregroundColor(theme.textColor)
                    
                    Text("Upload a written story and a voice sample, then hear them read their own words!")
                        .font(theme.bodyFont)
                        .foregroundColor(theme.textColor.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)
                
                // Step 1: Written Story
                VStack(alignment: .leading, spacing: 12) {
                    Text("STEP 1: Upload Written Story")
                        .font(theme.bodyFont)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.accentColor)
                    
                    TextEditor(text: $writtenText)
                        .font(theme.bodyFont)
                        .foregroundColor(theme.textColor)
                        .frame(height: 200)
                        .padding(12)
                        .background(theme.cardBackgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(theme.accentColor.opacity(0.3), lineWidth: 1)
                        )
                    
                    HStack {
                        Button(action: { showDocumentPicker = true }) {
                            Label("Upload Document", systemImage: "doc.badge.plus")
                                .font(theme.bodyFont)
                        }
                        
                        Spacer()
                        
                        if !writtenText.isEmpty {
                            Text("\(writtenText.count) characters")
                                .font(theme.bodyFont)
                                .foregroundColor(theme.textColor.opacity(0.5))
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                // Divider
                HStack {
                    Rectangle()
                        .fill(theme.textColor.opacity(0.2))
                        .frame(height: 1)
                    Text("+")
                        .foregroundColor(theme.textColor.opacity(0.5))
                    Rectangle()
                        .fill(theme.textColor.opacity(0.2))
                        .frame(height: 1)
                }
                .padding(.horizontal, 24)
                
                // Step 2: Voice Sample
                VStack(alignment: .leading, spacing: 12) {
                    Text("STEP 2: Voice Sample (30 sec)")
                        .font(theme.bodyFont)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.accentColor)
                    
                    if hasVoiceSample {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Voice sample uploaded!")
                                .font(theme.bodyFont)
                                .foregroundColor(.green)
                            Spacer()
                            Button("Change") {
                                hasVoiceSample = false
                            }
                            .font(theme.bodyFont)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Button(action: { /* Record voice sample */ }) {
                            HStack {
                                Image(systemName: "mic.badge.plus")
                                Text("Record Voice Sample")
                            }
                            .font(theme.bodyFont)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(theme.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Text("Need 30 seconds of clear audio")
                            .font(theme.bodyFont)
                            .foregroundColor(theme.textColor.opacity(0.5))
                    }
                }
                .padding(.horizontal, 24)
                
                // Magic Result Preview
                VStack(spacing: 16) {
                    Text("THE MAGIC RESULT")
                        .font(theme.bodyFont)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                    
                    HStack(spacing: 20) {
                        // Before
                        VStack(spacing: 8) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("Written Story")
                                .font(theme.bodyFont)
                                .foregroundColor(.gray)
                        }
                        
                        Image(systemName: "arrow.right")
                            .foregroundColor(.purple)
                        
                        // After
                        VStack(spacing: 8) {
                            Image(systemName: "person.wave.2.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.purple)
                            Text("Their Voice Reading It!")
                                .font(theme.bodyFont)
                                .foregroundColor(.purple)
                        }
                    }
                }
                .padding()
                .background(Color.purple.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 24)
                
                // Example Quote
                VStack(spacing: 12) {
                    Text("\"October 15, 1985 - Dear Diary...\"")
                        .font(theme.bodyFont)
                        .foregroundColor(theme.textColor.opacity(0.8))
                        .italic()
                        .multilineTextAlignment(.center)
                    
                    Text("in Grandpa's voice")
                        .font(theme.bodyFont)
                        .foregroundColor(.purple)
                }
                .padding()
                .background(theme.cardBackgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 24)
                
                // Action Button
                Button(action: createVoiceClone) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "wand.and.stars")
                            Text("Create Voice Clone")
                        }
                    }
                    .font(theme.headlineFont)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        writtenText.isEmpty || !hasVoiceSample
                            ? theme.accentColor.opacity(0.5)
                            : Color.purple
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(writtenText.isEmpty || !hasVoiceSample || isProcessing)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .background(theme.backgroundColor)
        .fileImporter(
            isPresented: $showDocumentPicker,
            allowedContentTypes: [.pdf, .plainText, .data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    loadDocument(from: url)
                }
            case .failure:
                break
            }
        }
    }
    
    private func createVoiceClone() {
        isProcessing = true
        // Would call API to process voice clone
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isProcessing = false
            coordinator.goToNextStep()
        }
    }
    
    private func loadDocument(from url: URL) {
        // Would read and parse document
        writtenText = "Document loaded from \(url.lastPathComponent)"
    }
}

// MARK: - Preview

#Preview {
    VoiceCloneScreenView(coordinator: OnboardingCoordinator.preview)
        .themed(LightTheme())
}
