//
//  TruoraLoggerImplementation.swift
//  TruoraValidationsSDK
//
//  Created by AI Assistant on 2025-02-01.
//

import Foundation
import UIKit

/// Actor-based logger implementation for iOS.
///
/// This implementation follows Sentry's patterns for reliability:
/// - Events are buffered in memory and flushed periodically
/// - Events may be lost if the app is killed before flush completes
/// - Thread-safe via actor isolation
/// - Integrates with app lifecycle for automatic flushing
public actor TruoraLoggerImplementation: TruoraLogger { // swiftlint:disable:this type_body_length
    // MARK: - Singleton Pattern

    private static let lock = NSLock()
    private static var _instance: TruoraLoggerImplementation?
    private static var initializationError: Error?

    /// Initialize the singleton logger instance.
    /// Must be called before using `shared`.
    ///
    /// - Parameter config: Logger configuration
    /// - Throws: TruoraException if initialization fails
    public static func initialize(with config: LoggerConfiguration) async throws {
        var shouldInitialize = false
        lock.withLock {
            guard _instance == nil, initializationError == nil else {
                return // Already initialized or failed
            }
            shouldInitialize = true
        }

        // Initialize outside the lock to avoid issues with async/await
        if shouldInitialize {
            let instance = TruoraLoggerImplementation(config: config)
            await instance.initializeAfterActorReady()

            lock.withLock {
                _instance = instance
            }
        }
    }

    /// Get the singleton logger instance.
    ///
    /// - Throws: TruoraException if not initialized
    /// - Returns: The shared logger instance
    public static var shared: TruoraLoggerImplementation {
        get throws {
            try lock.withLock {
                guard let instance = _instance else {
                    let baseMessage = "TruoraLogger not initialized"
                    let message = initializationError.map { "\(baseMessage). Previous initialization failed: \($0)" }
                        ?? baseMessage
                    throw TruoraException.sdk(SDKError(type: .internalError, details: message))
                }
                return instance
            }
        }
    }

    /// Check if the logger has been initialized.
    public static var isInitialized: Bool {
        lock.withLock { _instance != nil }
    }

    // MARK: - Test Support

    /// Initialize for testing with minimal configuration.
    /// Safe to call multiple times - only initializes once.
    public static func initializeForTesting() async throws {
        if !isInitialized, initializationError == nil {
            try await initialize(with: LoggerConfiguration.testing())
        }
    }

    /// Reset the singleton for testing.
    /// Cancels any pending operations and clears the instance.
    public static func reset() async {
        var instanceToShutdown: TruoraLoggerImplementation?
        lock.withLock {
            instanceToShutdown = _instance
            _instance = nil
            initializationError = nil
        }
        // Shutdown outside the lock to avoid async/await issues
        if let instance = instanceToShutdown {
            await instance.shutdown()
        }
    }

    // MARK: - Properties

    private let config: LoggerConfiguration
    private let initializationTime = Date()
    /// Lazy device info - computed on MainActor when first accessed
    @MainActor
    private lazy var deviceInfo: DeviceInfo = .init(
        model: UIDevice.current.model,
        osVersion: UIDevice.current.systemVersion
    )

    private var eventBuffer: [SDKEvent] = []
    private var flushTask: Task<Void, Never>?
    private var notificationObservers: [NSObjectProtocol] = []
    private let consoleOutput: ConsoleLogOutput
    private let apiOutput: APILogOutput?

    // Flush management
    private var flushFailureCount = 0
    private var lastFlushAttemptTime: Date?
    private static let maxConsecutiveFailures = 10

    private struct DeviceInfo {
        let model: String
        let osVersion: String
    }

    // MARK: - Initialization

    private init(config: LoggerConfiguration) {
        self.config = config
        self.consoleOutput = ConsoleLogOutput()

        if config.enableApiOutput {
            self.apiOutput = APILogOutput(
                apiKey: config.apiKey,
                endpoint: config.loggingEndpoint,
                sdkVersion: config.sdkVersion
            )
        } else {
            self.apiOutput = nil
        }
    }

    /// Initialize lifecycle observers after actor is fully initialized
    /// Must be called separately from init to avoid Swift 6 concurrency issues
    private func initializeAfterActorReady() {
        setupLifecycleObservers()
        startFlushTimer()
    }

    // MARK: - Lifecycle Observation

    private func setupLifecycleObservers() {
        let center = NotificationCenter.default

        // App entering background - flush immediately
        let backgroundObserver = center.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { [weak self] in
                await self?.flush()
            }
        }

        // App terminating - final flush attempt
        let terminationObserver = center.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { [weak self] in
                await self?.flush(timeoutMs: 5000)
            }
        }

        notificationObservers = [backgroundObserver, terminationObserver]
    }

    // MARK: - Timer Management

    private func startFlushTimer() {
        flushTask?.cancel()
        // No need to await flushTask value as it's void and we just want to start a new one

        flushTask = Task { [weak self] in
            while !Task.isCancelled {
                // Sleep for the flush interval
                if let interval = self?.config.flushIntervalMs {
                    try? await Task.sleep(nanoseconds: UInt64(interval) * 1_000_000)

                } else {
                    // Fallback or exit if self is nil
                    return
                }

                guard !Task.isCancelled else { break }

                await self?.flush()
            }
        }
    }

    // MARK: - TruoraLogger Protocol Implementation

    public func logEvent(
        eventType: EventType,
        eventName: String,
        level: LogLevel,
        errorMessage: String?,
        retention: RetentionPeriod,
        metadata: [String: Any]?,
        stackTrace: String?
    ) async {
        // Auto-compute duration since logger initialization
        let durationMs = Int64(Date().timeIntervalSince(initializationTime) * 1000)

        // Get context from ValidationConfig
        let context = await getValidationContext()

        // Access deviceInfo on MainActor
        let deviceModel = await deviceInfo.model
        let osVersion = await deviceInfo.osVersion

        let event = SDKEvent(
            eventType: eventType,
            eventName: eventName,
            level: level,
            errorMessage: errorMessage,
            errorCode: nil,
            durationMs: durationMs,
            stackTrace: stackTrace,
            userId: context.userId,
            validationId: context.validationId,
            validationType: context.validationType,
            accountId: context.accountId,
            deviceModel: deviceModel,
            osVersion: osVersion,
            sdkVersion: config.sdkVersion,
            platform: "ios",
            metadata: convertMetadata(metadata) ?? [:],
            retention: retention
        )

        // Buffer the event
        eventBuffer.append(event)

        // Console output if enabled
        if config.enableConsoleOutput {
            await consoleOutput.output(event: event)
        }

        // Auto-flush if buffer is full
        if eventBuffer.count >= config.maxBufferSize {
            await flush()
        }
    }

    public func logCamera(
        eventName: String,
        level: LogLevel,
        errorMessage: String?,
        retention: RetentionPeriod,
        metadata: [String: Any]?
    ) async {
        await logEvent(
            eventType: .camera,
            eventName: eventName,
            level: level,
            errorMessage: errorMessage,
            retention: retention,
            metadata: metadata,
            stackTrace: nil
        )
    }

    public func logML(
        eventName: String,
        level: LogLevel,
        errorMessage: String?,
        retention: RetentionPeriod,
        metadata: [String: Any]?
    ) async {
        await logEvent(
            eventType: .mlModel,
            eventName: eventName,
            level: level,
            errorMessage: errorMessage,
            retention: retention,
            metadata: metadata,
            stackTrace: nil
        )
    }

    public func logView(
        viewName: String,
        level: LogLevel,
        retention: RetentionPeriod,
        metadata: [String: Any]?
    ) async {
        var mergedMetadata = metadata ?? [:]
        mergedMetadata["view_name"] = viewName

        await logEvent(
            eventType: .view,
            eventName: "view_\(viewName)",
            level: level,
            errorMessage: nil,
            retention: retention,
            metadata: mergedMetadata,
            stackTrace: nil
        )
    }

    public func logDevice(
        eventName: String,
        level: LogLevel,
        retention: RetentionPeriod,
        metadata: [String: Any]?
    ) async {
        await logEvent(
            eventType: .device,
            eventName: eventName,
            level: level,
            errorMessage: nil,
            retention: retention,
            metadata: metadata,
            stackTrace: nil
        )
    }

    public func logFeedback(
        eventName: String,
        level: LogLevel,
        errorMessage: String?,
        retention: RetentionPeriod,
        metadata: [String: Any]?
    ) async {
        await logEvent(
            eventType: .mlModel, // Map to supported ml_model type
            eventName: eventName,
            level: level,
            errorMessage: errorMessage,
            retention: retention,
            metadata: metadata,
            stackTrace: nil
        )
    }

    public func logSdk(
        eventName: String,
        level: LogLevel,
        errorMessage: String?,
        retention: RetentionPeriod,
        metadata: [String: Any]?
    ) async {
        await logEvent(
            eventType: .device, // Map to supported device type
            eventName: eventName,
            level: level,
            errorMessage: errorMessage,
            retention: retention,
            metadata: metadata,
            stackTrace: nil
        )
    }

    public func logException(
        eventType: EventType,
        eventName: String,
        exception: Error,
        level: LogLevel,
        retention: RetentionPeriod,
        metadata: [String: Any]?
    ) async {
        // Extract stack trace
        let stackTrace = Thread.callStackSymbols.joined(separator: "\n")

        // Get error message
        let errorMessage: String = if let truoraException = exception as? TruoraException {
            truoraException.errorDescription ?? "Unknown error"
        } else {
            exception.localizedDescription
        }

        await logEvent(
            eventType: eventType,
            eventName: eventName,
            level: level,
            errorMessage: errorMessage,
            retention: retention,
            metadata: metadata,
            stackTrace: stackTrace
        )
    }

    // MARK: - Flush

    public func flush() async {
        guard !eventBuffer.isEmpty else { return }

        // Backoff check: if we have failures, wait exponentially before retrying
        if flushFailureCount > 0 {
            let backoffSeconds = pow(2.0, Double(min(flushFailureCount, 6))) // 2s, 4s, 8s, 16s, 32s, 64s
            if let last = lastFlushAttemptTime, Date().timeIntervalSince(last) < backoffSeconds {
                return // Skip flush during backoff period
            }
        }

        // Copy buffer atomically (actor-isolated)
        let eventsToFlush = eventBuffer

        // Send to API if configured
        if let apiOutput {
            let success = await apiOutput.output(events: eventsToFlush)
            if success {
                eventBuffer.removeAll()
                flushFailureCount = 0
                lastFlushAttemptTime = nil
            } else {
                flushFailureCount += 1
                lastFlushAttemptTime = Date()
                #if DEBUG
                print("⚠️ [TruoraLogger] Flush failed (consecutive: \(flushFailureCount)). Retaining events.")
                #endif
            }
        } else {
            // If no API output (e.g. testing/dev), just clear
            eventBuffer.removeAll()
        }
    }

    public func flush(timeoutMs: Int64) async {
        // Use withTimeoutOrNil for time-bounded flush
        let timeoutSeconds = TimeInterval(timeoutMs) / 1000.0
        await withTimeoutOrNil(timeoutSeconds: timeoutSeconds) {
            await self.flush()
        }
    }

    // MARK: - Shutdown

    /// Shutdown the logger and release resources.
    /// Any pending events may be lost.
    public func shutdown() async {
        flushTask?.cancel()
        flushTask = nil

        // Remove notification observers
        notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
        notificationObservers.removeAll()

        // Final flush attempt
        await flush(timeoutMs: 5000)
    }

    // MARK: - Helpers

    /// Validation context structure to avoid large tuples
    private struct ValidationContext {
        let userId: String?
        let validationId: String?
        let validationType: String?
        let accountId: String?
    }

    /// Get validation context from ValidationConfig
    private func getValidationContext() async -> ValidationContext {
        let config = await MainActor.run { ValidationConfig.shared }
        let accountId = await MainActor.run { config.accountId }
        let validationId = await MainActor.run { config.validationId }

        return ValidationContext(
            userId: accountId,
            validationId: validationId,
            validationType: nil,
            accountId: accountId
        )
    }

    // GDPR Forbidden keys from backend spec (static to avoid recreating on every call)
    private static let forbiddenKeys: Set<String> = [
        "user_id", "userid", "user", "username", "email", "mail", "e_mail",
        "phone", "phone_number", "phonenumber", "mobile", "name", "first_name",
        "firstname", "last_name", "lastname", "address", "street", "city",
        "postal_code", "postalcode", "imei", "serial_number", "serialnumber",
        "mac_address", "macaddress", "device_id", "deviceid", "advertising_id",
        "advertisingid", "adid", "android_id", "androidid", "ios_idfa", "idfa",
        "idfv", "credit_card", "creditcard", "card_number", "cardnumber",
        "account_number", "accountnumber", "ssn", "social_security",
        "socialsecurity", "fingerprint", "face_data", "facedata", "biometric",
        "retina", "password", "pwd", "token", "auth_token", "authtoken",
        "ip_address", "ipaddress", "ip", "geolocation", "gps", "latitude",
        "longitude", "lat", "lon", "lng"
    ]

    /// Convert Any metadata to String metadata and filter forbidden GDPR keys
    private func convertMetadata(_ metadata: [String: Any]?) -> [String: String]? {
        guard let metadata else { return nil }

        return metadata.reduce(into: [String: String]()) { result, element in
            let key = element.key.lowercased()
            if !forbiddenKeys.contains(key) {
                result[element.key] = "\(element.value)"
            }
        }
    }

    /// Execute with timeout (in seconds)
    private func withTimeoutOrNil<T>(
        timeoutSeconds: TimeInterval,
        operation: @escaping () async throws -> T
    ) async rethrows -> T? {
        do {
            return try await withThrowingTaskGroup(of: T.self) { group in
                group.addTask {
                    try await operation()
                }

                group.addTask {
                    try await Task.sleep(nanoseconds: UInt64(timeoutSeconds * 1_000_000_000))
                    throw CancellationError()
                }

                guard let result = try await group.next() else {
                    group.cancelAll()
                    return nil
                }

                group.cancelAll()
                return result
            }
        } catch {
            return nil
        }
    }
}
