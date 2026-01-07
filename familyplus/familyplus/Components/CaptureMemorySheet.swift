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
import Foundation

// MARK: - Input Mode

enum InputMode {
    case recording
    case audioUpload
    case documentUpload
    case typing
    
    var icon: String {
        switch self {
        case .recording: return "mic.fill"
        case .audioUpload: return "folder.fill"
        case .documentUpload: return "doc.fill"
        case .typing: return "text.bubble.fill"
        }
    }
    
    var title: String {
        switch self {
        case .recording: return "Record"
        case .audioUpload: return "Audio"
        case .documentUpload: return "Document"
        case .typing: return "Type"
        }
    }
}

// MARK: - Capture Memory Sheet

struct CaptureMemorySheet: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    
    var initialPrompt: PromptData? = nil
    var storyId: UUID? = nil
    
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
    
    // Text input state
    @State private var memoryText = ""
    
    // Upload state
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0
    @State private var uploadError: String?
    @State private var uploadSuccess = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            ScrollView {
                VStack(spacing: 24) {
                    // Prompt selection
                    promptSection
                    
                    // Input mode selector (4 buttons)
                    inputModeSelector
                    
                    // Dynamic input section based on mode
                    inputSection
                }
                .padding(.horizontal, theme.screenPadding)
                .padding(.bottom, 20)
            }
        }
        .background(theme.backgroundColor)
        .presentationDetents([.medium, .large])
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
        .alert("Upload Error", isPresented: .constant(uploadError != nil), actions: {
            Button("OK") { uploadError = nil }
        }, message: {
            Text(uploadError ?? "")
        })
        .alert("Success!", isPresented: $uploadSuccess, actions: {
            Button("OK") {
                dismiss()
            }
        }, message: {
            Text("Your memory has been saved!")
        })
        .onAppear {
            if let initialPrompt = initialPrompt {
                selectedPrompt = initialPrompt
            }
        }
        .onDisappear {
            // Cleanup
            if audioRecorder.isRecording {
                audioRecorder.cancelRecording()
            }
            recordingTimer?.invalidate()
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Text("Share a Memory")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(theme.textColor)
            
            Spacer()
            
            Button("Cancel") {
                if audioRecorder.isRecording {
                    audioRecorder.cancelRecording()
                }
                dismiss()
            }
            .foregroundColor(theme.accentColor)
            .font(.system(size: 17, weight: .semibold))
        }
        .padding(.horizontal, theme.screenPadding)
        .padding(.vertical, 16)
        .background(theme.backgroundColor)
    }
    
    // MARK: - Prompt Section
    
    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Prompt")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(theme.textColor)
            
            if let prompt = selectedPrompt {
                // Selected prompt display
                HStack {
                    Text(prompt.text)
                        .font(.system(size: 16))
                        .foregroundColor(theme.textColor)
                    Spacer()
                    Button("Change") {
                        selectedPrompt = nil
                        customPromptText = ""
                    }
                    .font(.system(size: 15))
                    .foregroundColor(theme.accentColor)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.cardBackgroundColor)
                )
            }
            
            // Custom prompt input
            TextField("Type a prompt or question...", text: $customPromptText)
                .textFieldStyle(.plain)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.cardBackgroundColor)
                )
                .onChange(of: customPromptText) { _, _ in
                    if !customPromptText.isEmpty {
                        selectedPrompt = nil
                    }
                }
        }
    }
    
    // MARK: - Input Mode Selector
    
    private var inputModeSelector: some View {
        HStack(spacing: 4) {
            ForEach([InputMode.recording, .audioUpload, .documentUpload, .typing], id: \.self) { mode in
                Button(action: {
                    // Stop recording if switching away from recording mode
                    if inputMode == .recording && audioRecorder.isRecording {
                        audioRecorder.stopRecording()
                    }
                    inputMode = mode
                }) {
                    Text(mode.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(inputMode == mode ? .white : theme.accentColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(inputMode == mode ? theme.accentColor : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.cardBackgroundColor)
        )
    }
    
    // MARK: - Input Section
    
    @ViewBuilder
    private var inputSection: some View {
        switch inputMode {
        case .recording:
            recordingSection
        case .audioUpload:
            audioUploadSection
        case .documentUpload:
            documentUploadSection
        case .typing:
            typingSection
        }
    }
    
    // MARK: - Recording Section
    
    private var recordingSection: some View {
        VStack(spacing: 16) {
            // Record button
            Button(action: toggleRecording) {
                Image(systemName: audioRecorder.isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 80, height: 80)
                    .background(
                        Circle()
                            .fill(audioRecorder.isRecording ? Color.red : theme.accentColor)
                    )
            }
            .buttonStyle(.plain)
            
            // Duration
            Text(durationText)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(theme.textColor)
            
            // Status text
            Text(audioRecorder.isRecording ? "Recording..." : audioRecorder.recordingDuration > 0 ? "Recording complete" : "Tap to record")
                .font(.system(size: 14))
                .foregroundColor(theme.secondaryTextColor)
            
            // Save button (only when has recording)
            if audioRecorder.recordingDuration > 0 && !audioRecorder.isRecording {
                saveRecordingButton
            }
            
            // Upload progress
            if isUploading {
                uploadProgressView
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackgroundColor)
        )
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            if audioRecorder.isRecording {
                recordingVisualLevel = audioRecorder.getCurrentLevel()
            }
        }
    }
    
    private var saveRecordingButton: some View {
        Button(action: uploadRecording) {
            HStack(spacing: 8) {
                if isUploading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "checkmark.circle.fill")
                }
                Text(isUploading ? "Uploading..." : "Save Recording")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.accentColor)
            )
        }
        .buttonStyle(.plain)
        .disabled(isUploading)
    }
    
    // MARK: - Audio Upload Section
    
    private var audioUploadSection: some View {
        VStack(spacing: 12) {
            // Upload button
            Button(action: { showAudioPicker = true }) {
                HStack {
                    Image(systemName: "folder.fill")
                    Text("Choose Audio File")
                    Spacer()
                    Text("M4A, MP3, WAV")
                        .foregroundColor(theme.secondaryTextColor)
                }
                .padding(12)
            }
            .buttonStyle(.plain)
            .disabled(isUploading)
            
            // Selected file
            if let fileName = selectedAudioFileName {
                HStack {
                    Text(fileName)
                        .font(.system(size: 14))
                        .foregroundColor(theme.textColor)
                        .lineLimit(1)
                    Spacer()
                    Button("Clear") {
                        selectedAudioFile = nil
                        selectedAudioFileName = nil
                    }
                    .font(.system(size: 13))
                }
                .padding(8)
                .background(Color.clear)
                
                // Save button
                Button(action: uploadAudioFile) {
                    Text(isUploading ? "Uploading..." : "Upload")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .disabled(isUploading || selectedAudioFile == nil)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.cardBackgroundColor)
        )
    }
    
    // MARK: - Document Upload Section
    
    private var documentUploadSection: some View {
        VStack(spacing: 16) {
            // Upload button
            Button(action: { showDocumentPicker = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 24))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Choose Document")
                            .font(.system(size: 16, weight: .semibold))
                        Text("PDF, TXT, RTF")
                            .font(.system(size: 12))
                            .foregroundColor(theme.secondaryTextColor)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(theme.secondaryTextColor)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.accentColor.opacity(0.1))
                )
            }
            .buttonStyle(.plain)
            .disabled(isUploading)
            
            // Selected document display
            if let docName = selectedDocumentName {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(theme.accentColor)
                    Text(docName)
                        .font(.system(size: 14))
                        .foregroundColor(theme.textColor)
                        .lineLimit(1)
                    Spacer()
                    if isExtracting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Button(action: {
                            selectedDocument = nil
                            selectedDocumentName = nil
                            extractedText = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(theme.secondaryTextColor)
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.cardBackgroundColor)
                )
                
                // Extracted text preview
                if let text = extractedText {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Extracted Text (\(text.count) characters)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.secondaryTextColor)
                        
                        Text(text)
                            .font(.system(size: 14))
                            .foregroundColor(theme.textColor)
                            .lineLimit(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(theme.backgroundColor)
                    )
                    
                    // Save button
                    Button(action: uploadDocument) {
                        HStack(spacing: 8) {
                            if isUploading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "arrow.up.circle.fill")
                            }
                            Text(isUploading ? "Uploading..." : "Save Document")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(theme.accentColor)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isUploading)
                }
            }
            
            // Upload progress
            if isUploading {
                uploadProgressView
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackgroundColor)
        )
    }
    
    // MARK: - Typing Section
    
    private var typingSection: some View {
        VStack(spacing: 12) {
            // Text editor
            ZStack(alignment: .topLeading) {
                if memoryText.isEmpty {
                    Text("Write your memory here...")
                        .foregroundColor(theme.secondaryTextColor.opacity(0.5))
                        .font(.system(size: 16))
                        .padding(16)
                }
                
                TextEditor(text: $memoryText)
                    .font(.system(size: 16))
                    .foregroundColor(theme.textColor)
                    .padding(12)
                    .background(Color.clear)
                    .scrollContentBackground(.hidden)
            }
            .frame(minHeight: 120)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.cardBackgroundColor)
            )
            
            // Character count
            HStack {
                Text("\(memoryText.count) characters")
                    .font(.system(size: 12))
                    .foregroundColor(theme.secondaryTextColor)
                Spacer()
            }
            
            // Save button
            if !memoryText.isEmpty {
                Button(action: uploadText) {
                    Text(isUploading ? "Saving..." : "Save")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .disabled(isUploading)
            }
        }
    }
    
    // MARK: - Upload Progress View
    
    private var uploadProgressView: some View {
        HStack {
            ProgressView(value: uploadProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: theme.accentColor))
            Text("\(Int(uploadProgress * 100))%")
                .font(.system(size: 12))
                .foregroundColor(theme.secondaryTextColor)
                .frame(width: 40, alignment: .leading)
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
        guard hasValidPrompt() else {
            uploadError = "Please select or enter a prompt first"
            return
        }
        
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
                    source: "app_audio"
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
        guard hasValidPrompt() else {
            uploadError = "Please select or enter a prompt first"
            return
        }
        
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
                    source: "app_audio"
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
        guard hasValidPrompt() else {
            uploadError = "Please select or enter a prompt first"
            return
        }
        
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
    
    private func uploadText() {
        guard hasValidPrompt() else {
            uploadError = "Please select or enter a prompt first"
            return
        }
        
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
