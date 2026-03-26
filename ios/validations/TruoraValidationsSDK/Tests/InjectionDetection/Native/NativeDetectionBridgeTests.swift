import XCTest
@testable import TruoraValidationsSDK

final class NativeDetectionBridgeTests: XCTestCase {
    func testCreateReturnsNilWhenNativeLibraryUnavailable() {
        // In CI/test environment, the real XCFramework binary is never linked.
        // td_bitmask_version() returns 0 (stub), so create() returns nil.
        let bridge = NativeDetectionBridge.create()
        XCTAssertNil(bridge, "Should return nil when TruoraDetection binary is not linked")
    }

    func testCreateReturnsNilOnRepeatedCalls() {
        let first = NativeDetectionBridge.create()
        let second = NativeDetectionBridge.create()
        XCTAssertNil(first, "First call should return nil")
        XCTAssertNil(second, "Second call should also return nil")
    }

    func testNativeDetectionBridgeConformsToDetectionBridging() {
        // Compile-time check: if this compiles, NativeDetectionBridge conforms.
        // At runtime, create() returns nil (no binary), but the type relationship holds.
        let _: (any DetectionBridging)? = NativeDetectionBridge.create()
    }

    func testExpectedNativeVersionMatchesVersion() {
        XCTAssertEqual(BitmaskEncoder.expectedNativeVersion, UInt32(BitmaskEncoder.version))
    }
}
