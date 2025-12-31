//
//  ElderPreferencesModal.swift
//  StoryRide
//
//  Modal for configuring elder call preferences
//

import SwiftUI

// MARK: - Elder Preferences Data Models

struct ElderPreferences {
    var callTimeWindows: [CallTimeWindow]
    var frequency: CallFrequency
    var allowedTopics: [String]
    var disallowedTopics: [String]
    var isOptedOut: Bool
    
    enum CallFrequency: String, CaseIterable {
        case weekly = "Weekly"
        case biweekly = "Every 2 Weeks"
        case monthly = "Monthly"
        case paused = "Paused"
        
        var icon: String {
            switch self {
            case .weekly: return "calendar.badge.clock"
            case .biweekly: return "calendar"
            case .monthly: return "calendar.circle"
            case .paused: return "pause.circle"
            }
        }
    }
}

struct CallTimeWindow: Identifiable {
    let id = UUID()
    let dayOfWeek: String
    let startTime: String
    let endTime: String
    
    var displayString: String {
        "\(dayOfWeek) \(startTime)-\(endTime)"
    }
}

// MARK: - Elder Preferences Modal

struct ElderPreferencesModal: View {
    let elderName: String
    @State private var preferences: ElderPreferences
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    
    init(elderName: String, preferences: ElderPreferences = ElderPreferences(
        callTimeWindows: [
            CallTimeWindow(dayOfWeek: "Tuesday", startTime: "2:00 PM", endTime: "4:00 PM"),
            CallTimeWindow(dayOfWeek: "Thursday", startTime: "10:00 AM", endTime: "12:00 PM")
        ],
        frequency: .weekly,
        allowedTopics: ["Childhood", "Career", "Family traditions"],
        disallowedTopics: ["Health issues", "Money"],
        isOptedOut: false
    )) {
        self.elderName = elderName
        self._preferences = State(initialValue: preferences)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Text("👴")
                            .font(.system(size: 64))
                        
                        Text("\(elderName)'s Preferences")
                            .font(.title2.bold())
                            .foregroundColor(theme.textColor)
                        
                        Text("Respecting \(elderName)'s comfort and boundaries")
                            .font(.subheadline)
                            .foregroundColor(theme.secondaryTextColor)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 24)
                    
                    // Opt-out warning (if opted out)
                    if preferences.isOptedOut {
                        HStack(spacing: 12) {
                            Image(systemName: "pause.circle.fill")
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Calls Paused")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.orange)
                                
                                Text("\(elderName) has opted out of calls")
                                    .font(.caption)
                                    .foregroundColor(theme.secondaryTextColor)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange.opacity(0.1))
                        )
                    }
                    
                    // Call Frequency
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Call Frequency", systemImage: "calendar")
                            .font(.headline)
                            .foregroundColor(theme.textColor)
                        
                        Picker("Frequency", selection: $preferences.frequency) {
                            ForEach(ElderPreferences.CallFrequency.allCases, id: \.self) { freq in
                                Label(freq.rawValue, systemImage: freq.icon)
                                    .tag(freq)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )
                    
                    // Preferred Call Times
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Preferred Call Times", systemImage: "clock")
                            .font(.headline)
                            .foregroundColor(theme.textColor)
                        
                        ForEach(preferences.callTimeWindows) { window in
                            HStack {
                                Image(systemName: "phone.fill")
                                    .foregroundColor(.green)
                                Text(window.displayString)
                                    .font(.subheadline)
                                    .foregroundColor(theme.textColor)
                                Spacer()
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.tertiarySystemBackground))
                            )
                        }
                        
                        Button(action: {}) {
                            Label("Add Time Window", systemImage: "plus.circle")
                                .font(.subheadline)
                                .foregroundColor(theme.accentColor)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )
                    
                    // Allowed Topics
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Comfortable Topics", systemImage: "checkmark.circle")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        TopicFlowLayout(spacing: 8) {
                            ForEach(preferences.allowedTopics, id: \.self) { topic in
                                TopicBadge(topic: topic, color: .green)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.05))
                    )
                    
                    // Disallowed Topics
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Topics to Avoid", systemImage: "xmark.circle")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        TopicFlowLayout(spacing: 8) {
                            ForEach(preferences.disallowedTopics, id: \.self) { topic in
                                TopicBadge(topic: topic, color: .red)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.05))
                    )
                    
                    // Emergency opt-out
                    VStack(spacing: 12) {
                        Divider()
                        
                        Text("Need a break from calls?")
                            .font(.subheadline)
                            .foregroundColor(theme.secondaryTextColor)
                        
                        Button(action: {
                            preferences.isOptedOut.toggle()
                        }) {
                            Label(
                                preferences.isOptedOut ? "Resume Calls" : "Pause All Calls",
                                systemImage: preferences.isOptedOut ? "play.circle" : "pause.circle"
                            )
                            .font(.headline)
                            .foregroundColor(preferences.isOptedOut ? .green : .orange)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(
                                        preferences.isOptedOut ? Color.green : Color.orange,
                                        lineWidth: 2
                                    )
                            )
                        }
                    }
                    .padding(.top, 16)
                }
                .padding(20)
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // TODO: Save preferences to backend
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}

// MARK: - Topic Badge

struct TopicBadge: View {
    let topic: String
    let color: Color
    
    var body: some View {
        Text(topic)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
            )
            .overlay(
                Capsule()
                    .strokeBorder(color.opacity(0.3), lineWidth: 1)
            )
            .foregroundColor(color)
    }
}

// MARK: - Topic Flow Layout

struct TopicFlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = TopicFlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = TopicFlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                     y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct TopicFlowResult {
        var size: CGSize
        var positions: [CGPoint]
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var positions: [CGPoint] = []
            var size: CGSize = .zero
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let subviewSize = subview.sizeThatFits(.unspecified)
                
                if currentX + subviewSize.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, subviewSize.height)
                currentX += subviewSize.width + spacing
                size.width = max(size.width, currentX - spacing)
            }
            
            size.height = currentY + lineHeight
            self.size = size
            self.positions = positions
        }
    }
}

// MARK: - Preview

struct ElderPreferencesModal_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ElderPreferencesModal(elderName: "Grandma Rose")
                .themed(DarkTheme())
                .previewDisplayName("Dark Theme")
            
            ElderPreferencesModal(elderName: "Grandpa Joe")
                .themed(LightTheme())
                .previewDisplayName("Light Theme")
        }
    }
}
