//
//  DurationFormatting.swift
//  StoryRide
//
//  Shared duration/time formatting utilities to eliminate duplication.
//  Replaces duplicated formatDuration and formatTime functions across components.
//
// ============================================================================

import Foundation

// MARK: - Duration Formatting

/// Formats a duration in seconds as a human-readable string.
///
/// Replaces duplicated `formatDuration` and `formatTime` functions:
/// - ThreadedTimelineView.swift: 3 instances
/// - HubView.swift: 2 instances
/// - AudioPlayerService.swift: 1 instance
/// - StoryDetailView.swift: 1 instance
///
/// - Parameter seconds: Duration in seconds
/// - Returns: Formatted string like "2 min", "30s", "1m 30s"
func formatDuration(_ seconds: TimeInterval) -> String {
    let totalSeconds = Int(seconds)
    
    if totalSeconds < 60 {
        return "\(totalSeconds)s"
    }
    
    let minutes = totalSeconds / 60
    let remainingSeconds = totalSeconds % 60
    
    if remainingSeconds == 0 {
        return "\(minutes) min"
    }
    
    return "\(minutes)m \(remainingSeconds)s"
}

/// Formats a duration in seconds as MM:SS.
///
/// - Parameter seconds: Duration in seconds
/// - Returns: Formatted string like "2:30", "0:45"
func formatTimecode(seconds: TimeInterval) -> String {
    let totalSeconds = Int(seconds)
    let minutes = totalSeconds / 60
    let secs = totalSeconds % 60
    return String(format: "%d:%02d", minutes, secs)
}

/// Formats a duration in seconds as a short descriptive string.
///
/// - Parameter seconds: Duration in seconds
/// - Returns: Formatted string like "2 minutes", "30 seconds"
func formatDurationLong(_ seconds: TimeInterval) -> String {
    let totalSeconds = Int(seconds)
    
    if totalSeconds < 60 {
        return "\(totalSeconds) second\(totalSeconds == 1 ? "" : "s")"
    }
    
    let minutes = totalSeconds / 60
    
    if minutes < 60 {
        return "\(minutes) minute\(minutes == 1 ? "" : "s")"
    }
    
    let hours = minutes / 60
    let remainingMinutes = minutes % 60
    
    if remainingMinutes == 0 {
        return "\(hours) hour\(hours == 1 ? "" : "s")"
    }
    
    return "\(hours)h \(remainingMinutes)m"
}

// MARK: - Time Ago Formatting

/// Formats a timestamp as a "time ago" string.
///
/// Replaces duplicated timeAgoText implementations:
/// - HubView.swift: RecentActivity.timeAgoText
///
/// - Parameter date: The date to format
/// - Returns: Formatted string like "5m ago", "2h ago", "Yesterday"
func timeAgo(from date: Date) -> String {
    let now = Date()
    let interval = now.timeIntervalSince(date)
    
    if interval < 0 {
        // Future date
        let futureInterval = -interval
        return formatDuration(futureInterval)
    }
    
    if interval < 60 {
        return "\(Int(interval))s ago"
    }
    
    if interval < 3600 {
        return "\(Int(interval / 60))m ago"
    }
    
    if interval < 86400 {
        return "\(Int(interval / 3600))h ago"
    }
    
    if interval < 172800 {
        return "Yesterday"
    }
    
    return "\(Int(interval / 86400))d ago"
}

// MARK: - Duration Input Parsing

/// Parses a duration string into seconds.
///
/// - Parameter string: Duration string like "2:30", "150", "2m 30s"
/// - Returns: Duration in seconds, or nil if parsing fails
func parseDuration(_ string: String) -> TimeInterval? {
    // Try MM:SS format
    if string.contains(":") {
        let components = string.split(separator: ":")
        guard components.count == 2,
              let minutes = Double(components[0]),
              let seconds = Double(components[1]) else {
            return nil
        }
        return minutes * 60 + seconds
    }
    
    // Try "Xm Ys" format
    if string.contains("m") || string.contains("s") {
        let pattern = #"(\d+)m\s*(\d+)s"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)),
           let minutesRange = Range(match.range(at: 1), in: string),
           let secondsRange = Range(match.range(at: 2), in: string),
           let minutes = Double(string[minutesRange]),
           let seconds = Double(string[secondsRange]) {
            return minutes * 60 + seconds
        }
    }
    
    // Try plain number (seconds)
    if let seconds = Double(string) {
        return seconds
    }
    
    return nil
}

// MARK: - Examples

/*
 USAGE EXAMPLES:
 
 // Basic duration formatting
 let duration: TimeInterval = 150  // 2 minutes 30 seconds
 print(formatDuration(duration))  // "2m 30s"
 print(formatTimecode(duration))  // "2:30"
 print(formatDurationLong(duration))  // "2 minutes"
 
 // Time ago formatting
 let pastDate = Date().addingTimeInterval(-3600)  // 1 hour ago
 print(timeAgo(from: pastDate))  // "1h ago"
 
 // Parsing duration strings
 parseDuration("2:30")     // 150
 parseDuration("2m 30s")   // 150
 parseDuration("150")      // 150
 */
