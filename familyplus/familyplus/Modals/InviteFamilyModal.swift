//
//  InviteFamilyModal.swift
//  StoryRide
//
//  Modal for inviting new family members
//

import SwiftUI

struct InviteFamilyModal: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    @State private var isLoading = true
    @State private var familyInfo: FamilyInfo?
    @State private var errorMessage: String?
    @State private var showShareSheet = false
    @State private var showSuccess = false

    var body: some View {
        ZStack {
            theme.backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                if isLoading {
                    loadingState
                } else if let familyInfo = familyInfo {
                    inviteContent(familyInfo: familyInfo)
                } else if let error = errorMessage {
                    errorState(message: error)
                }

                Spacer()

                dismissButton
            }
            .padding(.horizontal, theme.screenPadding)
        }
        .task {
            await loadFamilyInfo()
        }
        .sheet(isPresented: $showShareSheet) {
            if let familyInfo = familyInfo {
                InviteShareSheet(activityItems: [familyInfo.inviteUrl])
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(theme.accentColor)
            Text("Loading invite link...")
                .font(.system(size: 16))
                .foregroundColor(theme.secondaryTextColor)
        }
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 64))
                .foregroundColor(.orange)

            Text("Couldn't Load Invite")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(theme.textColor)

            Text(message)
                .font(.system(size: 14))
                .foregroundColor(theme.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
    }

    private func inviteContent(familyInfo: FamilyInfo) -> some View {
        VStack(spacing: 24) {
            // Success icon
            if showSuccess {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 64))
                    .foregroundColor(theme.accentColor)
            }

            VStack(spacing: 12) {
                if showSuccess {
                    Text("Invite Link Ready!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(theme.textColor)

                    Text("Share this link with\nfamily members")
                        .font(.system(size: 16))
                        .foregroundColor(theme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Invite to \(familyInfo.name)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(theme.textColor)

                    Text("Share your unique invite link\nto add family members")
                        .font(.system(size: 16))
                        .foregroundColor(theme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                }
            }

            // Invite link display
            VStack(spacing: 12) {
                HStack {
                    Text(familyInfo.inviteUrl)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.secondaryTextColor)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button(action: {
                        UIPasteboard.general.string = familyInfo.inviteUrl
                        withAnimation {
                            showSuccess = true
                        }
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 16))
                            .foregroundColor(theme.accentColor)
                            .frame(width: 36, height: 36)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.cardBackgroundColor)
                )

                // Share button
                Button(action: {
                    showShareSheet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Share Link")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(theme.accentColor)
                    .cornerRadius(12)
                }
            }
        }
    }

    private var dismissButton: some View {
        Button(action: {
            dismiss()
        }) {
            Text("Done")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(theme.accentColor)
                .frame(maxWidth: .infinity)
                .frame(height: theme.buttonHeight)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(theme.accentColor, lineWidth: 2)
                )
        }
    }

    private func loadFamilyInfo() async {
        do {
            let info = try await APIService.shared.getFamily()
            await MainActor.run {
                self.familyInfo = info
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

// MARK: - Share Sheet (renamed to avoid conflicts)

struct InviteShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

struct InviteFamilyModal_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            InviteFamilyModal()
                .themed(DarkTheme())
                .previewDisplayName("Dark Theme")

            InviteFamilyModal()
                .themed(LightTheme())
                .previewDisplayName("Light Theme")
        }
    }
}
