//
//  SettingsView.swift
//  StoryRide
//
//  Settings screen - Simple and clean like Hub and Family
//

import SwiftUI
import Auth

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss
    @State private var loadingState: LoadingState<ProfileSettingsData> = .loading
    @State private var showEditProfile = false
    @State private var showFamilySettings = false
    @State private var showExportData = false
    @State private var showDeleteConfirmation = false
    @State private var isExporting = false
    @State private var exportURL: URL?
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Group {
                switch loadingState {
                case .loading:
                    SettingsSkeleton()
                case .loaded(let data):
                    SettingsContent(
                        data: data,
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
            .navigationTitle("Settings")
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
            // Sign out from Supabase
            try? await SupabaseService.shared.signOut()

            // Clear auth token
            AuthService.shared.clearToken()

            // Clear onboarding flag to return to onboarding flow
            UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
            UserDefaults.standard.removeObject(forKey: "hasCreatedFamily")
            UserDefaults.standard.removeObject(forKey: "auth_user_id")
            UserDefaults.standard.removeObject(forKey: "auth_token")
            UserDefaults.standard.removeObject(forKey: "family_name")

            // Clear any pending invite codes
            UserDefaults.standard.removeObject(forKey: "pending_invite_code")

            await MainActor.run {
                // Dismiss settings
                dismiss()

                // Force app to refresh by triggering app state change
                // This will cause ContentView to check auth state and show onboarding
                NotificationCenter.default.post(name: .init("AuthStateDidChange"), object: nil)
            }
        }
    }

    // MARK: - Data Loading

    private func loadUserProfile() async throws -> UserProfile {
        // Get userId from UserDefaults (set by SupabaseService during auth)
        let storedUserId = UserDefaults.standard.string(forKey: "auth_user_id")

        // Get email from Supabase auth session
        let session = try await SupabaseService.shared.getCurrentSession()
        let email = session?.user.email ?? ""

        // Get family members to find current user's name/avatar
        let members = try await APIService.shared.getFamilyMembers()

        // Try to find current user by auth_user_id, fall back to organizer, then first member
        let currentUser = members.first(where: { $0.authUserId == storedUserId })
            ?? members.first(where: { $0.role == "organizer" })
            ?? members.first

        guard let user = currentUser else {
            throw NSError(domain: "SettingsView", code: -1, userInfo: [NSLocalizedDescriptionKey: "No family members found"])
        }

        return UserProfile(
            id: user.id,
            name: user.fullName ?? "Family Member",
            email: email,
            avatarEmoji: user.avatarUrl ?? "👤",
            theme: .dark,
            joinedAt: Date() // TODO: Get from API
        )
    }

    private func loadFamilyInfo() async throws -> FamilySettingsInfo {
        let family = try await APIService.shared.getFamily()
        let members = try await APIService.shared.getFamilyMembers()

        return FamilySettingsInfo(
            id: family.id,
            name: family.name,
            memberCount: members.count,
            inviteSlug: family.invite_slug
        )
    }

    private func loadUserStats() async throws -> UserStats {
        // Calculate from actual stories
        let stories = try await APIService.shared.getStories()
        let totalRecordings = stories.reduce(0.0) { $0 + Double($1.voiceCount) }

        // TODO: Implement topic tagging in backend
        let favoriteTopics: [String] = []

        return UserStats(
            totalStories: stories.count,
            totalRecordings: totalRecordings,
            favoriteTopics: favoriteTopics.isEmpty ? ["Family", "Memories", "Stories"] : favoriteTopics
        )
    }

    private func loadUserSettings() async throws -> UserSettings {
        // Fetch from backend API
        let apiSettings = try await APIService.shared.getUserSettings()

        // Map backend response to local model
        return UserSettings(
            notifications: NotificationSettings(
                pushEnabled: apiSettings.push_enabled,
                emailEnabled: apiSettings.email_enabled
            ),
            privacy: PrivacySettings(
                shareWithFamily: apiSettings.share_with_family,
                allowSuggestions: apiSettings.allow_suggestions,
                dataRetention: DataRetention(rawValue: apiSettings.data_retention.replacingOccurrences(of: "_", with: " ")) ?? .forever
            ),
            preferences: PreferenceSettings(
                autoPlayAudio: UserDefaults.standard.bool(forKey: "autoPlayAudio"),
                defaultPromptCategory: UserDefaults.standard.string(forKey: "defaultPromptCategory") ?? "story",
                hapticsEnabled: UserDefaults.standard.bool(forKey: "hapticsEnabled")
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
            .task {
                // Load current user's name from API
                do {
                    let members = try await APIService.shared.getFamilyMembers()
                    let storedUserId = UserDefaults.standard.string(forKey: "auth_user_id")
                    let currentUser = members.first(where: { $0.authUserId == storedUserId })
                        ?? members.first(where: { $0.role == "organizer" })
                        ?? members.first
                    name = currentUser?.fullName ?? ""
                } catch {
                    print("[EditProfile] Failed to load: \(error)")
                }
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
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            NavigationCoordinator.shared.navigateToFamily(action: .showManageMembers)
                        }
                    } label: {
                        HStack {
                            Text("Manage Members")
                                .foregroundColor(theme.textColor)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(theme.secondaryTextColor)
                        }
                    }
                }

                Section("Add Elder") {
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            NavigationCoordinator.shared.navigateToFamily(action: .showAddElder)
                        }
                    } label: {
                        HStack {
                            Text("Add Elder (Phone)")
                                .foregroundColor(theme.textColor)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(theme.secondaryTextColor)
                        }
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
            .task {
                do {
                    let family = try await APIService.shared.getFamily()
                    familyName = family.name
                    inviteSlug = family.invite_slug
                } catch {
                    print("[FamilySettings] Failed to load: \(error)")
                }
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
    let family: FamilySettingsInfo
    let stats: UserStats
    let settings: UserSettings
}

struct UserProfile: Identifiable {
    let id: String
    let name: String
    let email: String
    let avatarEmoji: String
    let theme: AppTheme
    let joinedAt: Date
}

// RENAMED from FamilyInfo to avoid conflict with APIService.FamilyInfo
struct FamilySettingsInfo: Identifiable {
    let id: String
    let name: String
    let memberCount: Int
    let inviteSlug: String
}

struct UserStats {
    let totalStories: Int
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
    // Removed: storyReminders, familyUpdates, weeklyDigest (engagement spam)
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


// MARK: - Main Content

struct SettingsContent: View {
    let data: ProfileSettingsData
    @Environment(\.theme) var theme
    let onEditProfile: () -> Void
    let onFamilySettings: () -> Void
    let onExportData: () -> Void
    let onDeleteAccount: () -> Void
    let onSignOut: () -> Void

    var body: some View {
        List {
            // Profile Header Section
            Section {
                ProfileHeaderCard(user: data.user, stats: data.stats)
            }

            // Profile Section
            Section {
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
            } header: {
                Text("Profile")
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryTextColor)
            }

            // Account Section
            Section {
                SettingsRow(
                    icon: "person.crop.circle",
                    title: "Account",
                    subtitle: "Manage your account settings"
                ) {}

                SettingsRow(
                    icon: "calendar",
                    title: "Member Since",
                    subtitle: formatDate(data.user.joinedAt),
                    showChevron: false
                ) {}
            } header: {
                Text("Account")
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryTextColor)
            }
            
            // Notifications Section
            Section {
                NotificationSection(settings: data.settings.notifications)
            } header: {
                Text("Notifications")
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryTextColor)
            }
            
            // Privacy Section
            Section {
                PrivacySection(settings: data.settings.privacy, onExportData: onExportData, onDeleteAccount: onDeleteAccount)
            } header: {
                Text("Privacy")
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryTextColor)
            }
            
            // App Preferences Section
            Section {
                PreferencesSection(settings: data.settings.preferences)
            } header: {
                Text("App Preferences")
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryTextColor)
            }
            
            // About Section
            Section {
                AboutSection()
            } header: {
                Text("About")
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryTextColor)
            }
            
            // Sign Out Section
            Section {
                SettingsRow(
                    icon: "rectangle.portrait.and.arrow.right",
                    title: "Sign Out",
                    subtitle: "Sign out of your account",
                    isDestructive: true
                ) {
                    onSignOut()
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Persona-Specific Settings Variants - REMOVED

// (All persona-specific variants like ChildSettingsContent, ParentSettingsContent, 
// TeenSettingsContent, and ElderNotAvailableView have been removed to unify the theme)

// MARK: - Profile Header Card

struct ProfileHeaderCard: View {
    let user: UserProfile
    let stats: UserStats
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 20) {
            // Profile Identity Section
            HStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(theme.accentColor.opacity(0.15))
                        .frame(width: 72, height: 72)
                    Text(user.avatarEmoji)
                        .font(.system(size: 32))
                }

                // Name & Subtitle
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.name)
                        .font(.title2.weight(.semibold))
                        .foregroundColor(theme.textColor)
                    Text(user.theme.displayName)
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryTextColor)
                }

                Spacer()
            }

            // Stats Row
            HStack(spacing: 0) {
                StatItem(value: "\(stats.totalStories)", label: "Stories", icon: "book.fill")

                Divider()
                    .frame(height: 40)
                    .padding(.horizontal, 16)

                StatItem(value: stats.formattedRecordings, label: "Recorded", icon: "waveform")
            }
            .padding(.vertical, 8)
        }
        .padding(20)
        .background(theme.cardBackgroundColor)
        .cornerRadius(12)
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
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundColor(theme.textColor)
            }

            Text(label)
                .font(.caption2)
                .foregroundColor(theme.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Notification Section

struct NotificationSection: View {
    let settings: NotificationSettings
    @Environment(\.theme) var theme
    @State private var pushEnabled: Bool
    @State private var emailEnabled: Bool
    @State private var isSaving = false

    init(settings: NotificationSettings) {
        self.settings = settings
        _pushEnabled = State(initialValue: settings.pushEnabled)
        _emailEnabled = State(initialValue: settings.emailEnabled)
    }

    var body: some View {
        SettingsToggleRow(
            icon: "bell.fill",
            title: "Push Notifications",
            subtitle: "Wisdom requests and important updates",
            isOn: Binding(
                get: { pushEnabled },
                set: { newValue in
                    pushEnabled = newValue
                    saveSettings()
                }
            )
        )

        SettingsToggleRow(
            icon: "envelope",
            title: "Email Notifications",
            isOn: Binding(
                get: { emailEnabled },
                set: { newValue in
                    emailEnabled = newValue
                    saveSettings()
                }
            )
        )
    }

    private func saveSettings() {
        Task {
            try? await APIService.shared.updateUserSettings(settings: UserSettingsUpdateRequest(
                push_enabled: pushEnabled,
                email_enabled: emailEnabled,
                share_with_family: nil,
                allow_suggestions: nil,
                data_retention: nil
            ))
        }
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
        SettingsToggleRow(
            icon: "person.3",
            title: "Share with Family",
            subtitle: "Allow family members to see your stories",
            isOn: Binding(
                get: { shareWithFamily },
                set: { newValue in
                    shareWithFamily = newValue
                    saveSettings()
                }
            )
        )

        SettingsToggleRow(
            icon: "lightbulb",
            title: "AI Suggestions",
            subtitle: "Get personalized story suggestions",
            isOn: Binding(
                get: { allowSuggestions },
                set: { newValue in
                    allowSuggestions = newValue
                    saveSettings()
                }
            )
        )

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

            Picker("Retention", selection: Binding(
                get: { selectedRetention },
                set: { newValue in
                    selectedRetention = newValue
                    saveSettings()
                }
            )) {
                ForEach(DataRetention.allCases, id: \.self) { retention in
                    Text(retention.description).tag(retention)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.vertical, 8)

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

    private func saveSettings() {
        Task {
            // Convert data retention format (spaces to underscores)
            let retentionValue = selectedRetention.rawValue.replacingOccurrences(of: " ", with: "_")

            try? await APIService.shared.updateUserSettings(settings: UserSettingsUpdateRequest(
                push_enabled: nil,
                email_enabled: nil,
                share_with_family: shareWithFamily,
                allow_suggestions: allowSuggestions,
                data_retention: retentionValue
            ))
        }
    }
}

// MARK: - Preferences Section

struct PreferencesSection: View {
    let settings: PreferenceSettings
    @Environment(\.theme) var theme
    @AppStorage("autoPlayAudio") private var autoPlayAudio: Bool = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("defaultPromptCategory") private var selectedCategory: String = "story"

    init(settings: PreferenceSettings) {
        self.settings = settings
        // Set UserDefaults defaults for @AppStorage properties
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: "autoPlayAudio") {
            defaults.set(settings.autoPlayAudio, forKey: "autoPlayAudio")
        }
        if !defaults.bool(forKey: "hapticsEnabled") {
            defaults.set(settings.hapticsEnabled, forKey: "hapticsEnabled")
        }
        if defaults.string(forKey: "defaultPromptCategory") == nil {
            defaults.set(settings.defaultPromptCategory, forKey: "defaultPromptCategory")
        }
    }

    var body: some View {
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
        .padding(.vertical, 8)
    }
}


// MARK: - About Section

struct AboutSection: View {
    @Environment(\.theme) var theme
    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var showLicenses = false

    var body: some View {
        // App Info
        HStack {
            Image(systemName: "app.fill")
                .font(.title2)
                .foregroundColor(theme.accentColor)

            VStack(alignment: .leading, spacing: 4) {
                Text("Family+")
                    .font(.headline)
                    .foregroundColor(theme.textColor)
                Text("Version 1.0.0")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
            }

            Spacer()
        }
        .padding(.vertical, 8)

        SettingsRow(
            icon: "bubble.left.and.bubble.right",
            title: "Send Feedback",
            subtitle: "Help us improve Family+"
        ) {
            // TODO: Open feedback form or email
            if let url = URL(string: "mailto:support@storyrd.app") {
                UIApplication.shared.open(url)
            }
        }

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
}

// MARK: - Reusable Components

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
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isDestructive ? .red : theme.accentColor)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(isDestructive ? .red : theme.textColor)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                        .lineLimit(1)
                }

                Spacer()

                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.secondaryTextColor.opacity(0.5))
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
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
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(theme.textColor)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(theme.accentColor)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Skeleton

struct SettingsSkeleton: View {
    @Environment(\.theme) var theme
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 72, height: 72)
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 24)
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 200, height: 16)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            
            Section {
                ForEach(0..<3, id: \.self) { _ in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 24, height: 24)
                        VStack(alignment: .leading, spacing: 4) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 120, height: 16)
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 80, height: 12)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
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
