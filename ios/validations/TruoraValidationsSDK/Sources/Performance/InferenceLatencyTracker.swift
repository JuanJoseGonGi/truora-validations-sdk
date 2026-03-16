//
//  InferenceLatencyTracker.swift
//  TruoraValidationsSDK
//

import Foundation

/// Tracks ML inference latency using a rolling average and classifies speed
/// relative to a fixed frame budget of 0.1666s (30fps, skip=5).
///
/// Thread-safe via an internal lock.
final class InferenceLatencyTracker: @unchecked Sendable {
    private static let windowSize = 10
    private static let minSamples = 3
    private static let slowThresholdRatio: Double = 0.50
    private static let tooSlowThresholdRatio: Double = 0.90

    /// Fixed frame budget: (1.0 / 30fps) * 5 skip = 0.1666s.
    private static let frameBudget: TimeInterval = (1.0 / 30.0) * 5.0

    private let lock = NSLock()
    private var latencies: [TimeInterval] = Array(repeating: 0, count: windowSize)
    private var writeIndex: Int = 0
    private var sampleCount: Int = 0

    /// Record a single inference duration.
    ///
    /// - Parameter latency: Duration in seconds (e.g., from CACurrentMediaTime difference)
    func record(latency: TimeInterval) {
        lock.lock()
        defer { lock.unlock() }
        latencies[writeIndex] = latency
        writeIndex = (writeIndex + 1) % Self.windowSize
        if sampleCount < Self.windowSize {
            sampleCount += 1
        }
    }

    /// Get the current inference speed classification.
    var speed: InferenceSpeedLevel {
        lock.lock()
        defer { lock.unlock() }

        guard sampleCount >= Self.minSamples else { return .unknown }

        let avg = computeAverage()
        let ratio = avg / Self.frameBudget

        if ratio >= Self.tooSlowThresholdRatio {
            return .tooSlow
        }
        if ratio >= Self.slowThresholdRatio {
            return .slow
        }
        return .fast
    }

    /// Get the rolling average inference time in seconds.
    /// Returns 0 if no samples have been recorded.
    var averageSeconds: TimeInterval {
        lock.lock()
        defer { lock.unlock() }
        guard sampleCount > 0 else { return 0 }
        return computeAverage()
    }

    /// Reset all recorded samples.
    func reset() {
        lock.lock()
        defer { lock.unlock() }
        sampleCount = 0
        writeIndex = 0
    }

    // MARK: - Private (caller must hold lock)

    private func computeAverage() -> TimeInterval {
        let count = min(sampleCount, Self.windowSize)
        guard count > 0 else { return 0 }
        let sum = latencies.prefix(count).reduce(0, +)
        return sum / Double(count)
    }
}
