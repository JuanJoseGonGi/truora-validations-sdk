import Foundation

/// Represents a single risk signal detected during injection attack analysis.
struct RiskFactor: Codable, Equatable {
    /// Category of the risk (e.g., "simulator", "virtual_camera", "jailbreak")
    let category: String

    /// Human-readable description of the detected signal
    let signal: String

    /// Penalty points subtracted from the trust score (0-100)
    let penalty: Int

    /// Confidence level of this detection ("high", "medium", "low")
    let confidence: String
}

/// Aggregated trust assessment computed from accumulated risk factors.
///
/// The trust score starts at 100 and is reduced by the sum of all risk factor penalties,
/// clamped to the range 0-100.
struct TrustResult: Codable, Equatable {
    /// Computed trust score: `max(0, min(100, 100 - totalPenalty))`
    let trustScore: Int

    /// All risk factors that contributed to the score reduction
    let riskFactors: [RiskFactor]

    /// Timestamp when this result was computed
    let timestamp: Date

    init(riskFactors: [RiskFactor], timestamp: Date = Date()) {
        let totalPenalty = riskFactors.reduce(0) { $0 + $1.penalty }
        self.trustScore = max(0, min(100, 100 - totalPenalty))
        self.riskFactors = riskFactors
        self.timestamp = timestamp
    }
}
