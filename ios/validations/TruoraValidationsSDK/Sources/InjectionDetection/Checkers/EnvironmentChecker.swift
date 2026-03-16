import Foundation

/// Checks for simulator and emulated environment indicators (Layer 1).
///
/// Detects simulator environments via ProcessInfo environment variables,
/// UIDevice model checks, and compile-time target environment flags.
struct EnvironmentChecker {
    private let systemInfo: SystemInfoProviding

    init(systemInfo: SystemInfoProviding) {
        self.systemInfo = systemInfo
    }

    /// Runs all environment checks and returns detected risk factors.
    func check() -> [RiskFactor] {
        var factors: [RiskFactor] = []

        if systemInfo.isSimulator {
            factors.append(RiskFactor(
                category: "simulator",
                signal: "Runtime simulator environment detected",
                penalty: 50,
                confidence: "high"
            ))
        }

        if systemInfo.simulatorDeviceName != nil {
            factors.append(RiskFactor(
                category: "simulator",
                signal: "SIMULATOR_DEVICE_NAME environment variable present",
                penalty: 30,
                confidence: "medium"
            ))
        }

        if systemInfo.deviceModel.contains("Simulator") {
            factors.append(RiskFactor(
                category: "simulator",
                signal: "Device model contains Simulator: \(systemInfo.deviceModel)",
                penalty: 10,
                confidence: "low"
            ))
        }

        return factors
    }
}
