import Foundation

/// Orchestrates injection detection reporting: detect -> encode -> sign -> log.
///
/// Uses `actor` isolation for thread safety (matches `TruoraLogger`'s async API).
/// Each call to `reportLayer(_:validationId:flowType:)` runs the appropriate
/// detection layer, encodes the results to a bitmask, signs the report (if the
/// native xcframework is linked), and logs it via `TruoraLogger.logDevice()`.
///
/// **Deduplication:** Tracks an accumulated bitmask across calls. Only new
/// signals (delta) are reported, preventing double-counting when runtime
/// re-checks find the same conditions.
///
/// **Escalation:** Trust scores below the threshold (50 default) trigger
/// `.error` level logging, which causes session escalation via the
/// dual-buffer drain in `SdkLogger`.
actor DetectionReporter {
    private let detector: InjectionDetector
    private let logger: TruoraLogger
    private var accumulatedBitmask: UInt32 = 0

    /// Creates a reporter that wraps an injection detector and logs results.
    ///
    /// - Parameters:
    ///   - detector: The `InjectionDetector` providing layered detection
    ///   - logger: Logger for sending `EventType.device` events to the backend
    init(detector: InjectionDetector, logger: TruoraLogger) {
        self.detector = detector
        self.logger = logger
    }

    /// Runs the named detection layer, encodes results, signs, and logs.
    ///
    /// - Parameters:
    ///   - layerName: Layer identifier: "init", "camera", or "runtime"
    ///   - validationId: Current validation session identifier
    ///   - flowType: Flow type ("face" or "document")
    func reportLayer(
        _ layerName: String,
        validationId: String,
        flowType: String
    ) async {
        // 1. Run appropriate detector method
        guard runDetectorLayer(layerName) else { return }

        // 2. Get cumulative trust result
        let trustResult = detector.computeTrustResult()

        // 3. Encode bitmask from all accumulated risk factors
        let newBitmask = BitmaskEncoder.encode(trustResult.riskFactors)

        // 4. Compute delta: only new signals since last report
        let deltaBitmask = newBitmask & ~accumulatedBitmask

        // 5. Update accumulated state
        accumulatedBitmask |= newBitmask

        // 6. Timestamp
        let timestamp = Int64(Date().timeIntervalSince1970)

        // 7. Sign report (or use fallback when bridge unavailable)
        let signature: String
        let bitmaskVersion: Int
        let threshold: Int

        if NativeDetectionBridge.isAvailable {
            let signed = NativeDetectionBridge.signReport(
                validationId: validationId,
                flowType: flowType,
                trustScore: trustResult.trustScore,
                riskBitmask: accumulatedBitmask,
                timestamp: timestamp
            )
            if signed == nil {
                await logger.logSdk(
                    eventName: "sign_report_failed",
                    level: .warning,
                    errorMessage: "Report signing failed;"
                        + " sending unsigned",
                    retention: .oneWeek,
                    metadata: nil
                )
            }
            signature = signed ?? "unsigned"
            bitmaskVersion = NativeDetectionBridge.getBitmaskVersion()
            threshold = NativeDetectionBridge.getEscalationThreshold()
        } else {
            signature = "unsigned"
            bitmaskVersion = BitmaskEncoder.version
            threshold = 50
        }

        // 8. Determine log level based on escalation threshold
        let level: LogLevel = trustResult.trustScore < threshold ? .error : .info

        // 9. Log the detection report as a device event
        let metadata: [String: Any] = [
            "trust_score": trustResult.trustScore,
            "risk_bitmask": String(accumulatedBitmask, radix: 16),
            "delta_bitmask": String(deltaBitmask, radix: 16),
            "signature": signature,
            "ts": timestamp,
            "bitmask_v": bitmaskVersion
        ]

        await logger.logDevice(
            eventName: "injection_\(layerName)",
            level: level,
            retention: .oneWeek,
            metadata: metadata
        )
    }

    /// Clears accumulated state and resets the underlying detector.
    func reset() {
        accumulatedBitmask = 0
        detector.reset()
    }

    // MARK: - Private

    /// Dispatches to the correct detector method based on layer name.
    ///
    /// - Returns: `true` if the layer was recognized and run,
    ///   `false` for unknown layer names.
    private func runDetectorLayer(_ layerName: String) -> Bool {
        switch layerName {
        case "init":
            detector.runInitChecks()
            return true
        case "camera":
            detector.runCameraChecks()
            return true
        case "runtime":
            detector.runRuntimeChecks()
            return true
        default:
            assertionFailure("Unknown detection layer: \(layerName)")
            return false
        }
    }
}
