import Foundation

/// Configuration for the injection attack detection module.
///
/// Detection is always enforced when enabled. If the trust score falls
/// below `blockingThreshold`, the SDK blocks the capture flow.
struct InjectionConfig: Equatable {
    /// Whether injection detection is enabled
    let enabled: Bool

    /// Trust score threshold (0-100). Operation blocked if score is below this value.
    let blockingThreshold: Int

    init(enabled: Bool = true, blockingThreshold: Int = 50) {
        self.enabled = enabled
        self.blockingThreshold = blockingThreshold
    }
}
