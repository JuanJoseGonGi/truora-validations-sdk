//
//  ThermalMonitor.swift
//  TruoraValidationsSDK
//

import Foundation

/// Monitors device thermal state using ProcessInfo APIs (iOS 11+).
///
/// Thread-safe via an internal lock.
final class ThermalMonitor: ThermalMonitoring, @unchecked Sendable {
    private let lock = NSLock()
    private var _currentState: ThermalLevel = .unknown
    private var observer: NSObjectProtocol?

    var currentState: ThermalLevel {
        lock.lock()
        defer { lock.unlock() }
        return _currentState
    }

    /// Start monitoring thermal state.
    func start() {
        // Read initial state (must access thermalState before registering for notification)
        updateState(from: ProcessInfo.processInfo.thermalState)

        observer = NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.updateState(from: ProcessInfo.processInfo.thermalState)
        }
    }

    /// Stop monitoring and release resources.
    func stop() {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
        observer = nil
        lock.lock()
        _currentState = .unknown
        lock.unlock()
    }

    private func updateState(from thermalState: ProcessInfo.ThermalState) {
        let level = Self.mapThermalState(thermalState)
        lock.lock()
        _currentState = level
        lock.unlock()
    }

    static func mapThermalState(_ state: ProcessInfo.ThermalState) -> ThermalLevel {
        switch state {
        case .nominal:
            return .nominal
        case .fair:
            return .fair
        case .serious:
            return .serious
        case .critical:
            return .critical
        @unknown default:
            return .unknown
        }
    }
}
