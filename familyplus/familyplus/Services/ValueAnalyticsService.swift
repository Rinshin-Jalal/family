//
//  ValueAnalyticsService.swift
//  StoryRide
//
//  Value-based analytics - track what users create, not engagement
//  Phase 5: Metrics transformation
//

import Foundation
import SwiftUI
import Combine

// MARK: - Value Analytics Events

enum ValueAnalyticsEvent {
    // App Lifecycle
    case appOpen
    case appClose

    // Content Creation (PRIMARY - value produced)
    case storyCapture(method: CaptureMethod)
    case storyComplete(storyId: String, panelCount: Int)
    case collectionCreate(title: String, storyCount: Int)

    // Value Extraction (SECONDARY - artifacts delivered)
    case storyExport(format: String, storyId: String)
    case storyShare(storyId: String, method: ShareMethod)
    case podcastGenerate(storyId: String)

    // Discovery (TERTIARY - findability signal)
    case searchQuery(query: String, resultsCount: Int)
    case filterApply(filters: [String])

    // Storage & Resources (subscription signal)
    case storageUsed(bytes: Int64, tier: String)
    case storageThresholdReached(threshold: ValueStorageThreshold)

    // Milestones (progress, not gamification)
    case milestoneReached(milestone: ValueMilestone)

    // Onboarding (simplified)
    case onboardingComplete(preserveTypes: [String], captureTarget: String)

    // DEPRECATED: Social/engagement events
    case pollView(pollId: String)
    case pollVote(pollId: String, optionId: String)

    var name: String {
        switch self {
        case .appOpen: return "app_open"
        case .appClose: return "app_close"
        case .storyCapture: return "story_capture"
        case .storyComplete: return "story_complete"
        case .collectionCreate: return "collection_create"
        case .storyExport: return "story_export"
        case .storyShare: return "story_share"
        case .podcastGenerate: return "podcast_generate"
        case .searchQuery: return "search_query"
        case .filterApply: return "filter_apply"
        case .storageUsed: return "storage_used"
        case .storageThresholdReached: return "storage_threshold_reached"
        case .milestoneReached: return "milestone_reached"
        case .onboardingComplete: return "onboarding_complete"
        case .pollView: return "poll_view"
        case .pollVote: return "poll_vote"
        }
    }

    var category: String {
        switch self {
        case .appOpen, .appClose: return "app_lifecycle"
        case .storyCapture, .storyComplete, .collectionCreate: return "content_creation"
        case .storyExport, .storyShare, .podcastGenerate: return "value_extraction"
        case .searchQuery, .filterApply: return "discovery"
        case .storageUsed, .storageThresholdReached: return "resources"
        case .milestoneReached: return "progress"
        case .onboardingComplete: return "onboarding"
        case .pollView, .pollVote: return "deprecated_social"
        }
    }

    var properties: [String: Any] {
        switch self {
        case .appOpen, .appClose:
            return [:]
        case .storyCapture(let method):
            return ["capture_method": method.rawValue]
        case .storyComplete(let storyId, let panelCount):
            return ["story_id": storyId, "panel_count": panelCount]
        case .collectionCreate(let title, let storyCount):
            return ["collection_title": title, "story_count": storyCount]
        case .storyExport(let format, let storyId):
            return ["format": format, "story_id": storyId]
        case .storyShare(let storyId, let method):
            return ["story_id": storyId, "share_method": method.rawValue]
        case .podcastGenerate(let storyId):
            return ["story_id": storyId]
        case .searchQuery(let query, let resultsCount):
            return ["query": query, "results_count": resultsCount]
        case .filterApply(let filters):
            return ["filters": filters]
        case .storageUsed(let bytes, let tier):
            return ["bytes": bytes, "tier": tier]
        case .storageThresholdReached(let threshold):
            return ["threshold": threshold.rawValue]
        case .milestoneReached(let milestone):
            return ["milestone": milestone.rawValue]
        case .onboardingComplete(let preserveTypes, let captureTarget):
            return ["preserve_types": preserveTypes, "capture_target": captureTarget]
        case .pollView(let pollId):
            return ["poll_id": pollId]
        case .pollVote(let pollId, let optionId):
            return ["poll_id": pollId, "option_id": optionId]
        }
    }

    var isValueMetric: Bool {
        switch self {
        case .pollView, .pollVote: return false
        default: return true
        }
    }
}

// MARK: - Supporting Types

enum CaptureMethod: String {
    case record = "record"
    case upload = "upload"
    case type = "type"
    case phone = "phone"
    case externalImport = "import"
}

enum ShareMethod: String {
    case link = "link"
    case file = "file"
    case publicLink = "public_link"
}

// Value analytics storage threshold (not to be confused with SubscriptionTier in SubscriptionView)
enum ValueStorageThreshold: String {
    case fiftyPercent = "50%"
    case seventyFivePercent = "75%"
    case ninetyPercent = "90%"
    case full = "100%"
}

// Value analytics milestone (not to be confused with Milestone struct in Achievement.swift)
enum ValueMilestone: String {
    case firstStory = "first_story"
    case tenStories = "ten_stories"
    case fiftyStories = "fifty_stories"
    case hundredStories = "hundred_stories"
    case firstExport = "first_export"
    case firstCollection = "first_collection"
    case firstPodcast = "first_podcast"
}

// MARK: - Value Analytics Service

@MainActor
final class ValueAnalyticsService: ObservableObject {
    static let shared = ValueAnalyticsService()

    @Published var isEnabled = true
    @Published var sessionId = UUID()

    @Published var storiesCaptured: Int = 0
    @Published var storageUsedBytes: Int64 = 0
    @Published var exportsCompleted: Int = 0
    @Published var searchesPerformed: Int = 0

    private init() {
        Task {
            await loadMetrics()
            await loadSession()
        }
    }

    func track(_ event: ValueAnalyticsEvent) {
        guard isEnabled else { return }

        updateMetrics(for: event)

        let eventData: [String: Any] = [
            "event_type": event.name,
            "event_category": event.category,
            "properties": event.properties,
            "session_id": sessionId.uuidString,
            "is_value_metric": event.isValueMetric,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]

        Task {
            await sendEvent(eventData)
        }
    }

    func trackStoryCapture(method: CaptureMethod) {
        track(.storyCapture(method: method))
        storiesCaptured += 1
    }

    func trackStoryComplete(storyId: String, panelCount: Int) {
        track(.storyComplete(storyId: storyId, panelCount: panelCount))
    }

    func trackStoryExport(format: String, storyId: String) {
        track(.storyExport(format: format, storyId: storyId))
        exportsCompleted += 1
    }

    func trackStoryShare(storyId: String, method: ShareMethod) {
        track(.storyShare(storyId: storyId, method: method))
    }

    func trackSearch(query: String, resultsCount: Int) {
        track(.searchQuery(query: query, resultsCount: resultsCount))
        searchesPerformed += 1
    }

    func trackStorageUsed(bytes: Int64, tierName: String, maxBytes: Int64) {
        storageUsedBytes = bytes
        track(.storageUsed(bytes: bytes, tier: tierName))

        let percentage = Double(bytes) / Double(maxBytes)

        if percentage >= 1.0 {
            track(.storageThresholdReached(threshold: .full))
        } else if percentage >= 0.9 {
            track(.storageThresholdReached(threshold: .ninetyPercent))
        } else if percentage >= 0.75 {
            track(.storageThresholdReached(threshold: .seventyFivePercent))
        } else if percentage >= 0.5 {
            track(.storageThresholdReached(threshold: .fiftyPercent))
        }
    }

    func trackMilestone(_ milestone: ValueMilestone) {
        track(.milestoneReached(milestone: milestone))
    }

    func onAppOpen() {
        sessionId = UUID()
        track(.appOpen)
    }

    func onAppClose() {
        track(.appClose)
    }

    // MARK: - Onboarding Analytics (Psychology Flow)

    func trackOnboardingQuizAnswer(question: String, answer: String) {
        let eventData: [String: Any] = [
            "event_type": "onboarding_quiz_answer",
            "event_category": "onboarding",
            "properties": [
                "question": question,
                "answer": answer
            ],
            "session_id": sessionId.uuidString,
            "is_value_metric": false,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]

        Task {
            await sendEvent(eventData)
        }
    }

    func trackCustomEvent(name: String, properties: [String: Any] = [:]) {
        let eventData: [String: Any] = [
            "event_type": name,
            "event_category": "custom",
            "properties": properties,
            "session_id": sessionId.uuidString,
            "is_value_metric": true,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]

        Task {
            await sendEvent(eventData)
        }
    }

    private func updateMetrics(for event: ValueAnalyticsEvent) {
        switch event {
        case .storyCapture:
            storiesCaptured += 1
        case .storyExport:
            exportsCompleted += 1
        case .searchQuery:
            searchesPerformed += 1
        case .storageUsed(let bytes, _):
            storageUsedBytes = bytes
        default:
            break
        }
    }

    private func sendEvent(_ event: [String: Any]) async {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: event)
            guard let url = URL(string: "\(baseURL)/api/analytics/track") else { return }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData

            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode) {
            }
        } catch {
            print("Analytics error: \(error)")
        }
    }

    private func loadMetrics() async {
        storiesCaptured = UserDefaults.standard.integer(forKey: "value_analytics_stories")
        storageUsedBytes = Int64(UserDefaults.standard.integer(forKey: "value_analytics_storage"))
        let storedExports = UserDefaults.standard.object(forKey: "value_analytics_exports") as? Int
        exportsCompleted = storedExports ?? 0
        searchesPerformed = UserDefaults.standard.integer(forKey: "value_analytics_searches")
    }

    private func loadSession() async {
        if let savedSessionId = UserDefaults.standard.string(forKey: "value_analytics_session"),
           let uuid = UUID(uuidString: savedSessionId) {
            sessionId = uuid
        }
    }

    private func saveMetrics() {
        UserDefaults.standard.set(storiesCaptured, forKey: "value_analytics_stories")
        UserDefaults.standard.set(Int(storageUsedBytes), forKey: "value_analytics_storage")
        UserDefaults.standard.set(exportsCompleted, forKey: "value_analytics_exports")
        UserDefaults.standard.set(searchesPerformed, forKey: "value_analytics_searches")
        UserDefaults.standard.set(sessionId.uuidString, forKey: "value_analytics_session")
    }

    private var baseURL: String {
        #if DEBUG
        return "http://localhost:8787"
        #else
        return "https://family-plus-backend.workers.dev"
        #endif
    }
}

// MARK: - Preview

#Preview("Value Analytics") {
    VStack(spacing: 20) {
        Text("Value-Based Analytics")
            .font(.headline)

        VStack(alignment: .leading, spacing: 8) {
            Text("Stories: \(ValueAnalyticsService.shared.storiesCaptured)")
            Text("Storage: \(ValueAnalyticsService.shared.storageUsedBytes)")
            Text("Exports: \(ValueAnalyticsService.shared.exportsCompleted)")
            Text("Searches: \(ValueAnalyticsService.shared.searchesPerformed)")
        }
        .font(.caption)

        Button("Track Story") {
            ValueAnalyticsService.shared.trackStoryCapture(method: .record)
        }

        Button("Track Export") {
            ValueAnalyticsService.shared.trackStoryExport(format: "pdf", storyId: "123")
        }
    }
    .padding()
}
