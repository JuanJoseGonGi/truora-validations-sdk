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
    private let client: SdkLogClient
    private let sdkVersion: String

    init(apiKey: String, endpoint: String, sdkVersion: String) {
        self.sdkVersion = sdkVersion
        // Configuration is validated in LoggerConfiguration, so this should not fail
        // swiftlint:disable:next force_try
        self.client = try! SdkLogClient(
            baseUrl: endpoint,
            apiKey: apiKey,
            sdkVersion: sdkVersion
        )
    }

    func output(events: [SDKEvent]) async -> Bool {
        guard !events.isEmpty else { return true }

        // Build batch: sdkVersion from actor config, platform hardcoded,
        // device/validation context extracted from the first event.
        let firstEvent = events[0]

        let logBatch = SDKLog(
            sdkVersion: sdkVersion,
            platform: "ios",
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            deviceModel: firstEvent.deviceModel,
            osVersion: firstEvent.osVersion,
            processId: nil,
            flowId: nil,
            validationId: firstEvent.validationId,
            accountId: firstEvent.accountId,
            clientId: nil,
            events: events
        )

        do {
            _ = try await client.log(logBatch)
            #if DEBUG
            print("🟢 [TruoraLogger] Sent \(events.count) events")
            #endif
            return true
        } catch {
            #if DEBUG
            let desc = error.localizedDescription
            print("❌ [TruoraLogger] Failed to send: \(desc)")
            #endif
            return false
        }
    }
}
