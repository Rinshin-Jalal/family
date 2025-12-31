//
//  SettingsView.swift
//  StoryRide
//
//  Combined Settings screen with adaptive layouts
//

import SwiftUI

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss
    @State private var loadingState: LoadingState<ProfileSettingsData> = .loading
    @State private var selectedTab: SettingsTab = .profile
    @State private var showEditProfile = false
    @State private var showFamilySettings = false
    @State private var showExportData = false
    @State private var showDeleteConfirmation = false
    @State private var isExporting = false
    @State private var exportURL: URL?
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                switch loadingState {
                case .loading:
                    SettingsSkeleton()
                case .loaded(let data):
                    SettingsContent(
                        data: data,
                        selectedTab: $selectedTab,
                        onEditProfile: { showEditProfile = true },
                        onFamilySettings: { showFamilySettings = true },
                        onExportData: { startExport() },
                        onDeleteAccount: { showDeleteConfirmation = true },
                        onSignOut: { signOut() }
                    )
                case .error(let message):
                    ErrorStateView(message: message, onRetry: { loadData() })
                case .empty:
                    EmptyStateView(icon: "person.crop.circle", title: "No Profile", subtitle: "Set up your profile to get started")
                }
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showEditProfile) {
                EditProfileSheet()
            }
            .sheet(isPresented: $showFamilySettings) {
                FamilySettingsSheet()
            }
            .sheet(isPresented: $showExportData) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .alert("Delete Account", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteAccount()
                }
            } message: {
                Text("Are you sure you want to delete your account? This action cannot be undone and will permanently remove all your data.")
            }
            .alert("Error", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .onAppear {
                loadData()
            }
        }
    }
    
    private func loadData() {
        loadingState = .loading
        Task {
            do {
                let user = try await loadUserProfile()
                let family = try await loadFamilyInfo()
                let stats = try await loadUserStats()
                let settings = try await loadUserSettings()
                await MainActor.run {
                    loadingState = .loaded(ProfileSettingsData(
                        user: user,
                        family: family,
                        stats: stats,
                        settings: settings
                    ))
                }
            } catch {
                await MainActor.run {
                    loadingState = .error(error.localizedDescription)
                }
            }
        }
    }
    
    private func startExport() {
        isExporting = true
        Task {
            do {
                let data = try await APIService.shared.exportUserData()
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("storyride_export.json")
                try data.write(to: tempURL)
                await MainActor.run {
                    exportURL = tempURL
                    isExporting = false
                    showExportData = true
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    errorMessage = "Failed to export data: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func deleteAccount() {
        Task {
            do {
                try await APIService.shared.deleteAccount()
                AuthService.shared.clearToken()
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to delete account: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func signOut() {
        Task {
            try? await SupabaseService.shared.signOut()
            AuthService.shared.clearToken()
            dismiss()
        }
    }
    
    // MARK: - Mock Data Loading (replace with actual API calls)
    
    private func loadUserProfile() async throws -> UserProfile {
        try await Task.sleep(nanoseconds: 300_000_000)
        return UserProfile(
            id: "user-123",
            name: "Alex",
            email: "alex@example.com",
            avatarEmoji: "🎸",
            theme: .dark,
            joinedAt: Date().addingTimeInterval(-86400 * 90)
        )
    }
    
    private func loadFamilyInfo() async throws -> FamilyInfo {
        try await Task.sleep(nanoseconds: 200_000_000)
        return FamilyInfo(
            id: "family-123",
            name: "The Rodriguez Family",
            memberCount: 4,
            inviteSlug: "abc12345"
        )
    }
    
    private func loadUserStats() async throws -> UserStats {
        try await Task.sleep(nanoseconds: 150_000_000)
        return UserStats(
            totalStories: 42,
            weekStreak: 4,
            totalRecordings: 156,
            favoriteTopics: ["Childhood", "Travel", "Music"]
        )
    }
    
    private func loadUserSettings() async throws -> UserSettings {
        try await Task.sleep(nanoseconds: 250_000_000)
        return UserSettings(
            notifications: NotificationSettings(
                pushEnabled: true,
                emailEnabled: true,
                storyReminders: true,
                familyUpdates: true,
                weeklyDigest: true
            ),
            privacy: PrivacySettings(
                shareWithFamily: true,
                allowSuggestions: true,
                dataRetention: .forever
            ),
            preferences: PreferenceSettings(
                autoPlayAudio: true,
                defaultPromptCategory: "story",
                hapticsEnabled: true
            )
        )
    }
}

// MARK: - Sheet Views

struct EditProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) var theme
    @State private var name: String = ""
    @State private var selectedEmoji: String = "🎸"
    @State private var selectedTheme: AppTheme = .dark
    @State private var isSaving = false
    
    private let emojis = ["🎸", "🎨", "📚", "🌍", "🎭", "🎪", "🎯", "🎲", "🎺", "🎻"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Your name", text: $name)
                }
                
                Section("Avatar") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(emojis, id: \.self) { emoji in
                            Text(emoji)
                                .font(.title)
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(selectedEmoji == emoji ? theme.accentColor.opacity(0.3) : Color.clear)
                                )
                                .onTapGesture {
                                    selectedEmoji = emoji
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Theme") {
                    Picker("Appearance", selection: $selectedTheme) {
                        Text("Dark").tag(AppTheme.dark)
                        Text("Light").tag(AppTheme.light)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveProfile() }
                        .disabled(isSaving)
                }
            }
            .onAppear {
                name = "Alex"
            }
        }
    }
    
    private func saveProfile() {
        isSaving = true
        Task {
            try? await APIService.shared.updateProfile(
                name: name,
                avatarEmoji: selectedEmoji,
                theme: selectedTheme.rawValue
            )
            await MainActor.run {
                isSaving = false
                dismiss()
            }
        }
    }
}

struct FamilySettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) var theme
    @State private var familyName: String = ""
    @State private var inviteSlug: String = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Family Name") {
                    TextField("Family name", text: $familyName)
                }
                
                Section("Invite Link") {
                    HStack {
                        Text("share.storyride.app/join/")
                            .foregroundColor(theme.secondaryTextColor)
                        Text(inviteSlug)
                            .fontWeight(.medium)
                    }
                    
                    Button("Copy Link") {
                        UIPasteboard.general.string = "https://share.storyride.app/join/\(inviteSlug)"
                    }
                }
                
                Section("Members") {
                    NavigationLink("Manage Members") {
                        Text("Member management coming soon")
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }
                
                Section("Add Elder") {
                    NavigationLink("Add Elder (Phone)") {
                        Text("Elder onboarding coming soon")
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }
            }
            .navigationTitle("Family Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                familyName = "The Rodriguez Family"
                inviteSlug = "abc12345"
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Data Models

struct ProfileSettingsData {
    let user: UserProfile
    let family: FamilyInfo
    let stats: UserStats
    let settings: UserSettings
    
    static let sample = ProfileSettingsData(
        user: UserProfile(
            id: "user-123",
            name: "Alex",
            email: "alex@example.com",
            avatarEmoji: "🎸",
            theme: .dark,
            joinedAt: Date().addingTimeInterval(-86400 * 90)
        ),
        family: FamilyInfo(
            id: "family-123",
            name: "The Rodriguez Family",
            memberCount: 4,
            inviteSlug: "abc12345"
        ),
        stats: UserStats(
            totalStories: 42,
            weekStreak: 4,
            totalRecordings: 156,
            favoriteTopics: ["Childhood", "Travel", "Music"]
        ),
        settings: UserSettings(
            notifications: NotificationSettings(
                pushEnabled: true,
                emailEnabled: true,
                storyReminders: true,
                familyUpdates: true,
                weeklyDigest: true
            ),
            privacy: PrivacySettings(
                shareWithFamily: true,
                allowSuggestions: true,
                dataRetention: .forever
            ),
            preferences: PreferenceSettings(
                autoPlayAudio: true,
                defaultPromptCategory: "story",
                hapticsEnabled: true
            )
        )
    )
}

struct UserProfile: Identifiable {
    let id: String
    let name: String
    let email: String
    let avatarEmoji: String
    let theme: AppTheme
    let joinedAt: Date
}

struct FamilyInfo: Identifiable {
    let id: String
    let name: String
    let memberCount: Int
    let inviteSlug: String
}

struct UserStats {
    let totalStories: Int
    let weekStreak: Int
    let totalRecordings: TimeInterval
    let favoriteTopics: [String]
    
    var formattedRecordings: String {
        let hours = Int(totalRecordings) / 3600
        let minutes = (Int(totalRecordings) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

struct UserSettings {
    let notifications: NotificationSettings
    let privacy: PrivacySettings
    let preferences: PreferenceSettings
}

struct NotificationSettings {
    let pushEnabled: Bool
    let emailEnabled: Bool
    let storyReminders: Bool
    let familyUpdates: Bool
    let weeklyDigest: Bool
}

struct PrivacySettings {
    let shareWithFamily: Bool
    let allowSuggestions: Bool
    let dataRetention: DataRetention
}

enum DataRetention: String, CaseIterable {
    case threeMonths = "3 months"
    case sixMonths = "6 months"
    case oneYear = "1 year"
    case forever = "Forever"
    
    var description: String { rawValue }
}

struct PreferenceSettings {
    let autoPlayAudio: Bool
    let defaultPromptCategory: String
    let hapticsEnabled: Bool
}

// MARK: - Settings Tab

enum SettingsTab: String, CaseIterable {
    case profile = "Profile"
    case notifications = "Notifications"
    case privacy = "Privacy"
    case preferences = "App"
    case about = "About"
    
    var icon: String {
        switch self {
        case .profile: return "person.circle"
        case .notifications: return "bell"
        case .privacy: return "lock.shield"
        case .preferences: return "gearshape"
        case .about: return "info.circle"
        }
    }
}

// MARK: - Main Content

struct SettingsContent: View {
    let data: ProfileSettingsData
    @Binding var selectedTab: SettingsTab
    @Environment(\.theme) var theme
    let onEditProfile: () -> Void
    let onFamilySettings: () -> Void
    let onExportData: () -> Void
    let onDeleteAccount: () -> Void
    let onSignOut: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {  // HIG: Consistent 8pt grid spacing
                // Profile Header Card
                ProfileHeaderCard(user: data.user, stats: data.stats)

                // HIG: Native segmented picker
                TabPickerRow(selectedTab: $selectedTab)

                // Tab Content with animation
                Group {
                    switch selectedTab {
                    case .profile:
                        ProfileSection(data: data, onEditProfile: onEditProfile, onFamilySettings: onFamilySettings, onSignOut: onSignOut)
                    case .notifications:
                        NotificationSection(settings: data.settings.notifications)
                    case .privacy:
                        PrivacySection(settings: data.settings.privacy, onExportData: onExportData, onDeleteAccount: onDeleteAccount)
                    case .preferences:
                        PreferencesSection(settings: data.settings.preferences)
                    case .about:
                        AboutSection()
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: selectedTab)
            }
            .padding(.vertical, 16)
        }
    }
}

// MARK: - Profile Header Card (Apple HIG Compliant)

struct ProfileHeaderCard: View {
    let user: UserProfile
    let stats: UserStats
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 24) {
            // Profile Identity Section
            HStack(spacing: 16) {
                // Avatar - Following HIG 44pt minimum touch target
                ZStack {
                    Circle()
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: 72, height: 72)
                    Text(user.avatarEmoji)
                        .font(.system(size: 32))
                }

                // Name & Subtitle
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.name)
                        .font(.title2.weight(.semibold))  // HIG: Use semantic font styles
                        .foregroundColor(Color(.label))
                    Text(user.theme.displayName)
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                }

                Spacer()

                // Edit button following HIG
                Button {
                    // Edit action
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(theme.accentColor)
                }
                .accessibilityLabel("Edit Profile")
            }

            // Stats Row - Following HIG visual hierarchy
            HStack(spacing: 0) {
                StatItem(value: "\(stats.totalStories)", label: "Stories", icon: "book.fill")

                Divider()
                    .frame(height: 40)
                    .padding(.horizontal, 16)

                StatItem(value: "\(stats.weekStreak)", label: "Week Streak", icon: "flame.fill")

                Divider()
                    .frame(height: 40)
                    .padding(.horizontal, 16)

                StatItem(value: stats.formattedRecordings, label: "Recorded", icon: "waveform")
            }
            .padding(.vertical, 8)
        }
        .padding(20)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 6) {
            // Icon + Value together for visual grouping
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(theme.accentColor)
                Text(value)
                    .font(.title3.weight(.bold).monospacedDigit())  // HIG: Monospaced for numbers
                    .foregroundColor(Color(.label))
            }

            Text(label)
                .font(.caption2)  // HIG: Use caption2 for tertiary info
                .foregroundColor(Color(.tertiaryLabel))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Tab Picker (Apple HIG Segmented Control)

struct TabPickerRow: View {
    @Binding var selectedTab: SettingsTab
    @Environment(\.theme) var theme

    var body: some View {
        // HIG: Use native Picker with segmented style for 2-5 options
        Picker("Settings Section", selection: $selectedTab) {
            ForEach(SettingsTab.allCases, id: \.self) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
                    .labelStyle(.titleOnly)  // Icons in segmented can be too cramped
                    .tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
    }
}

// MARK: - Profile Section

struct ProfileSection: View {
    let data: ProfileSettingsData
    let onEditProfile: () -> Void
    let onFamilySettings: () -> Void
    let onSignOut: () -> Void
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 16) {
            SettingsRow(
                icon: "person.circle",
                title: "Edit Profile",
                subtitle: "Update your name, avatar, and theme"
            ) {
                onEditProfile()
            }

            SettingsRow(
                icon: "person.3",
                title: "Family Settings",
                subtitle: "\(data.family.name) • \(data.family.memberCount) members"
            ) {
                onFamilySettings()
            }

            SettingsRow(
                icon: "envelope",
                title: "Email",
                subtitle: data.user.email,
                showChevron: false
            ) {}

            Divider()
                .background(theme.secondaryTextColor.opacity(0.3))
                .padding(.vertical, 4)

            // Sign Out at bottom of Profile tab - easily accessible but not first thing
            SettingsRow(
                icon: "rectangle.portrait.and.arrow.right",
                title: "Sign Out",
                subtitle: "Sign out of your account",
                isDestructive: true
            ) {
                onSignOut()
            }
        }
        .padding(.horizontal, theme.screenPadding)
    }
}

// MARK: - Notification Section

struct NotificationSection: View {
    let settings: NotificationSettings
    @Environment(\.theme) var theme
    @State private var pushEnabled: Bool
    @State private var emailEnabled: Bool
    @State private var storyReminders: Bool
    @State private var familyUpdates: Bool
    @State private var weeklyDigest: Bool
    
    init(settings: NotificationSettings) {
        self.settings = settings
        _pushEnabled = State(initialValue: settings.pushEnabled)
        _emailEnabled = State(initialValue: settings.emailEnabled)
        _storyReminders = State(initialValue: settings.storyReminders)
        _familyUpdates = State(initialValue: settings.familyUpdates)
        _weeklyDigest = State(initialValue: settings.weeklyDigest)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            SettingsToggleRow(
                icon: "bell.fill",
                title: "Push Notifications",
                isOn: $pushEnabled
            )
            
            if pushEnabled {
                SettingsToggleRow(
                    icon: "text.bubble",
                    title: "Story Reminders",
                    subtitle: "Remind me to record stories",
                    isOn: $storyReminders
                )
                
                SettingsToggleRow(
                    icon: "person.2",
                    title: "Family Updates",
                    subtitle: "When family members record",
                    isOn: $familyUpdates
                )
            }
            
            Divider()
                .background(theme.secondaryTextColor.opacity(0.3))
            
            SettingsToggleRow(
                icon: "envelope",
                title: "Email Notifications",
                isOn: $emailEnabled
            )
            
            if emailEnabled {
                SettingsToggleRow(
                    icon: "calendar",
                    title: "Weekly Digest",
                    subtitle: "Summary of family activity",
                    isOn: $weeklyDigest
                )
            }
        }
        .padding(.horizontal, theme.screenPadding)
    }
}

// MARK: - Privacy Section

struct PrivacySection: View {
    let settings: PrivacySettings
    let onExportData: () -> Void
    let onDeleteAccount: () -> Void
    @Environment(\.theme) var theme
    @State private var shareWithFamily: Bool
    @State private var allowSuggestions: Bool
    @State private var selectedRetention: DataRetention
    
    init(settings: PrivacySettings, onExportData: @escaping () -> Void, onDeleteAccount: @escaping () -> Void) {
        self.settings = settings
        self.onExportData = onExportData
        self.onDeleteAccount = onDeleteAccount
        _shareWithFamily = State(initialValue: settings.shareWithFamily)
        _allowSuggestions = State(initialValue: settings.allowSuggestions)
        _selectedRetention = State(initialValue: settings.dataRetention)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            SettingsToggleRow(
                icon: "person.3",
                title: "Share with Family",
                subtitle: "Allow family members to see your stories",
                isOn: $shareWithFamily
            )
            
            SettingsToggleRow(
                icon: "lightbulb",
                title: "AI Suggestions",
                subtitle: "Get personalized story suggestions",
                isOn: $allowSuggestions
            )
            
            Divider()
                .background(theme.secondaryTextColor.opacity(0.3))
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(theme.accentColor)
                    Text("Data Retention")
                        .font(.headline)
                        .foregroundColor(theme.textColor)
                }
                
                Text("How long we keep your stories")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
                
                Picker("Retention", selection: $selectedRetention) {
                    ForEach(DataRetention.allCases, id: \.self) { retention in
                        Text(retention.description).tag(retention)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding()
            
            SettingsRow(
                icon: "square.and.arrow.down",
                title: "Export My Data",
                subtitle: "Download all your stories and data"
            ) {
                onExportData()
            }
            
            SettingsRow(
                icon: "trash",
                title: "Delete Account",
                subtitle: "Permanently delete your account and data",
                isDestructive: true
            ) {
                onDeleteAccount()
            }
        }
        .padding(.horizontal, theme.screenPadding)
    }
}

// MARK: - Preferences Section

struct PreferencesSection: View {
    let settings: PreferenceSettings
    @Environment(\.theme) var theme
    @State private var autoPlayAudio: Bool
    @State private var hapticsEnabled: Bool
    @State private var selectedCategory: String
    
    init(settings: PreferenceSettings) {
        self.settings = settings
        _autoPlayAudio = State(initialValue: settings.autoPlayAudio)
        _hapticsEnabled = State(initialValue: settings.hapticsEnabled)
        _selectedCategory = State(initialValue: settings.defaultPromptCategory)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            SettingsToggleRow(
                icon: "play.circle",
                title: "Auto-play Audio",
                subtitle: "Automatically play stories when opened",
                isOn: $autoPlayAudio
            )
            
            SettingsToggleRow(
                icon: "hand.tap",
                title: "Haptic Feedback",
                subtitle: "Vibrate on interactions",
                isOn: $hapticsEnabled
            )
            
            Divider()
                .background(theme.secondaryTextColor.opacity(0.3))
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "text.bubble")
                        .foregroundColor(theme.accentColor)
                    Text("Default Prompt Category")
                        .font(.headline)
                        .foregroundColor(theme.textColor)
                }
                
                Picker("Category", selection: $selectedCategory) {
                    Text("Story").tag("story")
                    Text("Reflection").tag("reflection")
                    Text("Memory").tag("memory")
                }
                .pickerStyle(.segmented)
            }
            .padding()
        }
        .padding(.horizontal, theme.screenPadding)
    }
}

// MARK: - About Section

struct AboutSection: View {
    @Environment(\.theme) var theme
    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var showLicenses = false

    var body: some View {
        VStack(spacing: 16) {
            // App Info Card
            HStack {
                Image(systemName: "app.fill")
                    .font(.title2)
                    .foregroundColor(theme.accentColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text("StoryRide")
                        .font(.headline)
                        .foregroundColor(theme.textColor)
                    Text("Version 1.0.0 (Build 123)")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.cardBackgroundColor)
            )

            SettingsRow(
                icon: "bubble.left.and.bubble.right",
                title: "Send Feedback",
                subtitle: "Help us improve StoryRide"
            ) {}

            Divider()
                .background(theme.secondaryTextColor.opacity(0.3))

            SettingsRow(
                icon: "doc.text",
                title: "Terms of Service",
                subtitle: "Usage terms and conditions"
            ) {
                showTerms = true
            }

            SettingsRow(
                icon: "hand.raised",
                title: "Privacy Policy",
                subtitle: "How we protect your data"
            ) {
                showPrivacy = true
            }

            SettingsRow(
                icon: "list.bullet",
                title: "Open Source Licenses",
                subtitle: "Third-party software credits"
            ) {
                showLicenses = true
            }
        }
        .padding(.horizontal, theme.screenPadding)
    }
}

// MARK: - Reusable Components (Apple HIG Compliant)

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var showChevron: Bool = true
    var isDestructive: Bool = false
    let action: () -> Void
    @Environment(\.theme) var theme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // HIG: Icon in tinted rounded square (iOS Settings style)
                    
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isDestructive ? .red : theme.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)  // HIG: Body for list item titles
                        .foregroundColor(isDestructive ? .red : Color(.label))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(Color(.secondaryLabel))
                        .lineLimit(1)
                }

                Spacer()

                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
        .buttonStyle(.glass)  // Apple's native glass button style
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool
    @Environment(\.theme) var theme

    var body: some View {
        HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.accentColor)
            

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)  // HIG: Body for list item titles
                    .foregroundColor(Color(.label))
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(Color(.secondaryLabel))
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(theme.accentColor)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .glassEffect(.regular)
    }
}

// MARK: - Skeleton

struct SettingsSkeleton: View {
    @Environment(\.theme) var theme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 80)
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 24)
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 200, height: 16)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(theme.cardBackgroundColor)
                )
                .padding(.horizontal, theme.screenPadding)
                
                ForEach(0..<4, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 80)
                        .cornerRadius(12)
                        .padding(.horizontal, theme.screenPadding)
                }
            }
            .padding(.vertical, theme.screenPadding)
        }
        .background(theme.backgroundColor)
    }
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .themed(DarkTheme())
            .previewDisplayName("Dark Theme")
        
        SettingsView()
            .themed(LightTheme())
            .previewDisplayName("Light Theme")
    }
}
