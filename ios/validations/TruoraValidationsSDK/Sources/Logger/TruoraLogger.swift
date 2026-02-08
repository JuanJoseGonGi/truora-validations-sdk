//
//  TruoraLogger.swift
//  TruoraValidationsSDK
//
//  Created by AI Assistant on 2025-02-01.
//

import Foundation

/// Protocol for SDK logging. Designed for VIPER architecture injection.
///
/// Inject this protocol into Presenters/Interactors via constructor for production use,
/// and use mock implementations for testing.
///
/// This protocol is `Sendable` to support Swift 6 concurrency.
/// Implementations should be actors or use proper isolation.
public protocol TruoraLogger: Sendable {
    // MARK: - Generic Event Logging

    /// Log a generic SDK event with full control over all parameters.
    /// Duration is auto-computed from logger initialization time.
    ///
    /// - Parameters:
    ///   - eventType: The category of event (CAMERA, ML_MODEL, VIEW, etc.)
    ///   - eventName: Snake_case name (max 35 characters)
    ///   - level: Severity level (DEBUG, INFO, WARN, ERROR, FATAL)
    ///   - errorMessage: Optional error description
    ///   - retention: Data retention period
    ///   - metadata: Optional key-value context
    ///   - stackTrace: Optional stack trace for errors
    func logEvent(
        eventType: EventType,
        eventName: String,
        level: LogLevel,
        errorMessage: String?,
        retention: RetentionPeriod,
        metadata: [String: Any]?,
        stackTrace: String?
    ) async

    // MARK: - Convenience Methods

    /// Log a camera-related event.
    func logCamera(
        eventName: String,
        level: LogLevel,
        errorMessage: String?,
        retention: RetentionPeriod,
        metadata: [String: Any]?
    ) async

    /// Log an ML model event.
    func logML(
        eventName: String,
        level: LogLevel,
        errorMessage: String?,
        retention: RetentionPeriod,
        metadata: [String: Any]?
    ) async

    /// Log a view/screen event.
    func logView(
        viewName: String,
        level: LogLevel,
        retention: RetentionPeriod,
        metadata: [String: Any]?
    ) async

    /// Log a device-related event.
    func logDevice(
        eventName: String,
        level: LogLevel,
        retention: RetentionPeriod,
        metadata: [String: Any]?
    ) async

    /// Log a feedback event (e.g., document evaluation results).
    func logFeedback(
        eventName: String,
        level: LogLevel,
        errorMessage: String?,
        retention: RetentionPeriod,
        metadata: [String: Any]?
    ) async

    /// Log an SDK execution event.
    func logSdk(
        eventName: String,
        level: LogLevel,
        errorMessage: String?,
        retention: RetentionPeriod,
        metadata: [String: Any]?
    ) async

    // MARK: - Exception Logging

    /// Log an exception/error with automatic stack trace extraction.
    ///
    /// - Parameters:
    ///   - eventType: The event category
    ///   - eventName: The event name
    ///   - exception: The error/exception to log
    ///   - level: Severity level (typically ERROR or FATAL)
    ///   - retention: Data retention period
    ///   - metadata: Optional context
    func logException(
        eventType: EventType,
        eventName: String,
        exception: Error,
        level: LogLevel,
        retention: RetentionPeriod,
        metadata: [String: Any]?
    ) async

    // MARK: - Flush

    /// Flush pending events asynchronously.
    /// Events may be lost if the app is killed before flush completes.
    func flush() async

    /// Flush with a maximum timeout.
    /// - Parameter timeoutMs: Maximum time to wait in milliseconds
    func flush(timeoutMs: Int64) async
}

// MARK: - Default Implementations

public extension TruoraLogger {
    /// Convenience method to log an event with INFO level and default retention.
    func logInfo(
        eventType: EventType,
        eventName: String,
        metadata: [String: Any]? = nil
    ) async {
        await logEvent(
            eventType: eventType,
            eventName: eventName,
            level: .info,
            errorMessage: nil,
            retention: .oneWeek,
            metadata: metadata,
            stackTrace: nil
        )
    }

    /// Convenience method to log an error event.
    func logError(
        eventType: EventType,
        eventName: String,
        errorMessage: String,
        metadata: [String: Any]? = nil
    ) async {
        await logEvent(
            eventType: eventType,
            eventName: eventName,
            level: .error,
            errorMessage: errorMessage,
            retention: .oneWeek,
            metadata: metadata,
            stackTrace: nil
        )
    }
}
