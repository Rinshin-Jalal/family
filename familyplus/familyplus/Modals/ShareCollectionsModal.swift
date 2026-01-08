//
//  ShareCollectionsModal.swift
//  StoryRide
//
//  Modal for sharing stories and collections with public links
//  TRANSFORMED from InviteFamilyModal: Now focused on value extraction (public sharing)
//  rather than social network (inviting family members)
//

import SwiftUI

// MARK: - Share Collections Modal

struct ShareCollectionsModal: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    @State private var selectedTab: ShareTab = .story
    @State private var isLoading = false
    @State private var shareLink: String?
    @State private var errorMessage: String?
    @State private var showShareSheet = false
    @State private var showSuccess = false
    @State private var selectedStories: Set<String> = []

    // Share settings
    @State private var allowDownload = false
    @State private var allowComments = false
    @State private var showWatermark = true
    @State private var watermarkText = ""
    @State private var expirationDays: Int = 30
    @State private var hasExpiration = true

    enum ShareTab: String, CaseIterable {
        case story = "Story"
        case collection = "Collection"

        var icon: String {
            switch self {
            case .story: return "book.fill"
            case .collection: return "books.vertical.fill"
            }
        }
    }

    var body: some View {
        ZStack {
            theme.backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView
                    .padding(.horizontal, theme.screenPadding)
                    .padding(.top, 16)

                ScrollView {
                    VStack(spacing: 24) {
                        // Tab selector
                        tabPicker

                        if isLoading {
                            loadingState
                        } else if let link = shareLink {
                            shareResultView(link: link)
                        } else if let error = errorMessage {
                            errorState(message: error)
                        } else {
                            shareSettingsView
                        }
                    }
                    .padding(.horizontal, theme.screenPadding)
                    .padding(.top, 20)
                }

                // Bottom button
                VStack(spacing: 0) {
                    Divider()
                        .background(theme.secondaryTextColor.opacity(0.2))

                    actionButton
                        .padding(.horizontal, theme.screenPadding)
                        .padding(.vertical, 16)
                }
                .background(theme.cardBackgroundColor)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let link = shareLink {
                SystemShareSheet(activityItems: [link])
            }
        }
    }

    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.secondaryTextColor)
                    .frame(width: 32, height: 32)
            }

            Spacer()

            Text("Share Content")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(theme.textColor)

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.clear)
                    .frame(width: 32, height: 32)
            }
        }
    }

    private var tabPicker: some View {
        HStack(spacing: 8) {
            ForEach(ShareTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTab = tab
                        shareLink = nil
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 14))
                        Text(tab.rawValue)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(selectedTab == tab ? .white : theme.textColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedTab == tab ? theme.accentColor : theme.cardBackgroundColor)
                    )
                }
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(theme.accentColor)
            Text("Creating share link...")
                .font(.system(size: 16))
                .foregroundColor(theme.secondaryTextColor)
        }
        .frame(minHeight: 300)
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 56))
                .foregroundColor(.orange)

            Text("Couldn't Create Link")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(theme.textColor)

            Text(message)
                .font(.system(size: 14))
                .foregroundColor(theme.secondaryTextColor)
                .multilineTextAlignment(.center)

            Button(action: {
                errorMessage = nil
            }) {
                Text("Try Again")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(theme.accentColor)
                    .cornerRadius(12)
            }
        }
        .frame(minHeight: 300)
    }

    private func shareResultView(link: String) -> some View {
        VStack(spacing: 24) {
            // Success icon
            if showSuccess {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(theme.accentColor)
            }

            VStack(spacing: 12) {
                if showSuccess {
                    Text("Link Ready!")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(theme.textColor)

                    Text("Share this public link\nno account needed")
                        .font(.system(size: 15))
                        .foregroundColor(theme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Public Link Created")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(theme.textColor)

                    Text("Anyone with this link can view\nwithout an account")
                        .font(.system(size: 15))
                        .foregroundColor(theme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                }
            }

            // Share link display
            VStack(spacing: 12) {
                HStack {
                    Text(link)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(theme.secondaryTextColor)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button(action: {
                        UIPasteboard.general.string = link
                        withAnimation(.spring(response: 0.3)) {
                            showSuccess = true
                        }
                        // Reset success after delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showSuccess = false
                            }
                        }
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 14))
                            .foregroundColor(theme.accentColor)
                            .frame(width: 32, height: 32)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(theme.cardBackgroundColor)
                )

                // Share button
                Button(action: {
                    showShareSheet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Share Link")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(theme.accentColor)
                    .cornerRadius(12)
                }
            }

            // Create new link button
            Button(action: {
                withAnimation {
                    shareLink = nil
                }
            }) {
                Text("Create Another Link")
                    .font(.system(size: 14))
                    .foregroundColor(theme.accentColor)
            }
        }
        .frame(minHeight: 400)
    }

    private var shareSettingsView: some View {
        VStack(spacing: 20) {
            // Info banner
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Public Sharing")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.textColor)

                    Text("Anyone with the link can view without an account")
                        .font(.system(size: 12))
                        .foregroundColor(theme.secondaryTextColor)
                }

                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue.opacity(0.1))
            )

            // Permissions section
            VStack(alignment: .leading, spacing: 16) {
                Text("Permissions")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(theme.textColor)

                permissionToggle(
                    icon: "eye.fill",
                    title: "Allow Viewing",
                    subtitle: "Viewers can see the content",
                    isOn: .constant(true),
                    isLocked: true
                )

                permissionToggle(
                    icon: "square.and.arrow.down.fill",
                    title: "Allow Download",
                    subtitle: "Viewers can download files",
                    isOn: $allowDownload
                )

                permissionToggle(
                    icon: "bubble.left.and.bubble.right.fill",
                    title: "Allow Comments",
                    subtitle: "Viewers can leave comments",
                    isOn: $allowComments
                )
            }

            Divider()
                .background(theme.secondaryTextColor.opacity(0.2))

            // Watermark section
            VStack(alignment: .leading, spacing: 16) {
                Text("Watermark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(theme.textColor)

                Toggle("", isOn: $showWatermark)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: theme.accentColor))

                if showWatermark {
                    TextField("Custom watermark text", text: $watermarkText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .foregroundColor(theme.textColor)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(theme.cardBackgroundColor)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(theme.secondaryTextColor.opacity(0.2), lineWidth: 1)
                        )
                }
            }

            Divider()
                .background(theme.secondaryTextColor.opacity(0.2))

            // Expiration section
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Expiration")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(theme.textColor)

                    Spacer()

                    Toggle("", isOn: $hasExpiration)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: theme.accentColor))
                }

                if hasExpiration {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Link expires in \(expirationDays) days")
                            .font(.system(size: 14))
                            .foregroundColor(theme.secondaryTextColor)

                        Slider(value: Binding(
                            get: { Double(expirationDays) },
                            set: { expirationDays = Int($0) }
                        ), in: 1...365, step: 1)
                        .tint(theme.accentColor)

                        HStack {
                            Text("1 day")
                                .font(.system(size: 11))
                                .foregroundColor(theme.secondaryTextColor)
                            Spacer()
                            Text("365 days")
                                .font(.system(size: 11))
                                .foregroundColor(theme.secondaryTextColor)
                        }
                    }
                }
            }
        }
        .frame(minHeight: 400)
    }

    private func permissionToggle(icon: String, title: String, subtitle: String, isOn: Binding<Bool>, isLocked: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(isLocked ? .gray : theme.accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.textColor)

                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(theme.secondaryTextColor)
            }

            Spacer()

            if isLocked {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.green)
            } else {
                Toggle("", isOn: isOn)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: theme.accentColor))
            }
        }
    }

    private var actionButton: some View {
        Button(action: {
            Task {
                await createShareLink()
            }
        }) {
            Text(shareLink == nil ? "Create Public Link" : "Create New Link")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: theme.buttonHeight)
                .background(theme.accentColor)
                .cornerRadius(16)
        }
        .disabled(isLoading)
    }

    private func createShareLink() async {
        isLoading = true
        errorMessage = nil

        do {
            let permissions = SharePermissions(
                view: true,
                download: allowDownload,
                comment: allowComments
            )

            let expiresAt: Date? = hasExpiration ? Date().addingTimeInterval(Double(expirationDays * 86400)) : nil

            // For demo, using a mock link - in production this would call the API
            let mockToken = String(format: "%08X", Int.random(in: 0...Int.max))
            let link = "https://storyrd.app/s/\(mockToken)"

            await MainActor.run {
                shareLink = link
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

// MARK: - Share Permissions Model

struct SharePermissions: Codable {
    let view: Bool
    let download: Bool
    let comment: Bool
}

// MARK: - System Share Sheet (renamed to avoid conflicts)

struct SystemShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

struct ShareCollectionsModal_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ShareCollectionsModal()
                .themed(DarkTheme())
                .previewDisplayName("Dark Theme")

            ShareCollectionsModal()
                .themed(LightTheme())
                .previewDisplayName("Light Theme")
        }
    }
}
