//
//  TermsOfServiceView.swift
//  familyplus
//
//  Terms of Service
//

import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Last Updated
                    Text("Last Updated: January 12, 2026")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)

                    // Introduction
                    section(title: "1. Introduction") {
                        Text("Welcome to Family+ (\"we,\" \"our,\" or \"us\"). By using our application, you agree to these Terms of Service.")
                        Text("Family+ is a value extraction tool designed to help families preserve stories, wisdom, and voice memories.")
                    }

                    // Account Responsibilities
                    section(title: "2. Account Responsibilities") {
                        Text("You are responsible for maintaining the security of your account and for all activities that occur under your account.")
                        Text("You must provide accurate information when creating your account.")
                        Text("You must notify us immediately of any unauthorized use of your account.")
                    }

                    // Family Data
                    section(title: "3. Family Data") {
                        Text("Family+ allows you to create and join family groups. Each family group is private and accessible only to members.")
                        Text("Organizers can add or remove family members.")
                        Text("You are responsible for the content you upload to Family+.")
                    }

                    // Content and Intellectual Property
                    section(title: "4. Content and Intellectual Property") {
                        Text("You retain ownership of all content you upload to Family+.")
                        Text("By uploading content, you grant us a license to store, process, and display it for the purpose of providing our services.")
                        Text("We use AI to analyze and enhance your content, including generating summaries, tags, and transcriptions.")
                    }

                    // Privacy
                    section(title: "5. Privacy") {
                        Text("Your privacy is important to us. Please review our Privacy Policy to understand how we collect, use, and protect your data.")
                        Text("We implement appropriate security measures to protect your personal information.")
                    }

                    // Discontinuation
                    section(title: "6. Service Modifications") {
                        Text("We reserve the right to modify, suspend, or discontinue any aspect of Family+ at any time.")
                        Text("We may also impose limits on certain features or restrict your access to parts or all of the service without notice.")
                    }

                    // Termination
                    section(title: "7. Termination") {
                        Text("We may terminate or suspend your account at any time for violation of these Terms.")
                        Text("Upon termination, your right to use the service will immediately cease.")
                    }

                    // Disclaimer
                    section(title: "8. Disclaimer") {
                        Text("Family+ is provided \"as is\" without warranties of any kind.")
                        Text("We do not guarantee that the service will be uninterrupted, secure, or error-free.")
                    }

                    // Contact
                    section(title: "9. Contact Us") {
                        Text("If you have questions about these Terms, please contact us at:")
                        Text("support@storyrd.app")
                            .foregroundColor(theme.accentColor)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationTitle("Terms of Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(theme.textColor)

            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .font(.body)
            .foregroundColor(theme.secondaryTextColor)

            Divider()
                .background(theme.secondaryTextColor.opacity(0.2))
        }
    }
}

#Preview {
    TermsOfServiceView()
        .themed(DarkTheme())
}
