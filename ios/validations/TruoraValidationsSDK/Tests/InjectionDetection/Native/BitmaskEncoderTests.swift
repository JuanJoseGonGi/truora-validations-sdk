import Foundation
import XCTest
@testable import TruoraValidationsSDK

final class BitmaskEncoderTests: XCTestCase {
    // MARK: - Version

    func testVersion_isOne() {
        XCTAssertEqual(BitmaskEncoder.version, 1)
    }

    // MARK: - Empty Input

    func testEncode_emptyArray_returnsZero() {
        let bitmask = BitmaskEncoder.encode([])
        XCTAssertEqual(bitmask, 0)
    }

    // MARK: - Simulator Signals (Bits 0-7)

    func testEncode_simulatorRuntime_setsBit0() {
        let factors = [
            RiskFactor(
                category: "simulator",
                signal: "Runtime simulator environment detected",
                penalty: 50,
                confidence: "high"
            )
        ]
        let bitmask = BitmaskEncoder.encode(factors)
        XCTAssertNotEqual(bitmask & (1 << 0), 0, "Bit 0 should be set for simulator runtime")
    }

    func testEncode_simulatorEnvVar_setsBit1() {
        let factors = [
            RiskFactor(
                category: "simulator",
                signal: "SIMULATOR_DEVICE_NAME environment variable present",
                penalty: 30,
                confidence: "medium"
            )
        ]
        let bitmask = BitmaskEncoder.encode(factors)
        XCTAssertNotEqual(bitmask & (1 << 1), 0, "Bit 1 should be set for simulator env var")
    }

    func testEncode_simulatorDeviceModel_setsBit2() {
        let factors = [
            RiskFactor(
                category: "simulator",
                signal: "Device model contains Simulator: iPhone Simulator",
                penalty: 10,
                confidence: "low"
            )
        ]
        let bitmask = BitmaskEncoder.encode(factors)
        XCTAssertNotEqual(bitmask & (1 << 2), 0, "Bit 2 should be set for simulator device model")
    }

    // MARK: - Camera Signals (Bits 8-11)

    func testEncode_externalCamera_setsBit8() {
        let factors = [
            RiskFactor(
                category: "virtual_camera",
                signal: "External camera detected: ext-1",
                penalty: 30,
                confidence: "high"
            )
        ]
        let bitmask = BitmaskEncoder.encode(factors)
        XCTAssertNotEqual(bitmask & (1 << 8), 0, "Bit 8 should be set for external camera")
    }

    func testEncode_continuityCamera_setsBit9() {
        let factors = [
            RiskFactor(
                category: "virtual_camera",
                signal: "Continuity camera detected: cc-1",
                penalty: 25,
                confidence: "high"
            )
        ]
        let bitmask = BitmaskEncoder.encode(factors)
        XCTAssertNotEqual(bitmask & (1 << 9), 0, "Bit 9 should be set for continuity camera")
    }

    func testEncode_lensStuck_setsBit10() {
        let factors = [
            RiskFactor(
                category: "virtual_camera",
                signal: "Lens position stuck at 0.0 for device: cam-1",
                penalty: 15,
                confidence: "medium"
            )
        ]
        let bitmask = BitmaskEncoder.encode(factors)
        XCTAssertNotEqual(bitmask & (1 << 10), 0, "Bit 10 should be set for stuck lens")
    }

    func testEncode_noCameraDevices_setsBit11() {
        let factors = [
            RiskFactor(
                category: "virtual_camera",
                signal: "No camera devices discovered",
                penalty: 20,
                confidence: "medium"
            )
        ]
        let bitmask = BitmaskEncoder.encode(factors)
        XCTAssertNotEqual(bitmask & (1 << 11), 0, "Bit 11 should be set for no cameras")
    }

    // MARK: - Jailbreak Signals (Bits 12-19)

    func testEncode_jailbreakFile_setsBit12() {
        let factors = [
            RiskFactor(
                category: "jailbreak",
                signal: "File found: /Applications/Cydia.app",
                penalty: 20,
                confidence: "high"
            )
        ]
        let bitmask = BitmaskEncoder.encode(factors)
        XCTAssertNotEqual(bitmask & (1 << 12), 0, "Bit 12 should be set for jailbreak file")
    }

    func testEncode_sandboxCompromised_setsBit13() {
        let factors = [
            RiskFactor(
                category: "jailbreak",
                signal: "Sandbox compromised: write outside sandbox succeeded",
                penalty: 50,
                confidence: "high"
            )
        ]
        let bitmask = BitmaskEncoder.encode(factors)
        XCTAssertNotEqual(bitmask & (1 << 13), 0, "Bit 13 should be set for sandbox write")
    }

    func testEncode_suspiciousDylib_setsBit14() {
        let factors = [
            RiskFactor(
                category: "jailbreak",
                signal: "Suspicious dylib: MobileSubstrate",
                penalty: 40,
                confidence: "high"
            )
        ]
        let bitmask = BitmaskEncoder.encode(factors)
        XCTAssertNotEqual(bitmask & (1 << 14), 0, "Bit 14 should be set for suspicious dylib")
    }

    // MARK: - iOS-Specific Bits (20-24)

    func testEncode_iOSSpecificBits_simulatorBit0And20() {
        // The iOS-specific simulator bit 20 maps to the same simulator signals
        // but at a higher bit position for cross-platform bitmask alignment.
        // Both the primary bit (0) and the iOS alias (20) must be set together.
        let factors = [
            RiskFactor(
                category: "simulator",
                signal: "Runtime simulator environment detected",
                penalty: 50,
                confidence: "high"
            )
        ]
        let bitmask = BitmaskEncoder.encode(factors)
        XCTAssertNotEqual(bitmask & (1 << 0), 0, "Bit 0 (primary simulator) should be set")
        XCTAssertNotEqual(bitmask & (1 << 20), 0, "Bit 20 (iOS-specific simulator) should be set")
    }

    // MARK: - Unknown Signals

    func testEncode_unknownSignal_ignoredNoCrash() {
        let factors = [
            RiskFactor(
                category: "unknown_category",
                signal: "Some unknown signal",
                penalty: 10,
                confidence: "low"
            )
        ]
        let bitmask = BitmaskEncoder.encode(factors)
        XCTAssertEqual(bitmask, 0, "Unknown signals should be ignored")
    }

    // MARK: - Multiple Signals

    func testEncode_multipleSignals_combinesBits() {
        let factors = [
            RiskFactor(
                category: "simulator",
                signal: "Runtime simulator environment detected",
                penalty: 50,
                confidence: "high"
            ),
            RiskFactor(
                category: "virtual_camera",
                signal: "External camera detected: ext-1",
                penalty: 30,
                confidence: "high"
            ),
            RiskFactor(
                category: "jailbreak",
                signal: "File found: /Applications/Cydia.app",
                penalty: 20,
                confidence: "high"
            )
        ]
        let bitmask = BitmaskEncoder.encode(factors)
        XCTAssertNotEqual(bitmask & (1 << 0), 0, "Simulator bit should be set")
        XCTAssertNotEqual(bitmask & (1 << 8), 0, "External camera bit should be set")
        XCTAssertNotEqual(bitmask & (1 << 12), 0, "Jailbreak file bit should be set")
    }

    func testEncode_unknownCameraType_setsBit8() {
        // Bit 8 is intentionally shared between external and
        // unknown camera types. Both represent non-built-in
        // capture devices that indicate potential injection,
        // so they map to the same risk bit.
        let factors = [
            RiskFactor(
                category: "virtual_camera",
                signal: "Unknown camera type detected: unk-1",
                penalty: 15,
                confidence: "low"
            )
        ]
        let bitmask = BitmaskEncoder.encode(factors)
        XCTAssertNotEqual(bitmask & (1 << 8), 0, "Bit 8 should be set for unknown camera type")
    }
}
