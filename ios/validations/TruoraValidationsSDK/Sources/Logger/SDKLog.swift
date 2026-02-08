//
//  SDKLog.swift
//  TruoraValidationsSDK
//
//  Created by AI Assistant on 2025-02-01.
//

import Foundation

/// SDK Log batch request model for sending multiple events to the logging API.
///
/// This is the Swift equivalent of the KMP SDKLog model.
/// Contains batch metadata and a list of events to be logged.
public struct SDKLog: Codable, Sendable {
    // MARK: - Constants

    public static let maxEventsPerRequest = 50
    public static let validPlatforms = Set(["android", "ios"])

    // MARK: - Properties

    /// SDK version string (e.g., "2.1.0")
    public let sdkVersion: String

    /// Platform identifier ("ios" or "android")
    public let platform: String

    /// Timestamp in milliseconds since epoch
    public let timestamp: Int64

    /// Device model (e.g., "iPhone15,2")
    public let deviceModel: String

    /// OS version (e.g., "17.1")
    public let osVersion: String

    /// Process ID for tracking
    public let processId: String?

    /// Flow ID for correlation
    public let flowId: String?

    /// Validation ID for correlation
    public let validationId: String?

    /// Account ID for correlation
    public let accountId: String?

    /// Client ID for tracking
    public let clientId: String?

    /// List of events to log (max 50)
    public let events: [SDKEvent]

    // MARK: - Initialization

    public init(
        sdkVersion: String,
        platform: String,
        timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        deviceModel: String,
        osVersion: String,
        processId: String? = nil,
        flowId: String? = nil,
        validationId: String? = nil,
        accountId: String? = nil,
        clientId: String? = nil,
        events: [SDKEvent]
    ) {
        self.sdkVersion = sdkVersion
        self.platform = platform.lowercased()
        self.timestamp = timestamp
        self.deviceModel = deviceModel
        self.osVersion = osVersion
        self.processId = processId
        self.flowId = flowId
        self.validationId = validationId
        self.accountId = accountId
        self.clientId = clientId
        self.events = events
    }

    // MARK: - Validation

    /// Validate the SDK log request.
    /// - Throws: SdkLogValidationError if validation fails
    public func validate() throws {
        if sdkVersion.isBlank {
            throw SdkLogValidationError(code: .emptySdkVersion)
        }

        if platform.isBlank {
            throw SdkLogValidationError(code: .emptyPlatform)
        }

        if !SDKLog.validPlatforms.contains(platform) {
            throw SdkLogValidationError(code: .invalidPlatform)
        }

        if events.isEmpty {
            throw SdkLogValidationError(code: .emptyEvents)
        }

        if events.count > SDKLog.maxEventsPerRequest {
            throw SdkLogValidationError(code: .tooManyEvents)
        }

        // Validate each event
        for event in events {
            try event.validate()
        }
    }

    /// Returns a normalized copy with platform lowercase.
    public func normalized() -> SDKLog {
        SDKLog(
            sdkVersion: sdkVersion,
            platform: platform.lowercased(),
            timestamp: timestamp,
            deviceModel: deviceModel,
            osVersion: osVersion,
            processId: processId,
            flowId: flowId,
            validationId: validationId,
            accountId: accountId,
            clientId: clientId,
            events: events
        )
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case sdkVersion = "sdk_version"
        case platform
        case timestamp
        case deviceModel = "device_model"
        case osVersion = "os_version"
        case processId = "process_id"
        case flowId = "flow_id"
        case validationId = "validation_id"
        case accountId = "account_id"
        case clientId = "client_id"
        case events
    }
}

// MARK: - SDKEvent Validation Extension

public extension SDKEvent {
    /// Validate the SDK event.
    /// - Throws: SdkLogValidationError if validation fails
    func validate() throws {
        if eventName.isBlank {
            throw SdkLogValidationError(code: .invalidEventName)
        }

        if eventName.count > 35 {
            throw SdkLogValidationError(code: .eventNameTooLong)
        }

        if let durationMs, durationMs < 0 {
            throw SdkLogValidationError(code: .invalidDuration)
        }
    }
}

// MARK: - Helper Extension

private extension String {
    var isBlank: Bool {
        self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
