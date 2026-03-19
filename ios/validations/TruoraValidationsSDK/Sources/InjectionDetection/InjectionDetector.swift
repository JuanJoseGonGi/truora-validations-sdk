import Foundation

/// Orchestrates layered injection attack detection using a defense-in-depth approach.
///
/// Detection runs in 3 layers:
/// - **Layer 1 (Init):** Environment (simulator) + Jailbreak checks. Run once at SDK initialization.
/// - **Layer 2 (Camera Setup):** Camera device checks. Run when the camera session starts.
/// - **Layer 3 (Runtime):** Jailbreak re-check. Run periodically to catch tools activated after init.
///
/// Risk factors from all layers accumulate into a single `TrustResult` with a penalty-based score.
/// Thread-safe via `NSLock` to support calls from different lifecycle points.
final class InjectionDetector: @unchecked Sendable {
    private let systemInfo: SystemInfoProviding
    private let cameraInfo: CameraInfoProviding
    private let lock = NSLock()
    private var accumulatedFactors: [RiskFactor] = []

    init(
        systemInfo: SystemInfoProviding = DefaultSystemInfoProvider(),
        cameraInfo: CameraInfoProviding = DefaultCameraInfoProvider()
    ) {
        self.systemInfo = systemInfo
        self.cameraInfo = cameraInfo
    }

    // MARK: - Layer 1: Init Checks

    /// Runs environment (simulator) and jailbreak checks.
    /// Call once during SDK initialization.
    @discardableResult
    func runInitChecks() -> [RiskFactor] {
        let environmentFactors = EnvironmentChecker(systemInfo: systemInfo).check()
        let jailbreakFactors = JailbreakChecker(systemInfo: systemInfo).check()
        let newFactors = environmentFactors + jailbreakFactors
        appendFactors(newFactors)
        return newFactors
    }

    // MARK: - Layer 2: Camera Checks

    /// Runs camera device checks for virtual/external cameras.
    /// Call when the camera session starts.
    @discardableResult
    func runCameraChecks() -> [RiskFactor] {
        let newFactors = CameraChecker(cameraInfo: cameraInfo).check()
        appendFactors(newFactors)
        return newFactors
    }

    // MARK: - Layer 3: Runtime Checks

    /// Re-runs jailbreak checks to catch tools activated after init.
    /// Call periodically during capture (e.g., every 30 seconds).
    @discardableResult
    func runRuntimeChecks() -> [RiskFactor] {
        let newFactors = JailbreakChecker(systemInfo: systemInfo).check()
        appendFactors(newFactors)
        return newFactors
    }

    // MARK: - Trust Result

    /// Computes the trust result from all accumulated risk factors.
    func computeTrustResult() -> TrustResult {
        lock.lock()
        let factors = accumulatedFactors
        lock.unlock()
        return TrustResult(riskFactors: factors)
    }

    /// Clears all accumulated risk factors, resetting the trust score to 100.
    func reset() {
        lock.lock()
        accumulatedFactors.removeAll()
        lock.unlock()
    }

    // MARK: - Reporter Factory

    /// Creates a `DetectionReporter` that wraps this detector for progressive reporting.
    ///
    /// The returned actor orchestrates detect -> encode -> log, sending
    /// reports through the provided logger at each lifecycle layer.
    ///
    /// - Parameters:
    ///   - logger: Logger for sending `EventType.device` events to the backend
    ///   - blockingThreshold: Trust score below which the flow is blocked (default 50)
    /// - Returns: A new `DetectionReporter` actor bound to this detector
    func createReporter(logger: TruoraLogger, blockingThreshold: Int = 50) -> DetectionReporter {
        DetectionReporter(detector: self, logger: logger, blockingThreshold: blockingThreshold)
    }

    // MARK: - Private

    private func appendFactors(_ factors: [RiskFactor]) {
        guard !factors.isEmpty else { return }
        lock.lock()
        accumulatedFactors.append(contentsOf: factors)
        lock.unlock()
    }
}
