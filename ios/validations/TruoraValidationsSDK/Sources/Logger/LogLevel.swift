//
//  LogLevel.swift
//  TruoraValidationsSDK
//
//  Created by AI Assistant on 2025-02-01.
//

import Foundation

/// Log level enumeration representing the severity of log events.
/// Follows standard logging conventions (info < warning < error < fatal).
public enum LogLevel: String, Codable, Sendable, CaseIterable {
    case info
    case warning
    case error
    case fatal

    /// Priority value for comparison (higher = more severe)
    public var priority: Int {
        switch self {
        case .info: 0
        case .warning: 1
        case .error: 2
        case .fatal: 3
        }
    }

    /// Emoji prefix for console output (maintains existing SDK convention)
    public var emoji: String {
        switch self {
        case .info: "🟢"
        case .warning: "🟡"
        case .error: "🔴"
        case .fatal: "💥"
        }
    }
}
