import Foundation
import XCTest
@testable import TruoraValidationsSDK

final class CameraCheckerTests: XCTestCase {
    // MARK: - External Camera Detection

    func testExternalCamera_producesRiskFactor() {
        let devices = [
            CameraDeviceInfo(deviceType: .external, position: "unspecified", uniqueID: "ext-1", lensPosition: nil)
        ]
        let mock = MockCameraInfoProvider(devices: devices)
        let checker = CameraChecker(cameraInfo: mock)

        let factors = checker.check()

        let externalFactor = factors.first { $0.penalty == 30 }
        XCTAssertNotNil(externalFactor)
        XCTAssertEqual(externalFactor?.category, "virtual_camera")
    }

    func testContinuityCamera_producesRiskFactor() {
        let devices = [
            CameraDeviceInfo(deviceType: .continuityCamera, position: "unspecified", uniqueID: "cont-1", lensPosition: nil)
        ]
        let mock = MockCameraInfoProvider(devices: devices)
        let checker = CameraChecker(cameraInfo: mock)

        let factors = checker.check()

        let contFactor = factors.first { $0.penalty == 25 }
        XCTAssertNotNil(contFactor)
        XCTAssertEqual(contFactor?.category, "virtual_camera")
    }

    // MARK: - Built-in Cameras

    func testOnlyBuiltInCameras_producesNoRiskFactors() {
        let devices = [
            CameraDeviceInfo(deviceType: .builtInWideAngle, position: "back", uniqueID: "builtin-1", lensPosition: 0.5),
            CameraDeviceInfo(deviceType: .builtInTelephoto, position: "back", uniqueID: "builtin-2", lensPosition: 0.7)
        ]
        let mock = MockCameraInfoProvider(devices: devices)
        let checker = CameraChecker(cameraInfo: mock)

        let factors = checker.check()

        XCTAssertTrue(factors.isEmpty)
    }

    // MARK: - Lens Position Analysis

    func testLensPositionExactlyZero_producesRiskFactor() {
        let devices = [
            CameraDeviceInfo(deviceType: .builtInWideAngle, position: "back", uniqueID: "builtin-1", lensPosition: 0.0)
        ]
        let mock = MockCameraInfoProvider(devices: devices)
        let checker = CameraChecker(cameraInfo: mock)

        let factors = checker.check()

        let lensFactor = factors.first { $0.penalty == 15 }
        XCTAssertNotNil(lensFactor)
    }

    // MARK: - No Discovery Session

    func testNoDevicesAvailable_producesRiskFactor() {
        let mock = MockCameraInfoProvider(devices: [])
        let checker = CameraChecker(cameraInfo: mock)

        let factors = checker.check()

        let noDeviceFactor = factors.first { $0.penalty == 20 }
        XCTAssertNotNil(noDeviceFactor)
    }

    // MARK: - Multiple Camera Accumulation

    func testMultipleNonBuiltInCameras_accumulatesFactors() {
        let devices = [
            CameraDeviceInfo(deviceType: .external, position: "unspecified", uniqueID: "ext-1", lensPosition: nil),
            CameraDeviceInfo(deviceType: .continuityCamera, position: "unspecified", uniqueID: "cont-1", lensPosition: nil),
            CameraDeviceInfo(deviceType: .builtInWideAngle, position: "back", uniqueID: "builtin-1", lensPosition: 0.5)
        ]
        let mock = MockCameraInfoProvider(devices: devices)
        let checker = CameraChecker(cameraInfo: mock)

        let factors = checker.check()

        XCTAssertEqual(factors.count, 2)
        XCTAssertTrue(factors.contains { $0.penalty == 30 })
        XCTAssertTrue(factors.contains { $0.penalty == 25 })
    }
}
