//
//  BatteryMonitor.swift
//  TruoraValidationsSDK
//

import Foundation

/// Monitors low power mode using ProcessInfo (iOS 9+).
///
/// Thread-safe via an internal lock.
final class BatteryMonitor: BatteryMonitoring, @unchecked Sendable {
    private let lock = NSLock()
    private var _isLowPowerMode: Bool = false
    private var observer: NSObjectProtocol?

    var isLowPowerMode: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isLowPowerMode
    }

    /// Start monitoring power state.
    func start() {
        // Read initial state
        lock.lock()
        _isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        lock.unlock()

        observer = NotificationCenter.default.addObserver(
            forName: .NSProcessInfoPowerStateDidChange,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            let lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
            self?.lock.lock()
            self?._isLowPowerMode = lowPower
            self?.lock.unlock()
        }
    }

    /// Stop monitoring and release resources.
    func stop() {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
        observer = nil
        lock.lock()
        _isLowPowerMode = false
        lock.unlock()
    }
}
