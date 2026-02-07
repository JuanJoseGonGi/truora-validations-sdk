//
//  EventType.swift
//  TruoraValidationsSDK
//
//  Created by AI Assistant on 2025-02-01.
//

import Foundation

/// Event type enumeration for categorizing SDK events.
/// Maps to the event types defined in the SDK log specification.
public enum EventType: String, Codable, Sendable, CaseIterable {
    case camera = "CAMERA"
    case mlModel = "ML_MODEL"
    case view = "VIEW"
    case device = "DEVICE"
    case feedback = "FEEDBACK"
    case sdk = "SDK"
}
