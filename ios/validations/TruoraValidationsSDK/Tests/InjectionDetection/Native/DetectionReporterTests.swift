import Foundation
import XCTest
@testable import TruoraValidationsSDK

// MARK: - Mock Logger for Detection Reporter Tests

/// Records all logDevice calls for verification in detection reporter tests.
/// Uses NSLock for thread-safe access from async contexts without @MainActor.
final class MockDetectionLogger: TruoraLogger, @unchecked Sendable {
    struct LogEntry {
        let eventType: EventType?
        let eventName: String
        let level: LogLevel
        let errorMessage: String?
        let retention: RetentionPeriod
        let metadata: [String: Any]?
    }

    private let lock = NSLock()
    private var _entries: [LogEntry] = []

    var entries: [LogEntry] {
        lock.lock()
        defer { lock.unlock() }
        return _entries
    }

    // MARK: - TruoraLogger conformance

    func logEvent(
        eventType: EventType,
        eventName: String,
        level: LogLevel,
        errorMessage: String?,
        retention: RetentionPeriod,
        metadata: [String: Any]?,
        stackTrace: String?
    ) async {
        lock.lock()
        _entries.append(LogEntry(
            eventType: eventType,
            eventName: eventName,
            level: level,
            errorMessage: errorMessage,
            retention: retention,
            metadata: metadata
        ))
        lock.unlock()
    }

    func logCamera(
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

    func logML(
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

    func logView(
        viewName: String,
        level: LogLevel,
        retention: RetentionPeriod,
        metadata: [String: Any]?
    ) async {
        await logEvent(
            eventType: .view,
            eventName: viewName,
            level: level,
            errorMessage: nil,
            retention: retention,
            metadata: metadata,
            stackTrace: nil
        )
    }

    func logDevice(
        eventName: String,
        level: LogLevel,
        retention: RetentionPeriod,
        metadata: [String: Any]?
    ) async {
        lock.lock()
        _entries.append(LogEntry(
            eventType: .device,
            eventName: eventName,
            level: level,
            errorMessage: nil,
            retention: retention,
            metadata: metadata
        ))
        lock.unlock()
    }

    func logFeedback(
        eventName: String,
        level: LogLevel,
        errorMessage: String?,
        retention: RetentionPeriod,
        metadata: [String: Any]?
    ) async {}

    func logSdk(
        eventName: String,
        level: LogLevel,
        errorMessage: String?,
        retention: RetentionPeriod,
        metadata: [String: Any]?
    ) async {}

    func logException(
        eventType: EventType,
        eventName: String,
        exception: Error,
        level: LogLevel,
        retention: RetentionPeriod,
        metadata: [String: Any]?
    ) async {}

    func flush() async {}

    func flush(timeoutMs: Int64) async {}
}

// MARK: - Tests

final class DetectionReporterTests: XCTestCase {
    // MARK: - Helpers

    /// Creates a detector pre-configured with the given mock providers.
    private func makeDetector(
        isSimulator: Bool = false,
        simulatorDeviceName: String? = nil,
        existingFiles: Set<String> = [],
        canWriteSandbox: Bool = false,
        loadedDylibs: [String] = [],
        devices: [CameraDeviceInfo] = [
            CameraDeviceInfo(
                deviceType: .builtInWideAngle,
                position: "back",
                uniqueID: "cam-1",
                lensPosition: 0.5
            )
        ]
    ) -> InjectionDetector {
        let systemInfo = MockSystemInfoProvider(
            isSimulator: isSimulator,
            simulatorDeviceName: simulatorDeviceName,
            existingFiles: existingFiles,
            canWriteSandbox: canWriteSandbox,
            loadedDylibs: loadedDylibs
        )
        let cameraInfo = MockCameraInfoProvider(devices: devices)
        return InjectionDetector(systemInfo: systemInfo, cameraInfo: cameraInfo)
    }

    // MARK: - reportLayer event names

    func testReportLayer_init_logsInjectionInitEvent() async {
        let detector = makeDetector()
        let logger = MockDetectionLogger()
        let reporter = DetectionReporter(detector: detector, logger: logger)

        await reporter.reportLayer("init", validationId: "v1", flowType: "face")

        XCTAssertEqual(logger.entries.count, 1)
        XCTAssertEqual(logger.entries.first?.eventName, "injection_init")
    }

    func testReportLayer_camera_logsInjectionCameraEvent() async {
        let detector = makeDetector()
        let logger = MockDetectionLogger()
        let reporter = DetectionReporter(detector: detector, logger: logger)

        await reporter.reportLayer("camera", validationId: "v1", flowType: "face")

        XCTAssertEqual(logger.entries.count, 1)
        XCTAssertEqual(logger.entries.first?.eventName, "injection_camera")
    }

    func testReportLayer_runtime_logsInjectionRuntimeEvent() async {
        let detector = makeDetector()
        let logger = MockDetectionLogger()
        let reporter = DetectionReporter(detector: detector, logger: logger)

        await reporter.reportLayer("runtime", validationId: "v1", flowType: "face")

        XCTAssertEqual(logger.entries.count, 1)
        XCTAssertEqual(logger.entries.first?.eventName, "injection_runtime")
    }

    // MARK: - Deduplication

    func testReportLayer_sameSignalsTwice_deltaBitmaskIsZeroOnSecondCall() async {
        let detector = makeDetector(isSimulator: true)
        let logger = MockDetectionLogger()
        let reporter = DetectionReporter(detector: detector, logger: logger)

        // First call: init layer detects simulator
        await reporter.reportLayer("init", validationId: "v1", flowType: "face")
        // Second call: runtime layer re-runs jailbreak (no new signals since no files)
        await reporter.reportLayer("runtime", validationId: "v1", flowType: "face")

        XCTAssertEqual(logger.entries.count, 2)

        let secondMetadata = logger.entries[1].metadata
        let deltaBitmask = secondMetadata?["delta_bitmask"] as? String
        XCTAssertEqual(deltaBitmask, "0", "Delta should be 0 when no new signals detected")
    }

    func testReportLayer_newSignals_deltaBitmaskIsNonZero() async {
        let detector = makeDetector(
            isSimulator: true,
            devices: [
                CameraDeviceInfo(
                    deviceType: .external,
                    position: "unspecified",
                    uniqueID: "ext-1",
                    lensPosition: nil
                )
            ]
        )
        let logger = MockDetectionLogger()
        let reporter = DetectionReporter(detector: detector, logger: logger)

        // First: init detects simulator
        await reporter.reportLayer("init", validationId: "v1", flowType: "face")
        // Second: camera detects external camera (new signal)
        await reporter.reportLayer("camera", validationId: "v1", flowType: "face")

        XCTAssertEqual(logger.entries.count, 2)

        let secondMetadata = logger.entries[1].metadata
        let deltaBitmask = secondMetadata?["delta_bitmask"] as? String
        XCTAssertNotEqual(deltaBitmask, "0", "Delta should be non-zero for new signals")
    }

    // MARK: - Escalation

    func testReportLayer_lowTrustScore_usesErrorLevel() async {
        // Simulator (50 penalty) + sandbox compromised (50 penalty) = trust score 0
        let detector = makeDetector(isSimulator: true, canWriteSandbox: true)
        let logger = MockDetectionLogger()
        let reporter = DetectionReporter(detector: detector, logger: logger)

        await reporter.reportLayer("init", validationId: "v1", flowType: "face")

        XCTAssertEqual(
            logger.entries.first?.level,
            .error,
            "Trust score < 50 should trigger .error level"
        )
    }

    func testReportLayer_highTrustScore_usesInfoLevel() async {
        // Clean device: trust score 100
        let detector = makeDetector()
        let logger = MockDetectionLogger()
        let reporter = DetectionReporter(detector: detector, logger: logger)

        await reporter.reportLayer("init", validationId: "v1", flowType: "face")

        XCTAssertEqual(
            logger.entries.first?.level,
            .info,
            "Trust score >= 50 should use .info level"
        )
    }

    // MARK: - Unsigned fallback

    func testReportLayer_bridgeUnavailable_signatureIsUnsigned() async {
        let detector = makeDetector()
        let logger = MockDetectionLogger()
        let reporter = DetectionReporter(detector: detector, logger: logger)

        await reporter.reportLayer("init", validationId: "v1", flowType: "face")

        let metadata = logger.entries.first?.metadata
        let signature = metadata?["signature"] as? String
        XCTAssertEqual(
            signature,
            "unsigned",
            "Without xcframework, signature should be 'unsigned'"
        )
    }

    // MARK: - Metadata fields

    func testReportLayer_metadataContainsExpectedKeys() async {
        let detector = makeDetector(isSimulator: true)
        let logger = MockDetectionLogger()
        let reporter = DetectionReporter(detector: detector, logger: logger)

        await reporter.reportLayer("init", validationId: "v1", flowType: "face")

        let metadata = logger.entries.first?.metadata
        XCTAssertNotNil(metadata?["trust_score"])
        XCTAssertNotNil(metadata?["risk_bitmask"])
        XCTAssertNotNil(metadata?["delta_bitmask"])
        XCTAssertNotNil(metadata?["signature"])
        XCTAssertNotNil(metadata?["ts"])
        XCTAssertNotNil(metadata?["bitmask_v"])
    }

    // MARK: - Reset

    func testReset_clearsAccumulatedBitmask() async {
        let detector = makeDetector(isSimulator: true)
        let logger = MockDetectionLogger()
        let reporter = DetectionReporter(detector: detector, logger: logger)

        await reporter.reportLayer("init", validationId: "v1", flowType: "face")
        await reporter.reset()
        await reporter.reportLayer("init", validationId: "v1", flowType: "face")

        // After reset, the same signals should produce a non-zero delta again
        XCTAssertEqual(logger.entries.count, 2)
        let secondDelta = logger.entries[1].metadata?["delta_bitmask"] as? String
        XCTAssertNotEqual(
            secondDelta,
            "0",
            "After reset, same signals should produce non-zero delta"
        )
    }

    // MARK: - InjectionDetector factory

    func testInjectionDetector_createReporter_returnsDetectionReporter() {
        let detector = makeDetector()
        let logger = MockDetectionLogger()
        let reporter = detector.createReporter(logger: logger)

        // Verify it returned a DetectionReporter (type check)
        XCTAssertTrue(type(of: reporter) == DetectionReporter.self)
    }

    // MARK: - Retention period

    func testReportLayer_usesOneWeekRetention() async {
        let detector = makeDetector()
        let logger = MockDetectionLogger()
        let reporter = DetectionReporter(detector: detector, logger: logger)

        await reporter.reportLayer("init", validationId: "v1", flowType: "face")

        XCTAssertEqual(logger.entries.first?.retention, .oneWeek)
    }
}
