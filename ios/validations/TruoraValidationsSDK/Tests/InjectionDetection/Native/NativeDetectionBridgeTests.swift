import Foundation
import XCTest
@testable import TruoraValidationsSDK

final class NativeDetectionBridgeTests: XCTestCase {
    // MARK: - Availability

    func testIsAvailable_returnsFalseWithoutXCFramework() {
        XCTAssertFalse(NativeDetectionBridge.isAvailable)
    }

    // MARK: - runChecks

    func testRunChecks_returnsNilWhenUnavailable() {
        let result = NativeDetectionBridge.runChecks(mask: 0)
        XCTAssertNil(result)
    }

    // MARK: - signReport

    func testSignReport_returnsNilWhenUnavailable() {
        let result = NativeDetectionBridge.signReport(
            validationId: "test-id",
            flowType: "face",
            trustScore: 80,
            riskBitmask: 0x01,
            timestamp: 1_234_567_890
        )
        XCTAssertNil(result)
    }

    // MARK: - getBitmaskVersion

    func testGetBitmaskVersion_returnsFallbackVersion() {
        let version = NativeDetectionBridge.getBitmaskVersion()
        XCTAssertEqual(version, BitmaskEncoder.version)
    }

    // MARK: - getEscalationThreshold

    func testGetEscalationThreshold_returnsFallbackOf50() {
        let threshold = NativeDetectionBridge.getEscalationThreshold()
        XCTAssertEqual(threshold, 50)
    }
}
