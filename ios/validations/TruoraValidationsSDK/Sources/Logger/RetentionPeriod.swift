//
//  RetentionPeriod.swift
//  TruoraValidationsSDK
//
//  Created by AI Assistant on 2025-02-01.
//

import Foundation

/// Retention period enumeration for event data lifecycle management.
/// Defines how long events should be retained in the logging system.
public enum RetentionPeriod: String, Codable, Sendable, CaseIterable {
    case oneDay = "ONE_DAY"
    case oneWeek = "ONE_WEEK"
    case oneMonth = "ONE_MONTH"
    case oneYear = "ONE_YEAR"
    case permanent = "PERMANENT"
}
