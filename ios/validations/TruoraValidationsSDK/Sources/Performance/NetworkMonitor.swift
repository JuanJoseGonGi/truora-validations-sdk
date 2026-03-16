//
//  NetworkMonitor.swift
//  TruoraValidationsSDK
//

import Foundation
import Network

/// Monitors network quality using NWPathMonitor (iOS 12+).
///
/// Thread-safe via an internal lock.
final class NetworkMonitor: NetworkMonitoring, @unchecked Sendable {
    private let lock = NSLock()
    private var _currentQuality: NetworkQualityLevel = .unknown
    private var pathMonitor: NWPathMonitor?
    private let monitorQueue = DispatchQueue(label: "com.truora.performance.network")

    var currentQuality: NetworkQualityLevel {
        lock.lock()
        defer { lock.unlock() }
        return _currentQuality
    }

    /// Start monitoring network quality.
    func start() {
        let monitor = NWPathMonitor()
        pathMonitor = monitor

        monitor.pathUpdateHandler = { [weak self] path in
            let quality = Self.classifyPath(path)
            self?.lock.lock()
            self?._currentQuality = quality
            self?.lock.unlock()
        }
        monitor.start(queue: monitorQueue)
    }

    /// Stop monitoring and release resources.
    func stop() {
        pathMonitor?.cancel()
        pathMonitor = nil
        lock.lock()
        _currentQuality = .unknown
        lock.unlock()
    }

    static func classifyPath(_ path: NWPath) -> NetworkQualityLevel {
        guard path.status == .satisfied else {
            return .poor
        }

        // isConstrained = Low Data Mode enabled by user (iOS 13+)
        if path.isConstrained {
            return .poor
        }

        // isExpensive = cellular or personal hotspot
        if path.isExpensive {
            return .constrained
        }

        return .good
    }
}
