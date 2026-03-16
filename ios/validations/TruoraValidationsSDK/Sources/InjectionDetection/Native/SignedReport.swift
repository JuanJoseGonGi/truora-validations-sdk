import Foundation

/// HMAC-signed detection report payload sent to the validations backend.
///
/// Contains the trust score, accumulated risk bitmask, delta (new signals only),
/// HMAC signature, timestamp, and bitmask layout version. Sent as metadata
/// in `EventType.device` events via `TruoraLogger.logDevice()`.
struct SignedReport: Codable, Equatable {
    /// Trust score (0-100) computed from accumulated risk factor penalties
    let trustScore: Int

    /// Cumulative bitmask of all risk signals detected so far
    let riskBitmask: UInt32

    /// Bitmask of newly detected signals since the last report
    let deltaBitmask: UInt32

    /// HMAC-SHA256 signature hex string, or "unsigned" when xcframework unavailable
    let signature: String

    /// Unix epoch timestamp (seconds) when the report was generated
    let timestamp: Int64

    /// Version of the bitmask bit-position layout (for backend decoding)
    let bitmaskVersion: Int
}
