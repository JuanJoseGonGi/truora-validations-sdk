import Foundation

/// Represents the type of a camera device for injection detection analysis.
enum CameraDeviceType: String, Codable, Equatable {
    case builtInWideAngle
    case builtInTelephoto
    case builtInUltraWide
    case external
    case continuityCamera
    case unknown
}

/// Simplified representation of a camera device for injection detection checks.
///
/// Wraps the essential properties from AVCaptureDevice needed for virtual camera detection,
/// without coupling the detection logic to AVFoundation types.
struct CameraDeviceInfo: Equatable {
    /// The type of camera device
    let deviceType: CameraDeviceType

    /// Camera position (e.g., front, back)
    let position: String

    /// Unique identifier for the device
    let uniqueID: String

    /// Current lens position, if available. A constant value of exactly 0.0 may indicate a virtual camera.
    let lensPosition: Float?
}

/// Protocol abstracting camera device discovery for injection detection.
///
/// Wraps AVCaptureDevice.DiscoverySession access behind a protocol to enable
/// unit testing with mock camera configurations.
protocol CameraInfoProviding: Sendable {
    /// Returns all discovered camera devices with their type, position, and lens information
    func discoveredDevices() -> [CameraDeviceInfo]
}
