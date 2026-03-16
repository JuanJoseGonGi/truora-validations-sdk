//
//  PerformanceAdvisor.swift
//  TruoraValidationsSDK
//

import AVFoundation
import Foundation

/// Recommended video resolution preset.
enum VideoResolutionPreset {
    case hd720p // 1280x720 (default)
    case sd540p // 960x540 (constrained)

    var sessionPreset: AVCaptureSession.Preset {
        switch self {
        case .hd720p: .hd1280x720
        case .sd540p: .vga640x480 // closest standard AVFoundation preset below 720p
        }
    }

    var maxWidth: Int {
        switch self {
        case .hd720p: 1280
        case .sd540p: 960
        }
    }

    var maxHeight: Int {
        switch self {
        case .hd720p: 720
        case .sd540p: 540
        }
    }
}

/// Central performance advisor that reads device signals and recommends
/// parameter values for camera, ML, and network operations.
///
/// Fully automatic — no integrator configuration needed.
/// Each parameter is independently decided based on current signal state.
///
/// Downgrade is immediate; upgrade uses hysteresis to prevent oscillation.
///
/// Thread-safe via internal locks in each monitor and the advisor itself.
final class PerformanceAdvisor: @unchecked Sendable {
    // MARK: - Presets

    private static let jpegQualityDefault: CGFloat = 0.85
    private static let jpegQualityConstrained: CGFloat = 0.65
    private static let jpegQualityLow: CGFloat = 0.50

    private static let tfliteThreadsDefault = 2
    private static let tfliteThreadsReduced = 1

    private static let maxImageSizeDefault: CGFloat = 1024
    private static let maxImageSizeReduced: CGFloat = 768

    /// Hysteresis: wait this long before upgrading a parameter after conditions improve.
    private static let upgradeHysteresisSeconds: TimeInterval = 10.0

    // MARK: - Monitors

    let thermalMonitor: ThermalMonitoring
    let memoryMonitor: MemoryMonitoring
    let networkMonitor: NetworkMonitoring
    let batteryMonitor: BatteryMonitoring
    let inferenceTracker: InferenceLatencyTracker
    private let processorInfo: ProcessorInfoProviding
    private let clock: () -> Date

    // MARK: - Hysteresis timestamps

    private let lock = NSLock()
    private var lastResolutionDowngrade: Date?
    private var lastAutocaptureDowngrade: Date?

    // MARK: - Last logged values (to avoid log spam)

    private var lastLoggedResolution: VideoResolutionPreset?
    private var lastLoggedAutocapture: Bool?

    // MARK: - Logger (optional, injected)

    private var logger: TruoraLogger?

    // MARK: - Initializers

    /// Production initializer — creates real monitors.
    convenience init() {
        self.init(
            thermal: ThermalMonitor(),
            memory: MemoryMonitor(),
            network: NetworkMonitor(),
            battery: BatteryMonitor(),
            inferenceTracker: InferenceLatencyTracker(),
            processorInfo: SystemProcessorInfo()
        ) { Date() }
    }

    /// Testable initializer — accepts protocol-typed monitors and a controllable clock.
    init(
        thermal: ThermalMonitoring,
        memory: MemoryMonitoring,
        network: NetworkMonitoring,
        battery: BatteryMonitoring,
        inferenceTracker: InferenceLatencyTracker,
        processorInfo: ProcessorInfoProviding = SystemProcessorInfo(),
        clock: @escaping () -> Date = { Date() }
    ) {
        self.thermalMonitor = thermal
        self.memoryMonitor = memory
        self.networkMonitor = network
        self.batteryMonitor = battery
        self.inferenceTracker = inferenceTracker
        self.processorInfo = processorInfo
        self.clock = clock
    }

    // MARK: - Lifecycle

    /// Start all monitors. Call when camera capture begins.
    ///
    /// Safe to call in any context — uses optional chaining so if a monitor
    /// is a mock or different type, it is silently skipped. No force unwraps.
    func start(logger: TruoraLogger? = nil) {
        self.logger = logger
        (thermalMonitor as? ThermalMonitor)?.start()
        (memoryMonitor as? MemoryMonitor)?.start()
        (networkMonitor as? NetworkMonitor)?.start()
        (batteryMonitor as? BatteryMonitor)?.start()
        inferenceTracker.reset()
        logDeviceBaseline()
    }

    /// Stop all monitors and release resources. Call when camera capture ends.
    ///
    /// Safe to call in any context — uses optional chaining so if a monitor
    /// is a mock or different type, it is silently skipped. No force unwraps.
    func stop() {
        (thermalMonitor as? ThermalMonitor)?.stop()
        (memoryMonitor as? MemoryMonitor)?.stop()
        (networkMonitor as? NetworkMonitor)?.stop()
        (batteryMonitor as? BatteryMonitor)?.stop()
        inferenceTracker.reset()
        logger = nil
    }

    // MARK: - Parameter Recommendations

    /// Recommended video resolution.
    var recommendedVideoResolution: VideoResolutionPreset {
        let shouldDowngrade =
            thermalMonitor.currentState.isAtLeast(.serious)
            || memoryMonitor.currentPressure.isAtLeast(.critical)

        lock.lock()
        defer { lock.unlock() }
        let result: VideoResolutionPreset
        if shouldDowngrade {
            lastResolutionDowngrade = clock()
            result = .sd540p
        } else if isWithinHysteresisLocked(lastResolutionDowngrade) {
            result = .sd540p
        } else {
            result = .hd720p
        }
        logIfChangedLocked("resolution", newValue: result, lastValue: &lastLoggedResolution)
        return result
    }

    /// Whether ML-based autocapture should be active.
    /// Returns false if device conditions make ML inference too expensive.
    var shouldUseAutocapture: Bool {
        let shouldDisable =
            thermalMonitor.currentState.isAtLeast(.critical)
            || memoryMonitor.currentPressure.isAtLeast(.critical)
            || inferenceTracker.speed.isAtLeast(.tooSlow)

        lock.lock()
        defer { lock.unlock() }
        let result: Bool
        if shouldDisable {
            lastAutocaptureDowngrade = clock()
            result = false
        } else if isWithinHysteresisLocked(lastAutocaptureDowngrade) {
            result = false
        } else {
            result = true
        }
        logIfChangedLocked("autocapture", newValue: result, lastValue: &lastLoggedAutocapture)
        return result
    }

    /// Recommended JPEG compression quality (0.0 to 1.0).
    var recommendedJpegQuality: CGFloat {
        let net = networkMonitor.currentQuality
        if net.isAtLeast(.poor) {
            return Self.jpegQualityLow
        }
        if net.isAtLeast(.constrained) || batteryMonitor.isLowPowerMode {
            return Self.jpegQualityConstrained
        }
        return Self.jpegQualityDefault
    }

    /// Recommended TFLite interpreter thread count.
    var recommendedTFLiteThreadCount: Int {
        let activeProcessors = processorInfo.activeProcessorCount
        if thermalMonitor.currentState.isAtLeast(.serious) || activeProcessors <= 2 {
            return Self.tfliteThreadsReduced
        }
        return Self.tfliteThreadsDefault
    }

    /// Recommended maximum image dimension for compression.
    var recommendedMaxImageSize: CGFloat {
        if memoryMonitor.currentPressure.isAtLeast(.low)
            || networkMonitor.currentQuality.isAtLeast(.poor) {
            return Self.maxImageSizeReduced
        }
        return Self.maxImageSizeDefault
    }

    // MARK: - Private

    /// Caller must hold `lock`.
    private func isWithinHysteresisLocked(_ lastDowngrade: Date?) -> Bool {
        guard let lastDowngrade else { return false }
        return clock().timeIntervalSince(lastDowngrade) < Self.upgradeHysteresisSeconds
    }

    /// Caller must hold `lock`.
    private func logIfChangedLocked<T: Equatable>(
        _ param: String,
        newValue: T,
        lastValue: inout T?
    ) {
        guard newValue != lastValue else { return }
        lastValue = newValue

        guard let logger else { return }
        let metadata: [String: Any] = [
            "parameter": param,
            "value": String(describing: newValue),
            "thermal": String(describing: thermalMonitor.currentState),
            "memory": String(describing: memoryMonitor.currentPressure),
            "network": String(describing: networkMonitor.currentQuality),
            "low_power": batteryMonitor.isLowPowerMode,
            "inference_avg_ms": Int(inferenceTracker.averageSeconds * 1000)
        ]
        Task {
            await logger.logDevice(
                eventName: "perf_adapt_\(param)",
                level: .info,
                retention: .oneWeek,
                metadata: metadata
            )
        }
    }

    private func logDeviceBaseline() {
        guard let logger else { return }
        let metadata: [String: Any] = [
            "cpu_cores": ProcessInfo.processInfo.processorCount,
            "active_cores": ProcessInfo.processInfo.activeProcessorCount,
            "physical_memory_mb": ProcessInfo.processInfo.physicalMemory / (1024 * 1024),
            "thermal": String(describing: thermalMonitor.currentState),
            "memory": String(describing: memoryMonitor.currentPressure),
            "network": String(describing: networkMonitor.currentQuality),
            "low_power": batteryMonitor.isLowPowerMode
        ]
        Task {
            await logger.logDevice(
                eventName: "perf_baseline",
                level: .info,
                retention: .oneWeek,
                metadata: metadata
            )
        }
    }
}
