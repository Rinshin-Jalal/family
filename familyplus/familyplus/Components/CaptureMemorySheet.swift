//
//  CaptureMemorySheet.swift
//  StoryRide
//
//  Complete frictionless story capture with 4 input methods
//

import SwiftUI
import UniformTypeIdentifiers
import PDFKit
import Combine

// Import Services for APIService and PromptData

struct CaptureMemorySheet: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    
    var initialPrompt: PromptData? = nil
    var initialMode: InputMode = .recording
    var storyId: UUID? = nil
    var replyToResponseId: String? = nil  // For threaded replies
    var replyToName: String? = nil  // Name of person being replied to
    var replyToText: String? = nil  // Preview of message being replied to
    var hidePromptSection: Bool = false  // Hide prompt when replying
    
    // Prompt state
    @State private var selectedPrompt: PromptData?
    @State private var customPromptText = ""
    @State private var isLoadingPrompts = false
    
    // Input mode
    @State private var inputMode: InputMode = .recording
    
    // Recording state
    @StateObject private var audioRecorder = AudioRecorderService()
    @State private var recordingVisualLevel: Float = 0
    @State private var recordingTimer: Timer?
    
    // Audio upload state
    @State private var showAudioPicker = false
    @State private var selectedAudioFile: URL?
    @State private var selectedAudioFileName: String?
    
    // Document upload state
    @State private var showDocumentPicker = false
    @State private var selectedDocument: URL?
    @State private var selectedDocumentName: String?
    @State private var extractedText: String?
    @State private var isExtracting = false
    
    // Image upload state
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    
    // Text input state
    @State private var memoryText = ""
    
    // Upload state
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0
    @State private var uploadError: String?
    @State private var uploadSuccess = false
    
    @Namespace private var modeNamespace

    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Reply Context (when replying to someone)
                        if let replyName = replyToName {
                            replyContextSection(name: replyName, text: replyToText)
                        }
                        
                        // Prompt Hero Section (hide when replying)
                        if !hidePromptSection {
                            promptHeroSection
                        }
                        
                        // Mode Selector
                        inputModeSelector
                        
                        // Main Input Area
                        VStack {
                            inputSection
                        }
                        .padding(24)
                        .background(theme.role == .light ? Color.white : theme.cardBackgroundColor)
                        .cornerRadius(24)
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: inputMode)
                    }
                    .padding(.horizontal, theme.screenPadding)
                    .padding(.bottom, 40)
                    .padding(.top, 10)
                }
            }
        }
        .background(theme.backgroundColor)
        .presentationDragIndicator(.visible)
        .fileImporter(
            isPresented: $showAudioPicker,
            allowedContentTypes: [.audio, .mpeg4Audio, .mp3],
            allowsMultipleSelection: false
        ) { result in
            handleAudioFileSelection(result)
        }
        .fileImporter(
            isPresented: $showDocumentPicker,
            allowedContentTypes: [.pdf, .plainText, .rtf],
            allowsMultipleSelection: false
        ) { result in
            handleDocumentFileSelection(result)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(
                source: .photoLibrary,
                selectionLimit: 1,
                onImagesSelected: { images in
                    if let first = images.first {
                        selectedImage = first
                    }
                    showImagePicker = false
                },
                onCancel: {
                    showImagePicker = false
                }
            )
        }
        .alert("Something went wrong", isPresented: .constant(uploadError != nil), actions: {
            Button("I understand") { uploadError = nil }
        }, message: {
            Text(uploadError ?? "")
        })
        .alert("Memory Captured", isPresented: $uploadSuccess, actions: {
            Button("Perfect") {
                dismiss()
            }
        }, message: {
            Text("Your family story has been safely tucked away.")
        })
        .onAppear {
            if let initialPrompt = initialPrompt {
                selectedPrompt = initialPrompt
            }
            inputMode = initialMode
        }
        .onDisappear {
            // Cleanup
            if audioRecorder.isRecording {
                audioRecorder.cancelRecording()
            }
            recordingTimer?.invalidate()
        }
    }

    // MARK: - Components

    private var header: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2.5)
                .fill(theme.secondaryTextColor.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.vertical, 12)
            
            HStack {
                Text(replyToName != nil ? "Add Your Reply" : "Capture Memory")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(theme.textColor)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(theme.secondaryTextColor.opacity(0.5))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
    }

    // Reply Context Section
    private func replyContextSection(name: String, text: String?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "arrowshape.turn.up.left.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.accentColor)
                
                Text("Replying to \(name)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(theme.textColor)
            }
            
            if let text = text, !text.isEmpty {
                Text(text)
                    .font(.system(size: 14))
                    .foregroundColor(theme.secondaryTextColor)
                    .lineLimit(3)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(theme.secondaryTextColor.opacity(0.08))
                    .cornerRadius(12)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.accentColor.opacity(0.08))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.accentColor.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var promptHeroSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("STORY STARTER", systemImage: "sparkles")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(theme.accentColor)
                .tracking(1.5)
            
            if let prompt = selectedPrompt {
                Text(prompt.text)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(theme.textColor)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                TextField("What's on your mind?", text: $customPromptText, axis: .vertical)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(theme.textColor)
                    .lineLimit(3)
                    .onChange(of: customPromptText) { _, _ in
                        if !customPromptText.isEmpty { selectedPrompt = nil }
                    }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.role == .light ? Color.white : theme.cardBackgroundColor)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    private var inputModeSelector: some View {
        HStack(spacing: 8) {
            ForEach([InputMode.recording, .audioUpload, .documentUpload, .imageUpload, .typing], id: \.self) { mode in
                Button(action: {
                    if inputMode == .recording && audioRecorder.isRecording {
                        audioRecorder.stopRecording()
                    }
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        inputMode = mode
                    }
                    HapticManager.shared.selection()
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 18))
                        Text(mode.title)
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(inputMode == mode ? theme.accentColor : theme.secondaryTextColor.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background {
                        if inputMode == mode {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(theme.accentColor.opacity(0.1))
                        }
                    }
                }
            }
        }
        .padding(8)
        .background(theme.role == .light ? Color.white : theme.cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }

    @ViewBuilder
    private var inputSection: some View {
        switch inputMode {
        case .recording:
            recordingSection
        case .audioUpload:
            audioUploadSection
        case .documentUpload:
            documentUploadSection
        case .imageUpload:
            imageUploadSection
        case .typing:
            typingSection
        }
    }
    
    private var imageUploadSection: some View {
        VStack(spacing: 16) {
            if let image = selectedImage {
                VStack(spacing: 16) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .cornerRadius(16)
                        .clipped()
                    
                    Button(action: { selectedImage = nil }) {
                        Text("Remove Photo")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.red)
                    }
                    
                    Button(action: uploadImage) {
                        HStack(spacing: 12) {
                            if isUploading {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "arrow.up.circle.fill")
                            }
                            Text(isUploading ? "Uploading..." : "Save Photo Memory")
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(theme.accentColor)
                        .cornerRadius(16)
                        .shadow(color: theme.accentColor.opacity(0.3), radius: 8, y: 4)
                    }
                    .disabled(isUploading)
                }
            } else {
                Button(action: { showImagePicker = true }) {
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(theme.accentColor.opacity(0.1))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "camera.fill")
                                .font(.system(size: 32))
                                .foregroundColor(theme.accentColor)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Share a Photo")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(theme.textColor)
                            
                            Text("Add a visual memory to your family library")
                                .font(.system(size: 14))
                                .foregroundColor(theme.secondaryTextColor)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.vertical, 40)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var recordingSection: some View {
        VStack(spacing: 32) {
            // Visual Waveform (simplified)
            HStack(spacing: 4) {
                ForEach(0..<12) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.accentColor)
                        .frame(width: 4, height: audioRecorder.isRecording ? CGFloat.random(in: 10...60) : 4)
                        .animation(.easeInOut(duration: 0.15), value: recordingVisualLevel)
                }
            }
            .frame(height: 60)
            
            Button(action: toggleRecording) {
                ZStack {
                    Circle()
                        .fill(audioRecorder.isRecording ? Color.red : theme.accentColor)
                        .frame(width: 80, height: 80)
                        .shadow(color: (audioRecorder.isRecording ? Color.red : theme.accentColor).opacity(0.3), radius: 10, y: 5)
                    
                    Image(systemName: audioRecorder.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            VStack(spacing: 8) {
                Text(durationText)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textColor)
                    .monospacedDigit()
                
                Text(audioRecorder.isRecording ? "Listening..." : "Tap to Speak")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(theme.secondaryTextColor)
            }
            
            if audioRecorder.recordingDuration > 0 && !audioRecorder.isRecording {
                Button(action: uploadRecording) {
                    HStack {
                        if isUploading { ProgressView().tint(.white) }
                        else { Image(systemName: "paperplane.fill") }
                        Text(isUploading ? "SENT" : "SEND MEMORY")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(theme.accentColor)
                    .cornerRadius(16)
                    .shadow(color: theme.accentColor.opacity(0.3), radius: 8, y: 4)
                }
            }
        }
    }
    
    private var audioUploadSection: some View {
        VStack(spacing: 16) {
            if let fileName = selectedAudioFileName {
                // Selected file display
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(theme.accentColor.opacity(0.15))
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "waveform")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(theme.accentColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(fileName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.textColor)
                            .lineLimit(1)
                        
                        Text("Ready to upload")
                            .font(.system(size: 13))
                            .foregroundColor(theme.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        selectedAudioFile = nil
                        selectedAudioFileName = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(theme.secondaryTextColor.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: theme.cardRadius)
                        .fill(theme.cardBackgroundColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.cardRadius)
                                .stroke(theme.accentColor.opacity(0.2), lineWidth: 1.5)
                        )
                )
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                
                // Upload button
                Button(action: uploadAudioFile) {
                    HStack(spacing: 12) {
                        if isUploading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 20))
                        }
                        Text(isUploading ? "Uploading..." : "Upload Audio")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.accentColor.gradient)
                    )
                    .shadow(color: theme.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .disabled(isUploading || selectedAudioFile == nil)
            } else {
                // Upload button
                Button(action: { showAudioPicker = true }) {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(theme.accentColor.opacity(0.15))
                                .frame(width: 64, height: 64)
                            
                            Image(systemName: "folder.fill")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(theme.accentColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Choose Audio File")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(theme.textColor)
                            
                            Text("M4A, MP3, WAV")
                                .font(.system(size: 14))
                                .foregroundColor(theme.secondaryTextColor)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.secondaryTextColor.opacity(0.5))
                    }
                    .padding(20)
                }
                .buttonStyle(.plain)
                .disabled(isUploading)
                .background(
                    RoundedRectangle(cornerRadius: theme.cardRadius)
                        .fill(theme.cardBackgroundColor)
                )
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
            }
        }
    }
    
    private var documentUploadSection: some View {
        VStack(spacing: 16) {
            if let docName = selectedDocumentName {
                // Selected document display
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(theme.accentColor.opacity(0.15))
                                .frame(width: 56, height: 56)
                            
                            if isExtracting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: theme.accentColor))
                            } else {
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(theme.accentColor)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(docName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(theme.textColor)
                                .lineLimit(1)
                            
                            Text(isExtracting ? "Extracting text..." : "Document ready")
                                .font(.system(size: 13))
                                .foregroundColor(theme.secondaryTextColor)
                        }
                        
                        Spacer()
                        
                        if !isExtracting {
                            Button(action: {
                                selectedDocument = nil
                                selectedDocumentName = nil
                                extractedText = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(theme.secondaryTextColor.opacity(0.5))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: theme.cardRadius)
                            .fill(theme.cardBackgroundColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: theme.cardRadius)
                                    .stroke(theme.accentColor.opacity(0.2), lineWidth: 1.5)
                            )
                    )
                    .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                    
                    // Extracted text preview
                    if let text = extractedText {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "text.alignleft")
                                    .font(.system(size: 14))
                                    .foregroundColor(theme.accentColor)
                                Text("Extracted Text (\(text.count) characters)")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(theme.secondaryTextColor)
                            }
                            
                            Text(text)
                                .font(.system(size: 14))
                                .foregroundColor(theme.textColor)
                                .lineLimit(4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(theme.backgroundColor)
                        )
                        
                        // Save button
                        Button(action: uploadDocument) {
                            HStack(spacing: 12) {
                                if isUploading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.system(size: 20))
                                }
                                Text(isUploading ? "Uploading..." : "Save Document")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(theme.accentColor.gradient)
                            )
                            .shadow(color: theme.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        .disabled(isUploading)
                    }
                }
            } else {
                // Upload button
                Button(action: { showDocumentPicker = true }) {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(theme.accentColor.opacity(0.15))
                                .frame(width: 64, height: 64)
                            
                            Image(systemName: "doc.fill")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(theme.accentColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Choose Document")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(theme.textColor)
                            
                            Text("PDF, TXT, RTF")
                                .font(.system(size: 14))
                                .foregroundColor(theme.secondaryTextColor)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.secondaryTextColor.opacity(0.5))
                    }
                    .padding(20)
                }
                .buttonStyle(.plain)
                .disabled(isUploading)
                .background(
                    RoundedRectangle(cornerRadius: theme.cardRadius)
                        .fill(theme.cardBackgroundColor)
                )
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
            }
        }
    }
    
    private var typingSection: some View {
        VStack(spacing: 20) {
            ZStack(alignment: .topLeading) {
                if memoryText.isEmpty {
                    Text("Begin your story...")
                        .font(.system(size: 18))
                        .foregroundColor(theme.secondaryTextColor.opacity(0.4))
                        .padding(.top, 12)
                        .padding(.leading, 4)
                }
                
                TextEditor(text: $memoryText)
                    .font(.system(size: 18))
                    .foregroundColor(theme.textColor)
                    .frame(minHeight: 200)
                    .scrollContentBackground(.hidden)
            }
            
            HStack {
                Text("\(memoryText.count) characters")
                    .font(.system(size: 12))
                    .foregroundColor(theme.secondaryTextColor)
                
                Spacer()
                
                if !memoryText.isEmpty {
                    Button(action: uploadText) {
                        Text(isUploading ? "SAVING..." : "SAVE MEMORY")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(theme.accentColor)
                            .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private var durationText: String {
        let minutes = Int(audioRecorder.recordingDuration) / 60
        let seconds = Int(audioRecorder.recordingDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func hasValidPrompt() -> Bool {
        return selectedPrompt != nil || !customPromptText.isEmpty
    }
    
    private func getPromptId() -> UUID {
        if let prompt = selectedPrompt {
            return UUID(uuidString: prompt.id) ?? UUID()
        }
        // Create a temporary prompt for custom text
        return UUID()
    }
    
    // MARK: - Actions
    
    private func toggleRecording() {
        Task { @MainActor in
            if audioRecorder.isRecording {
                // Stop recording
                audioRecorder.stopRecording()
                recordingTimer?.invalidate()
                recordingTimer = nil
            } else {
                // Start recording
                do {
                    try await audioRecorder.startRecording()
                    // Start visualizer timer
                    recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                        recordingVisualLevel = audioRecorder.getCurrentLevel()
                    }
                } catch {
                    uploadError = "Failed to start recording: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func uploadRecording() {
        guard let audioURL = audioRecorder.currentRecordingURL else {
            uploadError = "No recording found"
            return
        }
        
        Task { @MainActor in
            isUploading = true
            uploadProgress = 0
            
            do {
                let audioData = try Data(contentsOf: audioURL)
                let filename = audioURL.lastPathComponent
                let promptId = getPromptId()
                
                _ = try await APIService.shared.uploadResponse(
                    promptId: promptId,
                    storyId: storyId,
                    audioData: audioData,
                    filename: filename,
                    source: "app_audio",
                    replyToResponseId: replyToResponseId
                )
                
                uploadProgress = 1.0
                uploadSuccess = true
            } catch {
                uploadError = "Upload failed: \(error.localizedDescription)"
            }
            
            isUploading = false
        }
    }
    
    private func handleAudioFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                // Start accessing the security-scoped resource
                guard url.startAccessingSecurityScopedResource() else {
                    uploadError = "Cannot access this file"
                    return
                }
                
                selectedAudioFile = url
                selectedAudioFileName = url.lastPathComponent
                
                // Schedule cleanup
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    url.stopAccessingSecurityScopedResource()
                }
            }
        case .failure(let error):
            uploadError = "Failed to select file: \(error.localizedDescription)"
        }
    }
    
    private func uploadAudioFile() {
        guard let audioURL = selectedAudioFile else {
            uploadError = "No audio file selected"
            return
        }
        
        Task { @MainActor in
            isUploading = true
            uploadProgress = 0
            
            do {
                let audioData = try Data(contentsOf: audioURL)
                let filename = audioURL.lastPathComponent
                let promptId = getPromptId()
                
                _ = try await APIService.shared.uploadResponse(
                    promptId: promptId,
                    storyId: storyId,
                    audioData: audioData,
                    filename: filename,
                    source: "app_audio",
                    replyToResponseId: replyToResponseId
                )
                
                uploadProgress = 1.0
                uploadSuccess = true
            } catch {
                uploadError = "Upload failed: \(error.localizedDescription)"
            }
            
            isUploading = false
        }
    }
    
    private func handleDocumentFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                guard url.startAccessingSecurityScopedResource() else {
                    uploadError = "Cannot access this file"
                    return
                }
                
                selectedDocument = url
                selectedDocumentName = url.lastPathComponent
                
                // Start text extraction
                extractTextFromDocument(url: url)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    url.stopAccessingSecurityScopedResource()
                }
            }
        case .failure(let error):
            uploadError = "Failed to select document: \(error.localizedDescription)"
        }
    }
    
    private func extractTextFromDocument(url: URL) {
        isExtracting = true
        extractedText = nil
        
        Task { @MainActor in
            do {
                let fileExtension = url.pathExtension.lowercased()
                
                if fileExtension == "pdf" {
                    // Extract from PDF
                    if let pdfDocument = PDFDocument(url: url) {
                        var fullText = ""
                        let pageCount = pdfDocument.pageCount
                        
                        for i in 0..<pageCount {
                            if let page = pdfDocument.page(at: i) {
                                if let pageText = page.string {
                                    fullText += pageText + "\n\n"
                                }
                            }
                        }
                        
                        extractedText = fullText.trimmingCharacters(in: .whitespacesAndNewlines)
                    } else {
                        uploadError = "Could not read PDF document"
                    }
                } else {
                    // Extract from text files
                    let text = try String(contentsOf: url, encoding: .utf8)
                    extractedText = text
                }
            } catch {
                uploadError = "Failed to extract text: \(error.localizedDescription)"
            }
            
            isExtracting = false
        }
    }
    
    private func uploadDocument() {
        guard let text = extractedText, !text.isEmpty else {
            uploadError = "No text extracted from document"
            return
        }
        
        Task { @MainActor in
            isUploading = true
            uploadProgress = 0
            
            do {
                // Convert text to audio using text-to-speech or upload as text
                // For now, upload as text response
                let textData = text.data(using: .utf8)!
                let filename = "extracted_\(UUID().uuidString).txt"
                let promptId = getPromptId()
                
                _ = try await APIService.shared.uploadResponse(
                    promptId: promptId,
                    storyId: storyId,
                    audioData: textData,
                    filename: filename,
                    source: "app_text"
                )
                
                uploadProgress = 1.0
                uploadSuccess = true
            } catch {
                uploadError = "Upload failed: \(error.localizedDescription)"
            }
            
            isUploading = false
        }
    }
    
    private func uploadImage() {
        guard let image = selectedImage else {
            uploadError = "No image selected"
            return
        }
        
        Task { @MainActor in
            isUploading = true
            uploadProgress = 0
            
            do {
                guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                    throw NSError(domain: "ImageConversion", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
                }
                
                let filename = "photo_\(UUID().uuidString).jpg"
                let promptId = getPromptId()
                
                // Using uploadResponse but with image data
                // Backend currently expects 'audio' but we'll send it as generic response for now
                // or ideally we would use a dedicated image endpoint
                _ = try await APIService.shared.uploadResponse(
                    promptId: promptId,
                    storyId: storyId,
                    audioData: imageData,
                    filename: filename,
                    source: "app_image"
                )
                
                uploadProgress = 1.0
                uploadSuccess = true
            } catch {
                uploadError = "Upload failed: \(error.localizedDescription)"
            }
            
            isUploading = false
        }
    }
    
    private func uploadText() {
        guard !memoryText.isEmpty else {
            uploadError = "Please enter some text"
            return
        }
        
        Task { @MainActor in
            isUploading = true
            uploadProgress = 0
            
            do {
                let textData = memoryText.data(using: .utf8)!
                let filename = "text_\(UUID().uuidString).txt"
                let promptId = getPromptId()
                
                _ = try await APIService.shared.uploadResponse(
                    promptId: promptId,
                    storyId: storyId,
                    audioData: textData,
                    filename: filename,
                    source: "app_text"
                )
                
                uploadProgress = 1.0
                uploadSuccess = true
            } catch {
                uploadError = "Upload failed: \(error.localizedDescription)"
            }
            
            isUploading = false
        }
    }
}

// MARK: - Preview

struct CaptureMemorySheet_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CaptureMemorySheet()
                .themed(DarkTheme())
                .previewDisplayName("Dark Mode")
            
            CaptureMemorySheet()
                .themed(LightTheme())
                .previewDisplayName("Light Mode")
        }
    }
}
