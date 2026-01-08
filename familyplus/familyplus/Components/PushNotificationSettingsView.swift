//
//  PushNotificationSettingsView.swift
//  StoryRide
//
//  Push Notifications Settings - Manage notification preferences
//

import SwiftUI
import UserNotifications

// MARK: - Push Notification Settings Models

struct PushNotificationSettings: Codable {
    var storyReminders: Bool
    var storyRemindersTime: Date?
    var familyUpdates: Bool
    var requestResponses: Bool
    var weeklyDigest: Bool
    var mentions: Bool
    var triviaReminders: Bool
    var kidsContent: Bool
    var quietHoursEnabled: Bool
    var quietHoursStart: Date?
    var quietHoursEnd: Date?
}

struct NotificationStats: Codable {
    let totalReceived: Int
    let thisWeek: Int
    let engagementRate: Double
}

// MARK: - Push Notification Settings View

struct PushNotificationSettingsView: View {
    @State private var settings = PushNotificationSettings(
        storyReminders: true,
        storyRemindersTime: Date(),
        familyUpdates: true,
        requestResponses: true,
        weeklyDigest: false,
        mentions: true,
        triviaReminders: true,
        kidsContent: false,
        quietHoursEnabled: true,
        quietHoursStart: Date(),
        quietHoursEnd: Date()
    )
    @State private var notificationStats = NotificationStats(totalReceived: 156, thisWeek: 12, engagementRate: 0.78)
    @State private var isLoading = false
    @State private var showPermissionAlert = false
    @State private var permissionStatus: UNAuthorizationStatus = .notDetermined
    
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Permission Status Card
                    PermissionStatusCard(
                        status: permissionStatus,
                        onRequestPermission: requestPermission
                    )
                    
                    // Notification Stats
                    NotificationStatsCard(stats: notificationStats)
                    
                    // Quick Toggles
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Notification Types")
                            .font(.headline)
                            .foregroundColor(theme.textColor)
                            .padding(.horizontal)
                        
                        NotificationToggleRow(
                            icon: "mic.fill",
                            title: "Story Recording Reminders",
                            subtitle: "Remind me to record stories",
                            isOn: $settings.storyReminders
                        )
                        
                        NotificationToggleRow(
                            icon: "person.2.fill",
                            title: "Family Updates",
                            subtitle: "New stories from family members",
                            isOn: $settings.familyUpdates
                        )
                        
                        NotificationToggleRow(
                            icon: "envelope.fill",
                            title: "Request Responses",
                            subtitle: "When family responds to requests",
                            isOn: $settings.requestResponses
                        )
                        
                        NotificationToggleRow(
                            icon: "bell.badge.fill",
                            title: "Mentions",
                            subtitle: "When I'm mentioned in stories",
                            isOn: $settings.mentions
                        )
                        
                        NotificationToggleRow(
                            icon: "gamecontroller.fill",
                            title: "Trivia Reminders",
                            subtitle: "New trivia questions available",
                            isOn: $settings.triviaReminders
                        )
                        
                        NotificationToggleRow(
                            icon: "envelope.open.fill",
                            title: "Weekly Digest",
                            subtitle: "Summary of family activity",
                            isOn: $settings.weeklyDigest
                        )
                    }
                    .padding()
                    .background(theme.cardBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Quiet Hours
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "moon.fill")
                                .foregroundColor(.purple)
                            Text("Quiet Hours")
                                .font(.headline)
                                .foregroundColor(theme.textColor)
                            Spacer()
                            Toggle("", isOn: $settings.quietHoursEnabled)
                                .labelsHidden()
                        }
                        .padding(.horizontal)
                        
                        if settings.quietHoursEnabled {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("From")
                                        .font(.caption)
                                        .foregroundColor(theme.secondaryTextColor)
                                    DatePicker("", selection: Binding(
                                        get: { settings.quietHoursStart ?? Date() },
                                        set: { settings.quietHoursStart = $0 }
                                    ), displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .leading) {
                                    Text("To")
                                        .font(.caption)
                                        .foregroundColor(theme.secondaryTextColor)
                                    DatePicker("", selection: Binding(
                                        get: { settings.quietHoursEnd ?? Date() },
                                        set: { settings.quietHoursEnd = $0 }
                                    ), displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                    }
                    .padding()
                    .background(theme.cardBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Schedule Settings
                    if settings.storyReminders {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Reminder Time")
                                .font(.headline)
                                .foregroundColor(theme.textColor)
                            
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(theme.accentColor)
                                
                                DatePicker("", selection: Binding(
                                    get: { settings.storyRemindersTime ?? Date() },
                                    set: { settings.storyRemindersTime = $0 }
                                ), displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                
                                Spacer()
                                
                                Text("Daily reminder")
                                    .font(.caption)
                                    .foregroundColor(theme.secondaryTextColor)
                            }
                            .padding()
                            .background(theme.cardBackgroundColor)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                    }
                    
                    // Clear History Button
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear Notification History")
                        }
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .padding()
                    }
                }
                .padding(.vertical)
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveSettings()
                        dismiss()
                    }
                }
            }
            .onAppear {
                checkPermissionStatus()
            }
        }
    }
    
    private func checkPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                permissionStatus = settings.authorizationStatus
            }
        }
    }
    
    private func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    permissionStatus = .authorized
                } else {
                    permissionStatus = .denied
                    showPermissionAlert = true
                }
            }
        }
    }
    
    private func saveSettings() {
        // Save to UserDefaults or API
    }
}

// MARK: - Permission Status Card

struct PermissionStatusCard: View {
    let status: UNAuthorizationStatus
    let onRequestPermission: () -> Void
    
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: iconForStatus)
                    .font(.title)
                    .foregroundColor(colorForStatus)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notification Status")
                        .font(.headline)
                        .foregroundColor(theme.textColor)
                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
                
                Spacer()
                
                if status != .authorized {
                    Button(action: onRequestPermission) {
                        Text("Enable")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(theme.accentColor)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding()
        .background(theme.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
    
    private var iconForStatus: String {
        switch status {
        case .authorized: return "bell.fill"
        case .denied: return "bell.slash.fill"
        case .notDetermined: return "bell.badge.questionmark"
        case .provisional: return "bell.and.waves.left.and.right"
        case .ephemeral: return "bell.fill"
        @unknown default: return "bell.fill"
        }
    }
    
    private var colorForStatus: Color {
        switch status {
        case .authorized: return .green
        case .denied: return .red
        case .notDetermined: return .orange
        case .provisional: return .blue
        case .ephemeral: return .green
        @unknown default: return .gray
        }
    }
    
    private var statusText: String {
        switch status {
        case .authorized: return "Notifications are enabled"
        case .denied: return "Notifications are blocked"
        case .notDetermined: return "Tap Enable to allow notifications"
        case .provisional: return "Notifications are in provisional mode"
        case .ephemeral: return "App notifications active"
        @unknown default: return "Unknown status"
        }
    }
}

// MARK: - Notification Stats Card

struct NotificationStatsCard: View {
    let stats: NotificationStats
    
    @Environment(\.theme) var theme
    
    var body: some View {
        HStack(spacing: 24) {
            NotificationStatItem(
                value: "\(stats.totalReceived)",
                label: "Total",
                icon: "bell.fill",
                color: .blue
            )
            
            NotificationStatItem(
                value: "\(stats.thisWeek)",
                label: "This Week",
                icon: "calendar",
                color: .green
            )
            
            NotificationStatItem(
                value: "\(Int(stats.engagementRate * 100))%",
                label: "Engagement",
                icon: "chart.line.uptrend.xyaxis",
                color: .orange
            )
        }
        .padding()
        .background(theme.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

// MARK: - Notification Stat Item

struct NotificationStatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.textColor)
            
            Text(label)
                .font(.caption)
                .foregroundColor(theme.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Notification Toggle Row

struct NotificationToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    @Environment(\.theme) var theme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(theme.accentColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textColor)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Notification Center Preview Helper

struct NotificationPreviewHelper: View {
    @State private var notifications: [NotificationPreview] = []
    
    var body: some View {
        List {
            ForEach(notifications) { notification in
                NotificationPreviewRow(notification: notification)
            }
        }
    }
}

struct NotificationPreview: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let time: Date
    let type: NotificationType
    
    enum NotificationType {
        case story, request, trivia, mention
    }
}

struct NotificationPreviewRow: View {
    let notification: NotificationPreview
    
    var body: some View {
        HStack {
            Image(systemName: iconForType)
                .foregroundColor(.blue)
            VStack(alignment: .leading) {
                Text(notification.title)
                    .font(.headline)
                Text(notification.body)
                    .font(.subheadline)
                Text(notification.time, style: .relative)
                    .font(.caption)
            }
        }
    }
    
    private var iconForType: String {
        switch notification.type {
        case .story: return "mic.fill"
        case .request: return "envelope.fill"
        case .trivia: return "gamecontroller.fill"
        case .mention: return "at.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    PushNotificationSettingsView()
}
