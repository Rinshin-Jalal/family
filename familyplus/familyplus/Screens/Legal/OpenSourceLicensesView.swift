//
//  OpenSourceLicensesView.swift
//  familyplus
//
//  Open Source Licenses
//

import SwiftUI

struct OpenSourceLicensesView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss

    // List of open source dependencies
    let licenses = [
        License(
            name: "Supabase",
            url: "https://github.com/supabase/supabase-swift",
            license: "Apache License 2.0"
        ),
        License(
            name: "Hono",
            url: "https://github.com/honojs/hono",
            license: "MIT License"
        ),
        License(
            name: "SwiftUI",
            url: "https://developer.apple.com/swiftui/",
            license: "Apple Platform License"
        ),
        License(
            name: "Cloudflare R2",
            url: "https://developers.cloudflare.com/r2/",
            license: "Cloudflare License Agreement"
        )
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(licenses) { license in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(license.name)
                            .font(.headline)
                            .foregroundColor(theme.textColor)

                        Text(license.license)
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor)

                        if let url = URL(string: license.url) {
                            Link(destination: url) {
                                Text(license.url)
                                    .font(.caption2)
                                    .foregroundColor(theme.accentColor)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationTitle("Open Source Licenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct License: Identifiable {
    let id = UUID()
    let name: String
    let url: String
    let license: String
}

#Preview {
    OpenSourceLicensesView()
        .themed(DarkTheme())
}
