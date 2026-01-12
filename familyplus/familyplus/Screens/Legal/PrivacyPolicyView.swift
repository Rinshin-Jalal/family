//
//  PrivacyPolicyView.swift
//  familyplus
//
//  Privacy Policy
//

import SwiftUI

struct PrivacyPolicyView: View {
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
                    section(title: "1. Our Commitment to Privacy") {
                        Text("Family+ is designed with privacy at its core. We believe your family stories and personal data should be protected.")
                        Text("This Privacy Policy explains how we collect, use, and safeguard your information.")
                    }

                    // Information We Collect
                    section(title: "2. Information We Collect") {
                        Text("Account Information: Name, email address, and authentication credentials provided during signup.")
                        Text("Profile Information: Avatar emoji, family role, and preferences.")
                        Text("Content: Audio recordings, photos, stories, and memories you upload.")
                        Text("Usage Data: How you interact with the app, features used, and performance data.")
                    }

                    // How We Use Your Information
                    section(title: "3. How We Use Your Information") {
                        Text("Provide and improve Family+ services")
                        Text("Process and analyze your content using AI")
                        Text("Send notifications you've requested")
                        Text("Respond to your questions and requests")
                        Text("Analyze usage patterns to improve the app")
                    }

                    // Data Storage and Security
                    section(title: "4. Data Storage and Security") {
                        Text("Your data is stored on secure servers via Supabase")
                        Text("Audio files are stored on Cloudflare R2")
                        Text("We use industry-standard encryption for data in transit and at rest")
                        Text("Access to your data is limited to you and your family members")
                    }

                    // AI and Content Processing
                    section(title: "5. AI and Content Processing") {
                        Text("We use AI to:")
                        Text("• Transcribe audio recordings")
                        Text("• Generate summaries and tags")
                        Text("• Suggest related stories")
                        Text("• Extract wisdom and insights")
                        Text("AI processing occurs on secure servers. Your content is not used to train public AI models.")
                    }

                    // Data Sharing
                    section(title: "6. Data Sharing") {
                        Text("We do NOT sell your personal data")
                        Text("Your content is shared only with:")
                        Text("• Your family members (based on privacy settings)")
                        Text("• Service providers who assist our operations (under strict confidentiality)")
                        Text("• Legal authorities when required by law")
                    }

                    // Data Retention
                    section(title: "7. Data Retention") {
                        Text("You can choose how long we keep your data:")
                        Text("• 3 months")
                        Text("• 6 months")
                        Text("• 1 year")
                        Text("• Forever (default)")
                        Text("You can export or delete your data at any time from Settings.")
                    }

                    // Your Rights
                    section(title: "8. Your Rights") {
                        Text("Access: View all data we have about you")
                        Text("Export: Download a copy of your data")
                        Text("Delete: Permanently delete your account and data")
                        Text("Opt-out: Disable notifications and data sharing")
                    }

                    // Children's Privacy
                    section(title: "9. Children's Privacy") {
                        Text("Family+ is intended for family use. Parents and guardians should supervise children's use of the app.")
                        Text("We do not knowingly collect data from children under 13 without parental consent.")
                    }

                    // Changes to This Policy
                    section(title: "10. Changes to This Policy") {
                        Text("We may update this Privacy Policy from time to time. We will notify you of significant changes via email or in-app notification.")
                    }

                    // Contact Us
                    section(title: "11. Contact Us") {
                        Text("Questions about this policy? Contact us at:")
                        Text("privacy@storyrd.app")
                            .foregroundColor(theme.accentColor)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationTitle("Privacy Policy")
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
    PrivacyPolicyView()
        .themed(DarkTheme())
}
