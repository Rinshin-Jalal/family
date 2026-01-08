import Foundation
import SwiftUI
import Combine

enum AnalyticsEvent {
    case appOpen
    case appClose
    case storyView(storyId: String, storyTitle: String)
    case storyShare(storyId: String, storyTitle: String)
    case storyCreate
    case storyComplete
    case quoteGenerate
    case quoteShare
    case pollView(pollId: String)
    case pollVote(pollId: String, optionId: String)
    case pollCreate
    case wisdomSearch(query: String)
    case wisdomRequest(question: String)
    case inviteSend
    case inviteAccept
    case onboardingComplete
    case settingsChange(setting: String)
    
    var name: String {
        switch self {
        case .appOpen: return "app_open"
        case .appClose: return "app_close"
        case .storyView: return "story_view"
        case .storyShare: return "story_share"
        case .storyCreate: return "story_create"
        case .storyComplete: return "story_complete"
        case .quoteGenerate: return "quote_generate"
        case .quoteShare: return "quote_share"
        case .pollView: return "poll_view"
        case .pollVote: return "poll_vote"
        case .pollCreate: return "poll_create"
        case .wisdomSearch: return "wisdom_search"
        case .wisdomRequest: return "wisdom_request"
        case .inviteSend: return "invite_send"
        case .inviteAccept: return "invite_accept"
        case .onboardingComplete: return "onboarding_complete"
        case .settingsChange: return "settings_change"
        }
    }
    
    var category: String {
        switch self {
        case .appOpen, .appClose: return "app"
        case .storyView, .storyShare, .storyCreate, .storyComplete: return "story"
        case .quoteGenerate, .quoteShare: return "quote"
        case .pollView, .pollVote, .pollCreate: return "poll"
        case .wisdomSearch, .wisdomRequest: return "wisdom"
        case .inviteSend, .inviteAccept: return "invite"
        case .onboardingComplete: return "onboarding"
        case .settingsChange: return "settings"
        }
    }
    
    var properties: [String: Any] {
        switch self {
        case .storyView(let storyId, let storyTitle):
            return ["story_id": storyId, "story_title": storyTitle]
        case .storyShare(let storyId, let storyTitle):
            return ["story_id": storyId, "story_title": storyTitle]
        case .pollView(let pollId):
            return ["poll_id": pollId]
        case .pollVote(let pollId, let optionId):
            return ["poll_id": pollId, "option_id": optionId]
        case .wisdomSearch(let query):
            return ["query": query]
        case .wisdomRequest(let question):
            return ["question": question]
        case .settingsChange(let setting):
            return ["setting": setting]
        default:
            return [:]
        }
    }
}

@MainActor
final class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()
    
    @Published var isEnabled = true
    @Published var sessionId = UUID()
    
    private var eventQueue: [AnalyticsEvent] = []
    private let queueLimit = 20
    
    private init() {
        Task {
            await loadSession()
        }
    }
    
    func track(_ event: AnalyticsEvent) {
        guard isEnabled else { return }
        
        let eventData: [String: Any] = [
            "event_type": event.name,
            "event_category": event.category,
            "properties": event.properties,
            "session_id": sessionId.uuidString,
        ]
        
        Task {
            await sendEvent(eventData)
        }
    }
    
    func trackViewStory(_ storyId: String, _ storyTitle: String) {
        track(.storyView(storyId: storyId, storyTitle: storyTitle))
    }
    
    func trackShareStory(_ storyId: String, _ storyTitle: String) {
        track(.storyShare(storyId: storyId, storyTitle: storyTitle))
    }
    
    func trackPollVote(_ pollId: String, _ optionId: String) {
        track(.pollVote(pollId: pollId, optionId: optionId))
    }
    
    func trackSearch(_ query: String) {
        track(.wisdomSearch(query: query))
    }
    
    func onAppOpen() {
        sessionId = UUID()
        track(.appOpen)
    }
    
    func onAppClose() {
        track(.appClose)
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
    
    private func loadSession() async {
        if let savedSessionId = UserDefaults.standard.string(forKey: "analytics_session_id"),
           let uuid = UUID(uuidString: savedSessionId) {
            sessionId = uuid
        }
    }
    
    private var baseURL: String {
        #if DEBUG
        return "http://localhost:8787"
        #else
        return "https://family-plus-backend.your-subdomain.workers.dev"
        #endif
    }
}

@MainActor
final class FeatureFlagService: ObservableObject {
    static let shared = FeatureFlagService()
    
    @Published var flags: [String: FeatureFlagData] = [:]
    @Published var isLoading = false
    
    private init() {}
    
    func loadFlags() async {
        isLoading = true
        
        do {
            let url = URL(string: "\(baseURL)/api/analytics/feature-flags")!
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let features = json["features"] as? [String: [String: Any]] {
                self.flags = features.mapValues { FeatureFlagData(from: $0) }
            }
        } catch {
            print("Failed to load feature flags: \(error)")
        }
        
        isLoading = false
    }
    
    func isEnabled(_ feature: String) -> Bool {
        flags[feature] != nil
    }
    
    func requiresUpgrade(for feature: String) -> Bool {
        guard let flag = flags[feature] else { return true }
        return flag.minimumPlanTier != "free"
    }
    
    private var baseURL: String {
        #if DEBUG
        return "http://localhost:8787"
        #else
        return "https://family-plus-backend.your-subdomain.workers.dev"
        #endif
    }
}

struct FeatureFlagData {
    let minimumPlanTier: String
    let rolloutPercentage: Int
    
    init(from dictionary: [String: Any]) {
        self.minimumPlanTier = dictionary["minimumPlanTier"] as? String ?? "free"
        self.rolloutPercentage = dictionary["rolloutPercentage"] as? Int ?? 100
    }
}

struct FeatureGate<Content: View, Fallback: View>: View {
    let feature: String
    let fallback: Fallback
    let content: Content
    
    @StateObject private var flagService = FeatureFlagService.shared
    
    init(
        feature: String,
        @ViewBuilder fallback: () -> Fallback,
        @ViewBuilder content: () -> Content
    ) {
        self.feature = feature
        self.fallback = fallback()
        self.content = content()
    }
    
    var body: some View {
        Group {
            if flagService.isEnabled(feature) {
                content
            } else {
                fallback
            }
        }
    }
}

#Preview("Analytics Service") {
    VStack(spacing: 20) {
        Text("Analytics & Feature Flags")
            .font(.headline)
        
        Button("Track App Open") {
            AnalyticsService.shared.track(.appOpen)
        }
        
        Button("Track Story View") {
            AnalyticsService.shared.trackViewStory("story-123", "The Great Fire")
        }
        
        Button("Track Poll Vote") {
            AnalyticsService.shared.trackPollVote("poll-123", "option-a")
        }
        
        Button("Load Feature Flags") {
            Task {
                await FeatureFlagService.shared.loadFlags()
            }
        }
    }
    .padding()
}
