//
//  LogOutputs.swift
//  TruoraValidationsSDK
//
//  Created by AI Assistant on 2025-02-01.
//

import Foundation

// MARK: - Console Output

/// Console output for debugging
actor ConsoleLogOutput {
    func output(event: SDKEvent) {
        let emoji = event.level.emoji
        let json = event.toJSON() ?? "{}"
        print("\(emoji) [TruoraLogger] \(event.eventType.rawValue): \(event.eventName)")
        print(json)
    }
}

// MARK: - API Output

/// API output for sending to Truora endpoint
actor APILogOutput {
    private let apiKey: String
    private let endpoint: String
    private let client: SdkLogClient

    init(apiKey: String, endpoint: String) {
        self.apiKey = apiKey
        self.endpoint = endpoint
        // Configuration is validated in LoggerConfiguration, so this should not fail
        // swiftlint:disable:next force_try
        self.client = try! SdkLogClient(
            baseUrl: endpoint,
            apiKey: apiKey,
            sdkVersion: "2.1.0" // NOTE: Inject actual SDK version
        )
    }

    func output(events: [SDKEvent]) async -> Bool {
        guard let firstEvent = events.first else { return true } // Empty is success

        // Construct SDKLog batch
        let sdkLog = SDKLog(
            sdkVersion: firstEvent.sdkVersion,
            platform: firstEvent.platform,
            deviceModel: firstEvent.deviceModel,
            osVersion: firstEvent.osVersion,
            // Context fields from first event
            processId: nil as String?, // Not in event
            flowId: nil as String?, // Not in event
            validationId: firstEvent.validationId,
            accountId: firstEvent.accountId,
            events: events
        )

        do {
            _ = try await client.log(sdkLog)
            return true
        } catch {
            #if DEBUG
            print("🔴 [TruoraLogger] Failed to send events: \(error)")
            #endif
            return false
        }
    }
}
