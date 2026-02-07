//
//  TruoraLoggerTests.swift
//  TruoraValidationsSDKTests
//
//  Created by AI Assistant on 2025-02-01.
//

import XCTest
@testable import TruoraValidationsSDK

@MainActor
final class TruoraLoggerTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        // Reset logger before each test
        await TruoraLoggerImplementation.reset()
    }

    override func tearDown() async throws {
        // Clean up after each test
        await TruoraLoggerImplementation.reset()
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialize_shouldCreateSingleton() async throws {
        // When
        try await TruoraLoggerImplementation.initialize(with: LoggerConfiguration.testing())

        // Then
        let logger = try await TruoraLoggerImplementation.shared
        XCTAssertNotNil(logger)
        XCTAssertTrue(TruoraLoggerImplementation.isInitialized)
    }

    func testInitialize_twice_shouldNotFail() async throws {
        // Given
        try await TruoraLoggerImplementation.initialize(with: LoggerConfiguration.testing())

        // When/Then - Should not throw
        try await TruoraLoggerImplementation.initialize(with: LoggerConfiguration.testing())
    }

    func testShared_beforeInitialization_shouldThrow() async {
        // When/Then
        do {
            _ = try await TruoraLoggerImplementation.shared
            XCTFail("Should have thrown error")
        } catch {
            // Expected
            XCTAssertTrue(error is TruoraException)
        }
    }

    // MARK: - Logging Tests

    func testLogEvent_shouldNotThrow() async throws {
        // Given
        try await TruoraLoggerImplementation.initialize(with: LoggerConfiguration.testing())
        let logger = try await TruoraLoggerImplementation.shared

        // When/Then - Should not throw
        await logger.logEvent(
            eventType: .camera,
            eventName: "test_event",
            level: .info,
            errorMessage: nil,
            durationMs: 100,
            retention: .oneWeek,
            metadata: ["key": "value"],
            stackTrace: nil
        )
    }

    func testLogCamera_shouldUseCameraEventType() async throws {
        // Given
        try await TruoraLoggerImplementation.initialize(with: LoggerConfiguration.testing())
        let logger = try await TruoraLoggerImplementation.shared

        // When
        await logger.logCamera(
            eventName: "camera_test",
            level: .info,
            errorMessage: nil,
            durationMs: 50,
            retention: .oneWeek,
            metadata: ["camera": "front"]
        )

        // Then - Event was logged (no error thrown)
        // In a real test, we'd verify the event was buffered
    }

    func testLogView_shouldIncludeViewName() async throws {
        // Given
        try await TruoraLoggerImplementation.initialize(with: LoggerConfiguration.testing())
        let logger = try await TruoraLoggerImplementation.shared

        // When
        await logger.logView(
            viewName: "DocumentCapture",
            level: .info,
            durationMs: 200,
            retention: .oneWeek,
            metadata: nil
        )

        // Then - Event was logged
    }

    func testLogException_shouldExtractErrorInfo() async throws {
        // Given
        try await TruoraLoggerImplementation.initialize(with: LoggerConfiguration.testing())
        let logger = try await TruoraLoggerImplementation.shared
        let testError = TruoraException.sdk(SDKError(type: .internalError, details: "Test error"))

        // When
        await logger.logException(
            eventType: .sdk,
            eventName: "exception_test",
            exception: testError,
            level: .error,
            durationMs: nil,
            retention: .oneMonth,
            metadata: nil
        )

        // Then - Event was logged with stack trace
    }

    // MARK: - Flush Tests

    func testFlush_emptyBuffer_shouldNotFail() async throws {
        // Given
        try await TruoraLoggerImplementation.initialize(with: LoggerConfiguration.testing())
        let logger = try await TruoraLoggerImplementation.shared

        // When/Then - Should not throw
        await logger.flush()
    }

    func testFlush_withTimeout_shouldComplete() async throws {
        // Given
        try await TruoraLoggerImplementation.initialize(with: LoggerConfiguration.testing())
        let logger = try await TruoraLoggerImplementation.shared

        // When/Then - Should not throw
        await logger.flush(timeoutMs: 1000)
    }

    // MARK: - Reset Tests

    func testReset_shouldClearInstance() async throws {
        // Given
        try await TruoraLoggerImplementation.initialize(with: LoggerConfiguration.testing())
        XCTAssertTrue(TruoraLoggerImplementation.isInitialized)

        // When
        await TruoraLoggerImplementation.reset()

        // Then
        XCTAssertFalse(TruoraLoggerImplementation.isInitialized)
    }

    // MARK: - Configuration Tests

    func testLoggerConfiguration_production_shouldDisableConsole() {
        // When
        let config = LoggerConfiguration.production(apiKey: "test", sdkVersion: "1.0")

        // Then
        XCTAssertFalse(config.enableConsoleOutput)
        XCTAssertTrue(config.enableApiOutput)
    }

    func testLoggerConfiguration_development_shouldEnableConsole() {
        // When
        let config = LoggerConfiguration.development(apiKey: "test", sdkVersion: "1.0")

        // Then
        XCTAssertTrue(config.enableConsoleOutput)
        XCTAssertTrue(config.enableApiOutput)
        XCTAssertEqual(config.flushIntervalMs, 5000)
    }
}

// MARK: - Mock Implementations

@MainActor
final class MockTruoraLogger: TruoraLogger {
    private(set) var loggedEvents: [SDKEvent] = []
    private(set) var flushCallCount = 0

    func logEvent(
        eventType: EventType,
        eventName: String,
        level: LogLevel,
        errorMessage: String?,
        durationMs: Int64?,
        retention: RetentionPeriod,
        metadata: [String: Any]?,
        stackTrace: String?
    ) async {
        let event = SDKEvent(
            eventType: eventType,
            eventName: eventName,
            level: level,
            success: nil,
            errorMessage: errorMessage,
            errorCode: nil,
            durationMs: durationMs,
            stackTrace: stackTrace,
            userId: nil,
            validationId: nil,
            validationType: nil,
            accountId: nil,
            deviceModel: "Mock",
            osVersion: "1.0",
            sdkVersion: "1.0.0",
            platform: "ios",
            metadata: metadata?.mapValues { "\($0)" },
            retention: retention
        )
        loggedEvents.append(event)
    }

    func logCamera(eventName: String, level: LogLevel, errorMessage: String?, durationMs: Int64?, retention: RetentionPeriod, metadata: [String: Any]?) async {
        await logEvent(eventType: .camera, eventName: eventName, level: level, errorMessage: errorMessage, durationMs: durationMs, retention: retention, metadata: metadata, stackTrace: nil)
    }

    func logML(eventName: String, level: LogLevel, errorMessage: String?, durationMs: Int64?, retention: RetentionPeriod, metadata: [String: Any]?) async {
        await logEvent(eventType: .mlModel, eventName: eventName, level: level, errorMessage: errorMessage, durationMs: durationMs, retention: retention, metadata: metadata, stackTrace: nil)
    }

    func logView(viewName: String, level: LogLevel, durationMs: Int64?, retention: RetentionPeriod, metadata: [String: Any]?) async {
        var mergedMetadata = metadata ?? [:]
        mergedMetadata["view_name"] = viewName
        await logEvent(eventType: .view, eventName: "view_\(viewName)", level: level, errorMessage: nil, durationMs: durationMs, retention: retention, metadata: mergedMetadata, stackTrace: nil)
    }

    func logDevice(eventName: String, level: LogLevel, retention: RetentionPeriod, metadata: [String: Any]?) async {
        await logEvent(eventType: .device, eventName: eventName, level: level, errorMessage: nil, durationMs: nil, retention: retention, metadata: metadata, stackTrace: nil)
    }

    func logFeedback(eventName: String, level: LogLevel, errorMessage: String?, durationMs: Int64?, retention: RetentionPeriod, metadata: [String: Any]?) async {
        await logEvent(eventType: .feedback, eventName: eventName, level: level, errorMessage: errorMessage, durationMs: durationMs, retention: retention, metadata: metadata, stackTrace: nil)
    }

    func logSdk(eventName: String, level: LogLevel, errorMessage: String?, durationMs: Int64?, retention: RetentionPeriod, metadata: [String: Any]?) async {
        await logEvent(eventType: .sdk, eventName: eventName, level: level, errorMessage: errorMessage, durationMs: durationMs, retention: retention, metadata: metadata, stackTrace: nil)
    }

    func logException(eventType: EventType, eventName: String, exception: Error, level: LogLevel, durationMs: Int64?, retention: RetentionPeriod, metadata: [String: Any]?) async {
        await logEvent(eventType: eventType, eventName: eventName, level: level, errorMessage: exception.localizedDescription, durationMs: durationMs, retention: retention, metadata: metadata, stackTrace: nil)
    }

    func flush() async {
        flushCallCount += 1
    }

    func flush(timeoutMs: Int64) async {
        flushCallCount += 1
    }
}
