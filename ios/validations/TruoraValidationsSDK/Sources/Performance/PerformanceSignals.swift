//
//  PerformanceSignals.swift
//  TruoraValidationsSDK
//

import Foundation

// MARK: - Monitor Protocols (for testability)

/// Provides the current thermal state of the device.
protocol ThermalMonitoring: Sendable {
    var currentState: ThermalLevel { get }
}

/// Provides the current memory pressure level.
protocol MemoryMonitoring: Sendable {
    var currentPressure: MemoryPressureLevel { get }
}

/// Provides the current network quality level.
protocol NetworkMonitoring: Sendable {
    var currentQuality: NetworkQualityLevel { get }
}

/// Provides the current low power mode state.
protocol BatteryMonitoring: Sendable {
    var isLowPowerMode: Bool { get }
}

/// Provides the active processor count (for TFLite thread decisions).
protocol ProcessorInfoProviding: Sendable {
    var activeProcessorCount: Int { get }
}

/// Default implementation that delegates to ProcessInfo.
struct SystemProcessorInfo: ProcessorInfoProviding {
    var activeProcessorCount: Int {
        ProcessInfo.processInfo.activeProcessorCount
    }
}

/// Normalized thermal state levels.
/// Maps platform-specific thermal readings to SDK-internal severity levels.
enum ThermalLevel: Int, Comparable {
    /// No thermal concern.
    case nominal = 0
    /// Slightly warm — no action needed yet.
    case fair = 1
    /// Hot — should reduce workload to avoid further throttling.
    case serious = 2
    /// Critical — device is actively throttling; minimize all work.
    case critical = 3
    /// Thermal monitoring not available.
    case unknown = -1

    func isAtLeast(_ threshold: ThermalLevel) -> Bool {
        guard self != .unknown else { return false }
        return self.rawValue >= threshold.rawValue
    }

    static func < (lhs: ThermalLevel, rhs: ThermalLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Normalized memory pressure levels.
enum MemoryPressureLevel: Int, Comparable {
    /// Plenty of memory available.
    case normal = 0
    /// Memory is getting low — release caches, reduce allocations.
    case low = 1
    /// Critical memory pressure — risk of jetsam kill.
    case critical = 2
    /// Memory monitoring not available.
    case unknown = -1

    func isAtLeast(_ threshold: MemoryPressureLevel) -> Bool {
        guard self != .unknown else { return false }
        return self.rawValue >= threshold.rawValue
    }

    static func < (lhs: MemoryPressureLevel, rhs: MemoryPressureLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Normalized network quality levels.
enum NetworkQualityLevel: Int, Comparable {
    /// Strong connection (Wi-Fi or fast cellular).
    case good = 0
    /// Metered or moderate connection (cellular, hotspot).
    case constrained = 1
    /// Slow or unreliable connection.
    case poor = 2
    /// Network monitoring not available.
    case unknown = -1

    func isAtLeast(_ threshold: NetworkQualityLevel) -> Bool {
        guard self != .unknown else { return false }
        return self.rawValue >= threshold.rawValue
    }

    static func < (lhs: NetworkQualityLevel, rhs: NetworkQualityLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Classification of ML inference speed relative to the available frame budget.
enum InferenceSpeedLevel: Int, Comparable {
    /// Inference uses less than 50% of frame budget.
    case fast = 0
    /// Inference uses 50-90% of frame budget.
    case slow = 1
    /// Inference uses more than 90% of frame budget.
    case tooSlow = 2
    /// Not enough data to classify.
    case unknown = -1

    func isAtLeast(_ threshold: InferenceSpeedLevel) -> Bool {
        guard self != .unknown else { return false }
        return self.rawValue >= threshold.rawValue
    }

    static func < (lhs: InferenceSpeedLevel, rhs: InferenceSpeedLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
