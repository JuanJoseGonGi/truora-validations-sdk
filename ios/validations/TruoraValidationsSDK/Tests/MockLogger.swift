//
//  MockLogger.swift
//  TruoraValidationsSDKTests
//
//  Shared no-op logger mock for interactor tests.
//

import Foundation
@testable import TruoraValidationsSDK

/// A no-op `TruoraLogger` implementation for tests that don't verify logging.
final class NoOpLogger: TruoraLogger {
    func logEvent(
        eventType: EventType,
        eventName: String,
        level: LogLevel,
        errorMessage: String?,
        retention: RetentionPeriod,
        metadata: [String: Any]?,
        stackTrace: String?
    ) async {}

    func logCamera(eventName: String, level: LogLevel, errorMessage: String?, retention: RetentionPeriod, metadata: [String: Any]?) async {}
    func logML(eventName: String, level: LogLevel, errorMessage: String?, retention: RetentionPeriod, metadata: [String: Any]?) async {}
    func logView(viewName: String, level: LogLevel, retention: RetentionPeriod, metadata: [String: Any]?) async {}
    func logDevice(eventName: String, level: LogLevel, retention: RetentionPeriod, metadata: [String: Any]?) async {}
    func logFeedback(eventName: String, level: LogLevel, errorMessage: String?, retention: RetentionPeriod, metadata: [String: Any]?) async {}
    func logSdk(eventName: String, level: LogLevel, errorMessage: String?, retention: RetentionPeriod, metadata: [String: Any]?) async {}
    func logException(eventType: EventType, eventName: String, exception: Error, level: LogLevel, retention: RetentionPeriod, metadata: [String: Any]?) async {}
    func flush() async {}
    func flush(timeoutMs: Int64) async {}
}
