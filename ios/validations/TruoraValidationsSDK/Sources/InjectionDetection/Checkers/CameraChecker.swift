import Foundation

/// Checks for virtual and external camera indicators (Layer 2).
///
/// Detects external cameras, continuity cameras, and suspicious lens positions
/// that may indicate a virtual camera feed.
struct CameraChecker {
    private let cameraInfo: CameraInfoProviding

    init(cameraInfo: CameraInfoProviding) {
        self.cameraInfo = cameraInfo
    }

    /// Runs all camera checks and returns detected risk factors.
    func check() -> [RiskFactor] {
        let devices = cameraInfo.discoveredDevices()

        guard !devices.isEmpty else {
            return [RiskFactor(
                category: "virtual_camera",
                signal: "No camera devices discovered",
                penalty: 20,
                confidence: "medium"
            )]
        }

        var factors: [RiskFactor] = []

        for device in devices {
            switch device.deviceType {
            case .external:
                factors.append(RiskFactor(
                    category: "virtual_camera",
                    signal: "External camera detected: \(device.uniqueID)",
                    penalty: 30,
                    confidence: "high"
                ))

            case .continuityCamera:
                factors.append(RiskFactor(
                    category: "virtual_camera",
                    signal: "Continuity camera detected: \(device.uniqueID)",
                    penalty: 25,
                    confidence: "high"
                ))

            case .builtInWideAngle, .builtInTelephoto, .builtInUltraWide:
                if let lensPosition = device.lensPosition, lensPosition == 0.0 {
                    factors.append(RiskFactor(
                        category: "virtual_camera",
                        signal: "Lens position stuck at 0.0 for device: \(device.uniqueID)",
                        penalty: 15,
                        confidence: "medium"
                    ))
                }

            case .unknown:
                factors.append(RiskFactor(
                    category: "virtual_camera",
                    signal: "Unknown camera type detected: \(device.uniqueID)",
                    penalty: 15,
                    confidence: "low"
                ))
            }
        }

        return factors
    }
}
