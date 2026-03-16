import Foundation

/// Encodes `RiskFactor` arrays into compact `UInt32` bitmasks for reporting.
///
/// Each known `(category, signal)` pair maps to a specific bit position.
/// Unknown signals are silently ignored. The bitmask layout is versioned
/// so the backend can decode it correctly across SDK releases.
///
/// **Bit layout (version 1):**
/// - Bits 0-7: Emulator/simulator checks
/// - Bits 8-11: Camera checks
/// - Bits 12-19: Runtime/jailbreak checks
/// - Bits 20-24: iOS-specific cross-platform alignment bits
enum BitmaskEncoder {
    /// Current bitmask layout version. Increment when bit assignments change.
    static let version = 1

    // MARK: - Bit Assignments

    // Simulator signals (bits 0-7)
    private static let bitSimulatorRuntime: UInt32 = 0
    private static let bitSimulatorEnvVar: UInt32 = 1
    private static let bitSimulatorDeviceModel: UInt32 = 2

    // Camera signals (bits 8-11)
    private static let bitExternalCamera: UInt32 = 8
    private static let bitContinuityCamera: UInt32 = 9
    private static let bitLensStuck: UInt32 = 10
    private static let bitNoCameraDevices: UInt32 = 11

    // Jailbreak signals (bits 12-19)
    private static let bitJailbreakFile: UInt32 = 12
    private static let bitSandboxCompromised: UInt32 = 13
    private static let bitSuspiciousDylib: UInt32 = 14

    // iOS-specific alignment (bits 20-24)
    private static let bitIOSSimulator: UInt32 = 20
    private static let bitIOSJailbreakFiles: UInt32 = 21
    private static let bitIOSSandboxWrite: UInt32 = 22
    private static let bitIOSDyldInjection: UInt32 = 23
    private static let bitIOSContinuityCamera: UInt32 = 24

    /// Encodes an array of risk factors into a compact bitmask.
    ///
    /// Each risk factor is matched by its `category` and a prefix/keyword in `signal`.
    /// Unknown combinations are silently ignored (no crash, no bit set).
    ///
    /// - Parameter riskFactors: Risk factors from injection detection checkers
    /// - Returns: Bitmask with bits set for each detected signal
    static func encode(_ riskFactors: [RiskFactor]) -> UInt32 {
        var bitmask: UInt32 = 0

        for factor in riskFactors {
            let bits = bitPositions(for: factor)
            for bit in bits {
                bitmask |= (1 << bit)
            }
        }

        return bitmask
    }

    // MARK: - Private

    private static func bitPositions(for factor: RiskFactor) -> [UInt32] {
        switch factor.category {
        case "simulator":
            simulatorBits(signal: factor.signal)
        case "virtual_camera":
            cameraBits(signal: factor.signal)
        case "jailbreak":
            jailbreakBits(signal: factor.signal)
        default:
            []
        }
    }

    private static func simulatorBits(signal: String) -> [UInt32] {
        if signal.hasPrefix("Runtime simulator") {
            return [bitSimulatorRuntime, bitIOSSimulator]
        }
        if signal.hasPrefix("SIMULATOR_DEVICE_NAME") {
            return [bitSimulatorEnvVar, bitIOSSimulator]
        }
        if signal.hasPrefix("Device model contains Simulator") {
            return [bitSimulatorDeviceModel, bitIOSSimulator]
        }
        return []
    }

    private static func cameraBits(signal: String) -> [UInt32] {
        if signal.hasPrefix("External camera") || signal.hasPrefix("Unknown camera type") {
            return [bitExternalCamera]
        }
        if signal.hasPrefix("Continuity camera") {
            return [bitContinuityCamera, bitIOSContinuityCamera]
        }
        if signal.hasPrefix("Lens position stuck") {
            return [bitLensStuck]
        }
        if signal.hasPrefix("No camera devices") {
            return [bitNoCameraDevices]
        }
        return []
    }

    private static func jailbreakBits(signal: String) -> [UInt32] {
        if signal.hasPrefix("File found:") {
            return [bitJailbreakFile, bitIOSJailbreakFiles]
        }
        if signal.hasPrefix("Sandbox compromised") {
            return [bitSandboxCompromised, bitIOSSandboxWrite]
        }
        if signal.hasPrefix("Suspicious dylib") {
            return [bitSuspiciousDylib, bitIOSDyldInjection]
        }
        return []
    }
}
