import Foundation

/// Configuration for the injection attack detection module.
///
/// By default, detection is enabled in report-only mode. When `strictMode` is enabled,
/// the SDK will refuse to proceed if the trust score falls below `strictModeThreshold`.
struct InjectionConfig: Equatable {
    /// Whether injection detection is enabled
    let enabled: Bool

    /// When true, the SDK blocks operation if trust score falls below the threshold
    let strictMode: Bool

    /// Trust score threshold for strict mode (0-100). Operation blocked if score is below this value.
    let strictModeThreshold: Int

    init(enabled: Bool = true, strictMode: Bool = false, strictModeThreshold: Int = 30) {
        self.enabled = enabled
        self.strictMode = strictMode
        self.strictModeThreshold = strictModeThreshold
    }
}
