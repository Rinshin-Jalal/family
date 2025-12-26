//
//  ProfileSwitcher.swift
//  StoryRide
//
//  Netflix-style profile switcher in top-right
//

import SwiftUI

// MARK: - User Profile Model

struct UserProfile: Identifiable {
    let id = UUID()
    let name: String
    let role: PersonaRole
    let avatarEmoji: String

    var displayName: String {
        "\(name) (\(role.displayName))"
    }
}

// MARK: - Profile Switcher

struct ProfileSwitcher: View {
    @Binding var currentProfile: UserProfile
    let profiles: [UserProfile]
    @State private var showingPicker = false

    var body: some View {
        Button(action: {
            showingPicker = true
        }) {
            HStack(spacing: 8) {
                Text(currentProfile.avatarEmoji)
                    .font(.title3)

                Image(systemName: "chevron.down")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.primary.opacity(0.1))
            )
        }
        .sheet(isPresented: $showingPicker) {
            ProfilePickerView(
                currentProfile: $currentProfile,
                profiles: profiles,
                isPresented: $showingPicker
            )
        }
        .accessibilityLabel("Switch profile. Current: \(currentProfile.name)")
        .accessibilityHint("Double tap to change user profile")
    }
}

// MARK: - Profile Picker Sheet

struct ProfilePickerView: View {
    @Binding var currentProfile: UserProfile
    let profiles: [UserProfile]
    @Binding var isPresented: Bool
    @Environment(\.theme) var theme

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Who's using StoryRide?")
                    .font(.title.bold())
                    .padding(.top, 40)

                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: 20
                ) {
                    ForEach(profiles) { profile in
                        ProfileTile(
                            profile: profile,
                            isSelected: profile.id == currentProfile.id
                        ) {
                            // Haptic feedback
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()

                            currentProfile = profile
                            isPresented = false
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .background(Color(.systemBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Profile Tile

struct ProfileTile: View {
    let profile: UserProfile
    let isSelected: Bool
    let action: () -> Void

    var themeColor: Color {
        switch profile.role {
        case .teen:
            return .brandIndigo
        case .parent:
            return .brandIndigo
        case .child:
            return .playfulOrange
        case .elder:
            return .storytellerOrange
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(themeColor.opacity(0.15))
                        .frame(width: 100, height: 100)

                    Text(profile.avatarEmoji)
                        .font(.system(size: 48))
                }
                .overlay(
                    Circle()
                        .strokeBorder(
                            isSelected ? themeColor : Color.clear,
                            lineWidth: 3
                        )
                )

                // Name and role
                VStack(spacing: 4) {
                    Text(profile.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(profile.role.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? themeColor : Color.clear,
                        lineWidth: 2
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(profile.name), \(profile.role.displayName)")
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to switch to this profile")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Preview

struct ProfileSwitcher_Previews: PreviewProvider {
    static let sampleProfiles = [
        UserProfile(name: "Leo", role: .teen, avatarEmoji: "🎸"),
        UserProfile(name: "Mom", role: .parent, avatarEmoji: "👩"),
        UserProfile(name: "Mia", role: .child, avatarEmoji: "🌟"),
        UserProfile(name: "Grandma", role: .elder, avatarEmoji: "❤️")
    ]

    static var previews: some View {
        VStack {
            ProfileSwitcher(
                currentProfile: .constant(sampleProfiles[0]),
                profiles: sampleProfiles
            )

            Spacer()

            ProfilePickerView(
                currentProfile: .constant(sampleProfiles[0]),
                profiles: sampleProfiles,
                isPresented: .constant(true)
            )
        }
        .themed(ParentTheme())
    }
}
