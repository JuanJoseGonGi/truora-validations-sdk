import Foundation
@testable import TruoraValidationsSDK

/// Configurable mock for `CameraInfoProviding` used in injection detection tests.
///
/// Returns a preconfigured list of camera devices for deterministic test scenarios.
final class MockCameraInfoProvider: CameraInfoProviding, @unchecked Sendable {
    private let devices: [CameraDeviceInfo]

    init(devices: [CameraDeviceInfo] = []) {
        self.devices = devices
    }

    func discoveredDevices() -> [CameraDeviceInfo] {
        devices
    }
}
