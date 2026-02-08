//
//  SDKEvent.swift
//  TruoraValidationsSDK
//
//  Created by AI Assistant on 2025-02-01.
//

import Foundation

/// Wide event model for structured SDK logging.
///
/// Following the "logging sucks" principles, this is a comprehensive event
/// containing all context needed for debugging. Instead of scattering log
/// lines throughout the code, emit one wide event with high dimensionality.
///
/// Key principles:
/// - High cardinality: user_id, validation_id for precise searching
/// - High dimensionality: 15+ fields for debugging context
/// - Structured: Key-value pairs, not string interpolation
public struct SDKEvent: Codable, Sendable {
    // MARK: - Core Identity

    /// Unique event identifier for deduplication
    public let eventId: String

    /// Event timestamp in ISO 8601 format
    public let timestamp: String

    /// Event type category (CAMERA, ML_MODEL, VIEW, etc.)
    public let eventType: EventType

    /// Event name in snake_case (max 35 characters per spec)
    public let eventName: String

    // MARK: - Log Level & Status

    /// Log severity level
    public let level: LogLevel

    /// Error message if applicable
    public let errorMessage: String?

    /// Error code for programmatic handling
    public let errorCode: String?

    /// Duration in milliseconds for timing events
    public let durationMs: Int64?

    /// Stack trace for error events
    public let stackTrace: String?

    // MARK: - Business Context (High Cardinality)

    /// User identifier from ValidationConfig
    public let userId: String?

    /// Validation identifier from ValidationConfig
    public let validationId: String?

    /// Type of validation (face_validation, doc_validation)
    public let validationType: String?

    /// Account identifier from ValidationConfig
    public let accountId: String?

    // MARK: - Device Context

    /// Device model (e.g., "iPhone15,2")
    public let deviceModel: String

    /// iOS version (e.g., "17.1")
    public let osVersion: String

    /// SDK version (e.g., "1.2.3")
    public let sdkVersion: String

    /// Platform identifier (always "ios")
    public let platform: String

    // MARK: - Additional Context

    /// Flexible metadata dictionary for event-specific context
    public let metadata: [String: String]

    /// Data retention period
    public let retention: RetentionPeriod

    // MARK: - Initialization

    public init(
        eventId: String = UUID().uuidString,
        timestamp: Date = Date(),
        eventType: EventType,
        eventName: String,
        level: LogLevel,
        errorMessage: String? = nil,
        errorCode: String? = nil,
        durationMs: Int64? = nil,
        stackTrace: String? = nil,
        userId: String? = nil,
        validationId: String? = nil,
        validationType: String? = nil,
        accountId: String? = nil,
        deviceModel: String,
        osVersion: String,
        sdkVersion: String,
        platform: String = "ios",
        metadata: [String: String] = [:],
        retention: RetentionPeriod
    ) {
        self.eventId = eventId
        self.timestamp = ISO8601DateFormatter().string(from: timestamp)
        self.eventType = eventType
        self.eventName = String(eventName.prefix(35)) // Enforce max 35 chars
        self.level = level
        self.errorMessage = errorMessage
        self.errorCode = errorCode
        self.durationMs = durationMs
        self.stackTrace = stackTrace
        self.userId = userId
        self.validationId = validationId
        self.validationType = validationType
        self.accountId = accountId
        self.deviceModel = deviceModel
        self.osVersion = osVersion
        self.sdkVersion = sdkVersion
        self.platform = platform
        self.metadata = metadata
        self.retention = retention
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case timestamp
        case eventType = "event_type"
        case eventName = "event_name"
        case level
        case errorMessage = "error_message"
        case errorCode = "error_code"
        case durationMs = "duration_ms"
        case stackTrace = "stack_trace"
        case userId = "user_id"
        case validationId = "validation_id"
        case validationType = "validation_type"
        case accountId = "account_id"
        case deviceModel = "device_model"
        case osVersion = "os_version"
        case sdkVersion = "sdk_version"
        case platform
        case metadata
        case retention
    }
}

// MARK: - Convenience Methods

public extension SDKEvent {
    /// Returns a JSON string representation of the event
    func toJSON() -> String? {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .useDefaultKeys
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .sortedKeys

        guard let data = try? encoder.encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Returns a dictionary representation suitable for API requests
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "event_id": eventId,
            "timestamp": timestamp,
            "event_type": eventType.rawValue,
            "event_name": eventName,
            "level": level.rawValue,
            "device_model": deviceModel,
            "os_version": osVersion,
            "sdk_version": sdkVersion,
            "platform": platform,
            "retention": retention.rawValue
        ]

        if let errorMessage { dict["error_message"] = errorMessage }
        if let errorCode { dict["error_code"] = errorCode }
        if let durationMs { dict["duration_ms"] = durationMs }
        if let stackTrace { dict["stack_trace"] = stackTrace }
        if let userId { dict["user_id"] = userId }
        if let validationId { dict["validation_id"] = validationId }
        if let validationType { dict["validation_type"] = validationType }
        if let accountId { dict["account_id"] = accountId }
        dict["metadata"] = metadata

        return dict
    }
}
