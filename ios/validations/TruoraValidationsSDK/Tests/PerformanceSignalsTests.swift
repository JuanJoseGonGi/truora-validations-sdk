//
//  PerformanceSignalsTests.swift
//  TruoraValidationsSDKTests
//

import XCTest
@testable import TruoraValidationsSDK

/// Tests for `isAtLeast()` on all four performance signal enums:
/// `ThermalLevel`, `MemoryPressureLevel`, `NetworkQualityLevel`, `InferenceSpeedLevel`.
///
/// Verifies self-comparison, boundary values, and the `.unknown` sentinel behavior.
final class PerformanceSignalsTests: XCTestCase {
    // MARK: - ThermalLevel

    func testThermalLevel_selfComparison() {
        let nonUnknown: [ThermalLevel] = [.nominal, .fair, .serious, .critical]
        for level in nonUnknown {
            XCTAssertTrue(level.isAtLeast(level), "\(level) should be at least itself")
        }
    }

    func testThermalLevel_nominal_isNotAtLeast_fair() {
        XCTAssertFalse(ThermalLevel.nominal.isAtLeast(.fair))
    }

    func testThermalLevel_serious_isAtLeast_fair() {
        XCTAssertTrue(ThermalLevel.serious.isAtLeast(.fair))
    }

    func testThermalLevel_critical_isAtLeast_serious() {
        XCTAssertTrue(ThermalLevel.critical.isAtLeast(.serious))
    }

    func testThermalLevel_fair_isNotAtLeast_serious() {
        XCTAssertFalse(ThermalLevel.fair.isAtLeast(.serious))
    }

    func testThermalLevel_unknown_isNever_atLeast_nominal() {
        XCTAssertFalse(ThermalLevel.unknown.isAtLeast(.nominal))
    }

    func testThermalLevel_unknown_isNever_atLeast_critical() {
        XCTAssertFalse(ThermalLevel.unknown.isAtLeast(.critical))
    }

    // MARK: - MemoryPressureLevel

    func testMemoryPressure_selfComparison() {
        let nonUnknown: [MemoryPressureLevel] = [.normal, .low, .critical]
        for level in nonUnknown {
            XCTAssertTrue(level.isAtLeast(level), "\(level) should be at least itself")
        }
    }

    func testMemoryPressure_normal_isNotAtLeast_low() {
        XCTAssertFalse(MemoryPressureLevel.normal.isAtLeast(.low))
    }

    func testMemoryPressure_critical_isAtLeast_low() {
        XCTAssertTrue(MemoryPressureLevel.critical.isAtLeast(.low))
    }

    func testMemoryPressure_low_isNotAtLeast_critical() {
        XCTAssertFalse(MemoryPressureLevel.low.isAtLeast(.critical))
    }

    func testMemoryPressure_unknown_isNever_atLeast_normal() {
        XCTAssertFalse(MemoryPressureLevel.unknown.isAtLeast(.normal))
    }

    // MARK: - NetworkQualityLevel

    func testNetworkQuality_selfComparison() {
        let nonUnknown: [NetworkQualityLevel] = [.good, .constrained, .poor]
        for level in nonUnknown {
            XCTAssertTrue(level.isAtLeast(level), "\(level) should be at least itself")
        }
    }

    func testNetworkQuality_good_isNotAtLeast_constrained() {
        XCTAssertFalse(NetworkQualityLevel.good.isAtLeast(.constrained))
    }

    func testNetworkQuality_poor_isAtLeast_constrained() {
        XCTAssertTrue(NetworkQualityLevel.poor.isAtLeast(.constrained))
    }

    func testNetworkQuality_constrained_isNotAtLeast_poor() {
        XCTAssertFalse(NetworkQualityLevel.constrained.isAtLeast(.poor))
    }

    func testNetworkQuality_unknown_isNever_atLeast_good() {
        XCTAssertFalse(NetworkQualityLevel.unknown.isAtLeast(.good))
    }

    // MARK: - InferenceSpeedLevel

    func testInferenceSpeed_selfComparison() {
        let nonUnknown: [InferenceSpeedLevel] = [.fast, .slow, .tooSlow]
        for level in nonUnknown {
            XCTAssertTrue(level.isAtLeast(level), "\(level) should be at least itself")
        }
    }

    func testInferenceSpeed_fast_isNotAtLeast_slow() {
        XCTAssertFalse(InferenceSpeedLevel.fast.isAtLeast(.slow))
    }

    func testInferenceSpeed_tooSlow_isAtLeast_slow() {
        XCTAssertTrue(InferenceSpeedLevel.tooSlow.isAtLeast(.slow))
    }

    func testInferenceSpeed_slow_isNotAtLeast_tooSlow() {
        XCTAssertFalse(InferenceSpeedLevel.slow.isAtLeast(.tooSlow))
    }

    func testInferenceSpeed_unknown_isNever_atLeast_fast() {
        XCTAssertFalse(InferenceSpeedLevel.unknown.isAtLeast(.fast))
    }

    func testInferenceSpeed_unknown_isNever_atLeast_tooSlow() {
        XCTAssertFalse(InferenceSpeedLevel.unknown.isAtLeast(.tooSlow))
    }
}
