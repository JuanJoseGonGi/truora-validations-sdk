//
//  InferenceLatencyTrackerTests.swift
//  TruoraValidationsSDKTests
//

import XCTest
@testable import TruoraValidationsSDK

/// Tests for `InferenceLatencyTracker` — a rolling-window tracker that
/// classifies ML inference speed relative to a dynamic frame budget.
///
/// Default frame budget: (1/30) * 5 = 0.1666s.
/// Slow threshold: 50% of budget = 0.0833s.
/// TooSlow threshold: 90% of budget = 0.15s.
final class InferenceLatencyTrackerTests: XCTestCase {
    private var tracker: InferenceLatencyTracker!

    override func setUp() {
        super.setUp()
        tracker = InferenceLatencyTracker()
    }

    override func tearDown() {
        tracker = nil
        super.tearDown()
    }

    // MARK: - Speed — insufficient samples

    func testSpeed_noSamples_returnsUnknown() {
        XCTAssertEqual(tracker.speed, .unknown)
    }

    func testSpeed_oneSample_returnsUnknown() {
        tracker.record(latency: 0.05)
        XCTAssertEqual(tracker.speed, .unknown)
    }

    func testSpeed_twoSamples_returnsUnknown() {
        tracker.record(latency: 0.05)
        tracker.record(latency: 0.05)
        XCTAssertEqual(tracker.speed, .unknown)
    }

    // MARK: - Speed — FAST classification

    func testSpeed_fastInference_returnsFast() {
        // 0.04s avg → 0.04/0.1666 = 0.24 → FAST
        for _ in 0 ..< 3 {
            tracker.record(latency: 0.04)
        }
        XCTAssertEqual(tracker.speed, .fast)
    }

    func testSpeed_justBelowSlowThreshold_returnsFast() {
        // 0.082s avg → 0.082/0.1666 = 0.492 → just below 0.50 → FAST
        for _ in 0 ..< 3 {
            tracker.record(latency: 0.082)
        }
        XCTAssertEqual(tracker.speed, .fast)
    }

    // MARK: - Speed — SLOW classification

    func testSpeed_slowInference_returnsSlow() {
        // 0.10s avg → 0.10/0.1666 = 0.60 → SLOW
        for _ in 0 ..< 3 {
            tracker.record(latency: 0.10)
        }
        XCTAssertEqual(tracker.speed, .slow)
    }

    func testSpeed_atSlowThreshold_returnsSlow() {
        // 0.084s avg → 0.084/0.1666 = 0.504 → at/above 0.50 → SLOW
        for _ in 0 ..< 3 {
            tracker.record(latency: 0.084)
        }
        XCTAssertEqual(tracker.speed, .slow)
    }

    // MARK: - Speed — TOO_SLOW classification

    func testSpeed_tooSlowInference_returnsTooSlow() {
        // 0.16s avg → 0.16/0.1666 = 0.96 → TOO_SLOW
        for _ in 0 ..< 3 {
            tracker.record(latency: 0.16)
        }
        XCTAssertEqual(tracker.speed, .tooSlow)
    }

    func testSpeed_atTooSlowThreshold_returnsTooSlow() {
        // 0.15s avg → 0.15/0.1666 = 0.90 → exactly at threshold → TOO_SLOW
        for _ in 0 ..< 3 {
            tracker.record(latency: 0.15)
        }
        XCTAssertEqual(tracker.speed, .tooSlow)
    }

    // MARK: - Rolling window

    func testSpeed_rollingWindow_evictsOldSamples() {
        // Fill window (size=10) with fast samples
        for _ in 0 ..< 10 {
            tracker.record(latency: 0.04)
        }
        XCTAssertEqual(tracker.speed, .fast)

        // Overwrite all 10 with too-slow samples
        for _ in 0 ..< 10 {
            tracker.record(latency: 0.16)
        }
        XCTAssertEqual(tracker.speed, .tooSlow)
    }

    func testSpeed_partialWindowOverwrite_blendsOldAndNew() {
        // Fill with 10 fast samples (0.04s)
        for _ in 0 ..< 10 {
            tracker.record(latency: 0.04)
        }
        // Overwrite 5 with 0.20s
        // New average = (5*0.04 + 5*0.20) / 10 = 1.20/10 = 0.12s
        // 0.12/0.1666 = 0.72 → SLOW
        for _ in 0 ..< 5 {
            tracker.record(latency: 0.20)
        }
        XCTAssertEqual(tracker.speed, .slow)
    }

    // MARK: - Reset

    func testReset_clearsAllSamples() {
        for _ in 0 ..< 5 {
            tracker.record(latency: 0.10)
        }
        XCTAssertEqual(tracker.speed, .slow)

        tracker.reset()
        XCTAssertEqual(tracker.speed, .unknown)
    }

    func testReset_allowsNewSamplesToAccumulate() {
        for _ in 0 ..< 5 {
            tracker.record(latency: 0.16)
        }
        tracker.reset()

        for _ in 0 ..< 3 {
            tracker.record(latency: 0.04)
        }
        XCTAssertEqual(tracker.speed, .fast)
    }

    // MARK: - averageSeconds

    func testAverageSeconds_noSamples_returnsZero() {
        XCTAssertEqual(tracker.averageSeconds, 0)
    }

    func testAverageSeconds_withSamples_returnsCorrectAverage() {
        tracker.record(latency: 0.10)
        tracker.record(latency: 0.20)
        tracker.record(latency: 0.30)
        // Average = (0.10 + 0.20 + 0.30) / 3 = 0.20
        XCTAssertEqual(tracker.averageSeconds, 0.20, accuracy: 0.001)
    }

    func testAverageSeconds_afterReset_returnsZero() {
        tracker.record(latency: 0.10)
        tracker.record(latency: 0.20)
        tracker.reset()
        XCTAssertEqual(tracker.averageSeconds, 0)
    }
}
