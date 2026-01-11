//
//  Logger.swift
//  FamilyPlus
//
//  Structured logging utility for tracking app events and errors
//

import Foundation
import os.log

/// App-wide logging service with structured output
enum Logger {
    /// Log levels for categorizing messages
    enum Level: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
    }

    /// Log a debug message
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .debug, message, file: file, function: function, line: line)
    }

    /// Log an info message
    static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .info, message, file: file, function: function, line: line)
    }

    /// Log a warning message
    static func warn(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .warning, message, file: file, function: function, line: line)
    }

    /// Log an error message
    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .error, message, file: file, function: function, line: line)
    }

    /// Log an error with underlying error details
    static func error(_ message: String, error: Error, file: String = #file, function: String = #function, line: Int = #line) {
        let errorMessage = "\(message) - \(error.localizedDescription)"
        log(level: .error, errorMessage, file: file, function: function, line: line)
    }

    /// Core logging method
    private static func log(level: Level, _ message: String, file: String, function: String, line: Int) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let filename = (file as NSString).lastPathComponent
        let logMessage = "[\(timestamp)] [\(level.rawValue)] [\(filename):\(line)] \(message)"

        // Use os_log for system integration (appears in Console.app)
        let osLogType: OSLogType
        switch level {
        case .debug: osLogType = .debug
        case .info: osLogType = .info
        case .warning: osLogType = .default
        case .error: osLogType = .error
        }

        let log = OSLog(subsystem: "com.familyplus.app", category: "Network")
        os_log("%{public}@", log: log, type: osLogType, logMessage)

        // Also print to console for Xcode debugging
        print(logMessage)
    }
}

/// API-specific logging helpers
extension Logger {
    /// Log an API request
    static func logRequest(endpoint: String, method: String) {
        info("[API Request] \(method) \(endpoint)")
    }

    /// Log a successful API response
    static func logResponse(endpoint: String, statusCode: Int) {
        info("[API Response] \(endpoint) - Status: \(statusCode)")
    }

    /// Log an API error
    static func logAPIError(endpoint: String, error: Error, statusCode: Int? = nil) {
        let statusInfo = statusCode.map { " - Status: \($0)" } ?? ""
        Self.error("[API Error] \(endpoint)\(statusInfo) - \(error.localizedDescription)")
    }

    /// Log a network error
    static func logNetworkError(endpoint: String, error: Error) {
        Self.error("[Network Error] \(endpoint) - \(error.localizedDescription)")
    }

    /// Log a decoding error
    static func logDecodingError(endpoint: String, error: Error) {
        Self.error("[Decoding Error] \(endpoint) - Failed to decode response: \(error.localizedDescription)")
    }

    /// Log authentication errors
    static func logAuthError(operation: String, error: Error) {
        Self.error("[Auth Error] \(operation) - \(error.localizedDescription)")
    }

    /// Log Supabase-specific errors
    static func logSupabaseError(operation: String, error: Error) {
        Self.error("[Supabase Error] \(operation) - \(error.localizedDescription)")
    }
}
