//
//  MemoryMonitor.swift
//  TruoraValidationsSDK
//

import Foundation
import UIKit

/// Monitors memory pressure using UIApplication memory warnings
/// and `os_proc_available_memory()` (iOS 13+).
///
/// Thread-safe via an internal lock.
final class MemoryMonitor: MemoryMonitoring, @unchecked Sendable {
    private static let criticalMemoryThresholdMB: UInt64 = 50
    private static let lowMemoryThresholdMB: UInt64 = 150

    private let lock = NSLock()
    private var _currentPressure: MemoryPressureLevel = .unknown
    private var observer: NSObjectProtocol?

    var currentPressure: MemoryPressureLevel {
        lock.lock()
        defer { lock.unlock() }
        return _currentPressure
    }

    /// Start monitoring memory pressure.
    func start() {
        // Read initial state
        updateFromPoll()

        observer = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            guard let self else { return }
            // Memory warning is binary (no severity) — treat as critical.
            lock.lock()
            defer { lock.unlock() }
            _currentPressure = .critical
        }
    }

    /// Stop monitoring and release resources.
    func stop() {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
        observer = nil
        lock.lock()
        _currentPressure = .unknown
        lock.unlock()
    }

    /// Actively poll memory pressure using os_proc_available_memory.
    func updateFromPoll() {
        let level = Self.pollMemoryPressure()
        lock.lock()
        _currentPressure = level
        lock.unlock()
    }

    static func pollMemoryPressure() -> MemoryPressureLevel {
        let availableBytes = os_proc_available_memory()
        let totalBytes = ProcessInfo.processInfo.physicalMemory

        guard totalBytes > 0 else { return .normal }

        // os_proc_available_memory returns remaining headroom before jetsam limit
        let availableMB = availableBytes / (1024 * 1024)

        // Use absolute thresholds based on remaining memory
        // (percentage of total RAM is less meaningful on iOS due to per-app jetsam limits)
        if availableMB < criticalMemoryThresholdMB {
            return .critical
        }
        if availableMB < lowMemoryThresholdMB {
            return .low
        }
        return .normal
    }
}
