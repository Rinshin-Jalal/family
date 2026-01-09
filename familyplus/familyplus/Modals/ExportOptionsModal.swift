//
//  ExportOptionsModal.swift
//  StoryRide
//
//  Export Modal - Multi-format export for value extraction
//  Users can export stories as PDF, Audio, Video, JSON, or EPUB
//

import SwiftUI

// MARK: - Export Options Modal

struct ExportOptionsModal: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    let storyId: String
    let storyTitle: String
    let collectionId: String?
    let collectionTitle: String?

    @State private var selectedFormat: ExportFormat = .pdf
    @State private var isExporting = false
    @State private var exportProgress: Double = 0
    @State private var exportError: String?
    @State private var exportComplete = false
    @State private var downloadUrl: String?

    // Export options
    @State private var includeImages = true
    @State private var includeTranscript = true
    @State private var includeMetadata = true
    @State private var addWatermark = false
    @State private var watermarkText = ""

    enum ExportFormat: String, CaseIterable {
        case pdf = "PDF Document"
        case audio = "Audio (MP3)"
        case video = "Video (MP4)"
        case json = "JSON Backup"
        case epub = "E-book (EPUB)"

        var icon: String {
            switch self {
            case .pdf: return "doc.fill"
            case .audio: return "waveform.circle.fill"
            case .video: return "video.fill"
            case .json: return "doc.text.fill"
            case .epub: return "book.fill"
            }
        }

        var color: Color {
            switch self {
            case .pdf: return .red
            case .audio: return .purple
            case .video: return .blue
            case .json: return .orange
            case .epub: return .green
            }
        }

        var description: String {
            switch self {
            case .pdf: return "Formatted document with images and text"
            case .audio: return "Audio file compatible with all players"
            case .video: return "Slideshow video for social media"
            case .json: return "Complete data backup"
            case .epub: return "E-book for Apple Books, Kindle"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundColor.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        if !isExporting && !exportComplete {
                            formatSelectionView
                            optionsView
                        } else if isExporting {
                            progressView
                        } else if exportComplete {
                            completeView
                        } else if let error = exportError {
                            errorView(error)
                        }

                        Spacer()
                    }
                    .padding(theme.screenPadding)
                    .padding(.top, 20)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(theme.accentColor)
                }
            }
        }
    }

    private var title: String {
        if let collectionId = collectionId {
            return "Export Collection"
        }
        return "Export Story"
    }

    private var formatSelectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Format")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(theme.textColor)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    FormatCard(
                        format: format,
                        isSelected: selectedFormat == format
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            selectedFormat = format
                        }
                    }
                }
            }
        }
    }

    private var optionsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Options")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(theme.textColor)

            VStack(spacing: 16) {
                OptionToggle(
                    icon: "photo.fill",
                    title: "Include Images",
                    subtitle: "Add AI-generated images to export"
                ) {
                    includeImages.toggle()
                }

                if selectedFormat == .pdf || selectedFormat == .epub {
                    OptionToggle(
                        icon: "text.alignleft",
                        title: "Include Transcript",
                        subtitle: "Add full text transcript"
                    ) {
                        includeTranscript.toggle()
                    }
                }

                if selectedFormat == .pdf {
                    OptionToggle(
                        icon: "info.circle.fill",
                        title: "Include Metadata",
                        subtitle: "Date, storyteller, tags"
                    ) {
                        includeMetadata.toggle()
                    }

                    OptionToggle(
                        icon: "drop.seal.fill",
                        title: "Add Watermark",
                        subtitle: "Overlay text on exported file"
                    ) {
                        addWatermark.toggle()
                    }

                    if addWatermark {
                        TextField("Watermark text", text: $watermarkText)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 14))
                            .padding(.horizontal)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.cardBackgroundColor)
            )
        }
    }

    private var progressView: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(theme.accentColor.opacity(0.2), lineWidth: 8)
                        .frame(width: 120, height: 120)

                    Circle()
                        .trim(from: 0, to: exportProgress)
                        .stroke(
                            LinearGradient(
                                colors: [theme.accentColor, theme.accentColor.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear, value: exportProgress)

                    Text("\(Int(exportProgress * 100))%")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(theme.textColor)
                }

                VStack(spacing: 8) {
                    Text("Exporting \(selectedFormat.rawValue.uppercased())")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.textColor)

                    Text("Please wait while we prepare your file...")
                        .font(.system(size: 14))
                        .foregroundColor(theme.secondaryTextColor)
                }
            }

            Spacer()
        }
    }

    private var completeView: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.green, .green.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)

                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(spacing: 8) {
                    Text("Export Complete!")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(theme.textColor)

                    if let url = downloadUrl {
                        Text("Your file is ready to download")
                            .font(.system(size: 15))
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }
            }

            if let url = downloadUrl {
                VStack(spacing: 12) {
                    Button(action: {
                        // Download file
                        if let url = URL(string: url) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Download File")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                colors: [.green, .green.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }

                    Button(action: {
                        // Share file
                        if let url = URL(string: url) {
                            let activityVC = UIActivityViewController(
                                activityItems: [url],
                                applicationActivities: nil
                            )
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let rootVC = windowScene.windows.first?.rootViewController {
                                rootVC.present(activityVC, animated: true)
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Share")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(theme.accentColor)
                        .cornerRadius(12)
                    }
                }
            }

            Spacer()
        }
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundColor(.orange)

            VStack(spacing: 8) {
                Text("Export Failed")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(theme.textColor)

                Text(error)
                    .font(.system(size: 14))
                    .foregroundColor(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                exportError = nil
                startExport()
            }) {
                Text("Try Again")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(theme.accentColor)
                    .cornerRadius(12)
            }

            Spacer()
        }
    }

    private var actionButton: some View {
        Button(action: {
            startExport()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18, weight: .semibold))
                Text("Export \(selectedFormat.rawValue.uppercased())")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [theme.accentColor, theme.accentColor.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
        }
        .disabled(isExporting)
        .padding(.horizontal)
        .padding(.bottom, 20)
    }

    private func startExport() {
        isExporting = true
        exportProgress = 0
        exportError = nil

        // Simulate export progress
        Task {
            do {
                for progress in stride(from: 0, through: 100, by: 10) {
                    try await Task.sleep(nanoseconds: 200_000_000)
                    await MainActor.run {
                        exportProgress = Double(progress) / 100
                    }
                }

                // TODO: Call actual export API
                // POST /api/stories/:id/export/:format

                await MainActor.run {
                    isExporting = false
                    exportComplete = true
                    downloadUrl = "https://storage.example.com/exports/\(storyId).\(selectedFormat)"

                    // Track value analytics: export completed
                    let exportFormat = selectedFormat == .pdf ? "pdf" :
                                      selectedFormat == .audio ? "mp3" :
                                      selectedFormat == .video ? "mp4" :
                                      selectedFormat == .json ? "json" : "epub"
                    ValueAnalyticsService.shared.trackStoryExport(format: exportFormat, storyId: storyId)
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    exportError = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Format Card

struct FormatCard: View {
    let format: ExportOptionsModal.ExportFormat
    let isSelected: Bool

    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isSelected ? format.color : format.color.opacity(0.1))
                    .frame(width: 50, height: 50)

                Image(systemName: format.icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .white : format.color)
            }

            VStack(spacing: 4) {
                Text(format.rawValue)
                    .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                    .foregroundColor(theme.textColor)

                Text(format.description)
                    .font(.system(size: 11))
                    .foregroundColor(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? format.color.opacity(0.15) : theme.cardBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? format.color : Color.clear, lineWidth: 2)
                )
        )
    }
}

// MARK: - Option Toggle

struct OptionToggle: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    @Environment(\.theme) var theme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(theme.accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(theme.textColor)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(theme.secondaryTextColor)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { /* TODO: Bind to state */ true },
                set: { _ in action() }
            ))
            .labelsHidden()
        }
    }
}

// MARK: - Preview

struct ExportOptionsModal_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ExportOptionsModal(
                storyId: "story-123",
                storyTitle: "The Summer of 1968",
                collectionId: nil,
                collectionTitle: nil
            )
            .themed(DarkTheme())
            .previewDisplayName("Dark - Story Export")

            ExportOptionsModal(
                storyId: "story-123",
                storyTitle: "The Summer of 1968",
                collectionId: nil,
                collectionTitle: nil
            )
            .themed(LightTheme())
            .previewDisplayName("Light - Story Export")
        }
    }
}
