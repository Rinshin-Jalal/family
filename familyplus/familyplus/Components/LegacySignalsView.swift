//
//  LegacySignalsView.swift
//  StoryRide
//
//  Legacy Signals - showing memory "aliveness" through engagement metrics
//

import SwiftUI

// MARK: - Legacy Signals View

struct LegacySignalsView: View {
    let voiceCount: Int
    let heardCount: Int
    let lastAdded: Date?
    let theme: PersonaTheme

    var body: some View {
        HStack(spacing: 16) {
            // Voice count (perspectives contributed)
            SignalItem(
                icon: "person.wave.2.fill",
                value: "\(voiceCount)",
                label: voiceCount == 1 ? "voice" : "voices",
                color: theme.accentColor.opacity(0.8),
                theme: theme
            )

            // Heard count (times listened)
            SignalItem(
                icon: "headphones",
                value: formattedHeardCount,
                label: "listened",
                color: heardCount > 0 ? .green.opacity(0.7) : theme.secondaryTextColor.opacity(0.5),
                theme: theme
            )

            Spacer()

            // Last added timestamp
            if let lastAdded = lastAdded {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(lastAddedString(from: lastAdded))
                        .font(.caption)
                }
                .foregroundColor(theme.secondaryTextColor)
            }
        }
    }

    private var formattedHeardCount: String {
        if heardCount == 0 {
            return "—"
        } else if heardCount >= 1000 {
            return "\(heardCount / 1000)k"
        } else {
            return "\(heardCount)"
        }
    }

    private func lastAddedString(from: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: from, relativeTo: Date())
    }
}

// MARK: - Signal Item

struct SignalItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    let theme: PersonaTheme

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.textColor)

                Text(label)
                    .font(.caption2)
                    .foregroundColor(theme.secondaryTextColor)
            }
        }
    }
}

// MARK: - Minimal Legacy Signals (for compact display)

struct CompactLegacySignalsView: View {
    let voiceCount: Int
    let heardCount: Int
    let theme: PersonaTheme

    var body: some View {
        HStack(spacing: 12) {
            // Voices pill
            SignalPill(
                icon: "person.wave.2.fill",
                text: "\(voiceCount) \(voiceCount == 1 ? "voice" : "voices")",
                color: theme.accentColor.opacity(0.15),
                iconColor: theme.accentColor,
                theme: theme
            )

            // Listened pill
            SignalPill(
                icon: "headphones",
                text: heardCount > 0 ? "\(heardCount)× listened" : "Not yet listened",
                color: heardCount > 0 ? Color.green.opacity(0.15) : theme.secondaryTextColor.opacity(0.08),
                iconColor: heardCount > 0 ? Color.green.opacity(0.7) : theme.secondaryTextColor.opacity(0.5),
                theme: theme
            )
        }
    }
}

// MARK: - Signal Pill

struct SignalPill: View {
    let icon: String
    let text: String
    let color: Color
    let iconColor: Color
    let theme: PersonaTheme

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(iconColor)

            Text(text)
                .font(.caption)
                .foregroundColor(theme.textColor.opacity(0.8))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(color)
        )
    }
}

// MARK: - Preview

struct LegacySignalsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Full signals view
            LegacySignalsView(
                voiceCount: 5,
                heardCount: 47,
                lastAdded: Date().addingTimeInterval(-86400 * 3),
                theme: LightTheme()
            )
            .previewDisplayName("Full Signals - light")

            // Compact signals view
            CompactLegacySignalsView(
                voiceCount: 8,
                heardCount: 124,
                theme: LightTheme()
            )
            .previewDisplayName("Compact Signals - light")

            // No listens yet
            LegacySignalsView(
                voiceCount: 3,
                heardCount: 0,
                lastAdded: Date().addingTimeInterval(-3600),
                theme: LightTheme()
            )
            .previewDisplayName("No Listens - Elder")
        }
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
    }
}
