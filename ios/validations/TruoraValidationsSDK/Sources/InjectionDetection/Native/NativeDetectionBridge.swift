import Foundation

/// Facade for the pre-compiled TruoraDetection C library (.xcframework).
///
/// Uses conditional compilation (`#if canImport(TruoraDetection)`) to bridge
/// to C functions when the xcframework is linked, and returns nil/fallback
/// values when it is not (development and test builds).
///
/// The C library source lives in scrap-services (private repo) and is
/// distributed as a pre-built binary via CI artifacts. This struct never
/// exposes detection logic -- only opaque function calls.
enum NativeDetectionBridge {
    // MARK: - Availability

    /// Whether the TruoraDetection xcframework is linked in this build.
    static var isAvailable: Bool {
        #if canImport(TruoraDetection)
        return true
        #else
        return false
        #endif
    }

    // MARK: - Detection

    /// Runs native detection checks with the given signal mask.
    ///
    /// - Parameter mask: Bitmask selecting which check categories to run
    /// - Returns: Tuple of (trustScore, riskBitmask), or nil if xcframework unavailable
    static func runChecks(mask: UInt32) -> (trustScore: Int, riskBitmask: UInt32)? {
        #if canImport(TruoraDetection)
        let result = td_run_checks(mask)
        return (trustScore: Int(result.trust_score), riskBitmask: result.risk_bitmask)
        #else
        return nil
        #endif
    }

    // MARK: - Signing

    /// Generates an HMAC-SHA256 signature for the detection report.
    ///
    /// - Parameters:
    ///   - validationId: Current validation session identifier
    ///   - flowType: Flow type ("face" or "document")
    ///   - trustScore: Computed trust score (0-100)
    ///   - riskBitmask: Accumulated risk signal bitmask
    ///   - timestamp: Unix epoch timestamp (seconds)
    /// - Returns: Hex-encoded HMAC signature string, or nil if xcframework unavailable
    static func signReport(
        validationId: String,
        flowType: String,
        trustScore: Int,
        riskBitmask: UInt32,
        timestamp: Int64
    ) -> String? {
        #if canImport(TruoraDetection)
        guard let cResult = td_sign_report(
            validationId,
            flowType,
            Int32(trustScore),
            riskBitmask,
            timestamp
        ) else {
            return nil
        }
        let signature = String(cString: cResult)
        free(cResult)
        return signature
        #else
        return nil
        #endif
    }

    // MARK: - Configuration

    /// Returns the bitmask layout version from the native library.
    /// Falls back to `BitmaskEncoder.version` when xcframework is unavailable.
    static func getBitmaskVersion() -> Int {
        #if canImport(TruoraDetection)
        return Int(td_bitmask_version())
        #else
        return BitmaskEncoder.version
        #endif
    }

    /// Returns the escalation threshold from the native library.
    /// Falls back to 50 when xcframework is unavailable.
    static func getEscalationThreshold() -> Int {
        #if canImport(TruoraDetection)
        return Int(td_escalation_threshold())
        #else
        return 50
        #endif
    }
}
