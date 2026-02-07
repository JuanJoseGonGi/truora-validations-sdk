//
//  LogLevel.swift
//  TruoraValidationsSDK
//
//  Created by AI Assistant on 2025-02-01.
//

import Foundation

/// Log level enumeration representing the severity of log events.
/// Follows standard logging conventions (DEBUG < INFO < WARN < ERROR < FATAL).
public enum LogLevel: String, Codable, Sendable, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARN"
    case error = "ERROR"
    case fatal = "FATAL"

    /// Priority value for comparison (higher = more severe)
    public var priority: Int {
        switch self {
        case .debug: 0
        case .info: 1
        case .warning: 2
        case .error: 3
        case .fatal: 4
        }
    }

    /// Emoji prefix for console output (maintains existing SDK convention)
    public var emoji: String {
        switch self {
        case .debug: "⚪️"
        case .info: "🟢"
        case .warning: "🟡"
        case .error: "🔴"
        case .fatal: "💥"
        }
    }
}
