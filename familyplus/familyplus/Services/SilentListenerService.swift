//
//  SilentListenerService.swift
//  StoryRide
//
//  Silent Listener Mode - Track consumption without contribution pressure
//

import SwiftUI
import Combine

// MARK: - Silent Listener State

@MainActor
class SilentListenerService: ObservableObject {
    static let shared = SilentListenerService()

    // MARK: - Published State

    @Published var isSilentMode: Bool = true
    @Published var listeningStats: [String: ListeningStats] = [:]

    // MARK: - Listening Stats Model

    struct ListeningStats: Codable {
        let responseId: String
        var listenCount: Int
        var lastListenedAt: Date?
        var totalListenTime: TimeInterval  // seconds
        var completionRate: Double  // 0-1, percentage of audio typically completed

        var formattedListenTime: String {
            let minutes = Int(totalListenTime) / 60
            let seconds = Int(totalListenTime) % 60
            return minutes > 0 ? "\(minutes)m \(seconds)s" : "\(seconds)s"
        }
    }

    // MARK: - Listen Events

    func trackListenStart(responseId: String) {
        if var existing = listeningStats[responseId] {
            existing.lastListenedAt = Date()
            listeningStats[responseId] = existing
        } else {
            listeningStats[responseId] = ListeningStats(
                responseId: responseId,
                listenCount: 1,
                lastListenedAt: Date(),
                totalListenTime: 0,
                completionRate: 0
            )
        }
        saveStats()
    }

    func trackListenProgress(responseId: String, seconds: TimeInterval) {
        guard var stats = listeningStats[responseId] else { return }
        stats.totalListenTime += seconds
        listeningStats[responseId] = stats
    }

    func trackListenComplete(responseId: String, completionRate: Double) {
        guard var stats = listeningStats[responseId] else { return }
        stats.listenCount += 1
        stats.completionRate = max(stats.completionRate, completionRate)
        stats.lastListenedAt = Date()
        listeningStats[responseId] = stats
        saveStats()
    }

    // MARK: - Stats Queries

    func getStats(for responseId: String) -> ListeningStats? {
        listeningStats[responseId]
    }

    func hasListened(to responseId: String) -> Bool {
        listeningStats[responseId]?.listenCount ?? 0 > 0
    }

    func totalListenTime(for responseId: String) -> TimeInterval {
        listeningStats[responseId]?.totalListenTime ?? 0
    }

    func listenCount(for responseId: String) -> Int {
        listeningStats[responseId]?.listenCount ?? 0
    }

    // MARK: - Persistence

    private let statsKey = "silentListenerStats"

    private func saveStats() {
        if let encoded = try? JSONEncoder().encode(listeningStats) {
            UserDefaults.standard.set(encoded, forKey: statsKey)
        }
    }

    private func loadStats() {
        guard let data = UserDefaults.standard.data(forKey: statsKey),
              let decoded = try? JSONDecoder().decode([String: ListeningStats].self, from: data) else {
            return
        }
        listeningStats = decoded
    }

    // MARK: - Silent Mode Toggle

    func toggleSilentMode() {
        isSilentMode.toggle()
        UserDefaults.standard.set(isSilentMode, forKey: "silentModeEnabled")
    }

    init() {
        loadStats()
        isSilentMode = UserDefaults.standard.bool(forKey: "silentModeEnabled")
    }
}

// MARK: - Silent Listener Indicator View

struct SilentListenerIndicator: View {
    let listenCount: Int
    let totalListenTime: TimeInterval
    let theme: PersonaTheme

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: listenCount > 0 ? "headphones.circle.fill" : "headphones.circle")
                .font(.caption2)
                .foregroundColor(listenCount > 0 ? .green.opacity(0.7) : theme.secondaryTextColor.opacity(0.5))

            if listenCount > 0 {
                Text("\(listenCount)×")
                    .font(.caption2)
                    .foregroundColor(theme.secondaryTextColor)

                Text("·")
                    .font(.caption2)
                    .foregroundColor(theme.secondaryTextColor.opacity(0.3))

                Text(formattedTime)
                    .font(.caption2)
                    .foregroundColor(theme.secondaryTextColor)
            }
        }
    }

    private var formattedTime: String {
        let minutes = Int(totalListenTime) / 60
        if minutes > 0 {
            return "\(minutes)m listened"
        } else {
            let seconds = Int(totalListenTime)
            return "\(seconds)s listened"
        }
    }
}

// MARK: - Silent Mode Badge

struct SilentModeBadge: View {
    @Environment(\.theme) var theme

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "theatermasks")
                .font(.caption2)

            Text("Listening")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(.purple.opacity(0.8))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(.purple.opacity(0.12))
        )
    }
}

// MARK: - Heard By Section (for response cards)

struct HeardBySection: View {
    let heardCount: Int
    let hasListened: Bool
    let theme: PersonaTheme

    var body: some View {
        HStack(spacing: 6) {
            // Headphone icon with count
            Image(systemName: hasListened ? "headphones.circle.fill" : "headphones.circle")
                .font(.caption)
                .foregroundColor(hasListened ? .green.opacity(0.7) : theme.secondaryTextColor.opacity(0.4))

            if heardCount > 0 {
                Text("\(heardCount)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.secondaryTextColor)

                Text(heardCount == 1 ? "listen" : "listens")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
            } else {
                Text("Not yet listened")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor.opacity(0.5))
            }

            Spacer()

            if hasListened {
                Text("You've heard this")
                    .font(.caption2)
                    .foregroundColor(.green.opacity(0.6))
            }
        }
    }
}

// MARK: - Listening Progress Ring

struct ListeningProgressRing: View {
    let progress: Double  // 0-1
    let theme: PersonaTheme

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(theme.secondaryTextColor.opacity(0.2), lineWidth: 2)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    style: StrokeStyle(
                        lineWidth: 2,
                        lineCap: .round
                    )
                )
                .foregroundColor(theme.accentColor)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
        }
        .frame(width: 20, height: 20)
    }
}

// MARK: - Preview

struct SilentListenerIndicator_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Has listened
            SilentListenerIndicator(
                listenCount: 3,
                totalListenTime: 245,
                theme: ParentTheme()
            )
            .previewDisplayName("Multiple Listens")

            // Not listened
            SilentListenerIndicator(
                listenCount: 0,
                totalListenTime: 0,
                theme: ElderTheme()
            )
            .previewDisplayName("Never Listened")

            // Silent mode badge
            SilentModeBadge()
                .themed(ParentTheme())
                .previewDisplayName("Silent Mode Badge")

            // Heard by section
            HeardBySection(
                heardCount: 12,
                hasListened: true,
                theme: ParentTheme()
            )
            .previewDisplayName("Heard By - Listened")

            HeardBySection(
                heardCount: 0,
                hasListened: false,
                theme: ChildTheme()
            )
            .previewDisplayName("Heard By - Not Listened")

            // Progress ring
            HStack(spacing: 16) {
                ListeningProgressRing(progress: 0.0, theme: ParentTheme())
                ListeningProgressRing(progress: 0.3, theme: ParentTheme())
                ListeningProgressRing(progress: 0.7, theme: ParentTheme())
                ListeningProgressRing(progress: 1.0, theme: ParentTheme())
            }
            .previewDisplayName("Progress Rings")
        }
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
    }
}
