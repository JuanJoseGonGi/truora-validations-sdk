//
//  SDKLogResponse.swift
//  TruoraValidationsSDK
//
//  Created by AI Assistant on 2025-02-01.
//

import Foundation

/// SDK Log response model from the logging API.
///
/// This is the Swift equivalent of the KMP SDKLogResponse model.
/// Contains confirmation details about the logged events.
public struct SDKLogResponse: Codable, Sendable {
    /// Response message from the server
    public let message: String

    /// Number of events successfully logged
    public let eventsLogged: Int

    /// SDK version confirmed by the server
    public let sdkVersion: String

    /// Platform confirmed by the server
    public let platform: String

    // MARK: - Initialization

    public init(
        message: String,
        eventsLogged: Int,
        sdkVersion: String,
        platform: String
    ) {
        self.message = message
        self.eventsLogged = eventsLogged
        self.sdkVersion = sdkVersion
        self.platform = platform
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case message
        case eventsLogged = "events_logged"
        case sdkVersion = "sdk_version"
        case platform
    }
}
