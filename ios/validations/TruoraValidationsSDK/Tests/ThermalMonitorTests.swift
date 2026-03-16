//
//  ThermalMonitorTests.swift
//  TruoraValidationsSDKTests
//

import XCTest
@testable import TruoraValidationsSDK

/// Tests for `ThermalMonitor.mapThermalState(_:)` — the static method that
/// converts Foundation's `ProcessInfo.ThermalState` to SDK-internal `ThermalLevel`.
///
/// The mapping is 1:1 for known states; `@unknown default` maps to `.unknown`.
final class ThermalMonitorTests: XCTestCase {
    func testMapThermalState_nominal() {
        XCTAssertEqual(
            ThermalMonitor.mapThermalState(.nominal),
            .nominal
        )
    }

    func testMapThermalState_fair() {
        XCTAssertEqual(
            ThermalMonitor.mapThermalState(.fair),
            .fair
        )
    }

    func testMapThermalState_serious() {
        XCTAssertEqual(
            ThermalMonitor.mapThermalState(.serious),
            .serious
        )
    }

    func testMapThermalState_critical() {
        XCTAssertEqual(
            ThermalMonitor.mapThermalState(.critical),
            .critical
        )
    }
}
