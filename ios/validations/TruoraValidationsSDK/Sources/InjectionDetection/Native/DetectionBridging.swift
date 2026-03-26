import Foundation

/// Protocol abstracting the native detection bridge for testability.
///
/// Memory management (`td_free_string`) stays inside the concrete implementation.
/// The protocol returns Swift `String`, not raw pointers. Conformers handle
/// Rust-allocated memory internally.
///
/// `Sendable` is required because `DetectionReporter` is an `actor` and holds
/// the bridge as a stored property.
protocol DetectionBridging: Sendable {
    /// Run native detection checks and return the raw bitmask.
    func runChecks(checksMask: UInt32) -> UInt32

    /// Generate HMAC-SHA256 signature for the detection report.
    /// Returns `"unsigned"` if the native library fails to produce a signature.
    func signReport(
        validationId: String,
        flowType: String,
        trustScore: UInt32,
        riskBitmask: UInt32,
        timestamp: UInt64
    ) -> String

    /// Returns the bitmask layout version from the native library.
    func bitmaskVersion() -> UInt32

    /// Returns the escalation threshold for trust score blocking.
    func getEscalationThreshold() -> UInt32
}
