import Foundation
import XCTest
@testable import TruoraValidationsSDK

final class EnvironmentCheckerTests: XCTestCase {
    // MARK: - Simulator Detection

    func testSimulatorDetected_producesHighConfidenceRiskFactor() {
        let mock = MockSystemInfoProvider(isSimulator: true)
        let checker = EnvironmentChecker(systemInfo: mock)

        let factors = checker.check()

        let simulatorFactor = factors.first { $0.category == "simulator" && $0.penalty == 50 }
        XCTAssertNotNil(simulatorFactor)
        XCTAssertEqual(simulatorFactor?.confidence, "high")
        XCTAssertTrue(simulatorFactor?.signal.contains("simulator") == true)
    }

    func testDeviceModelContainsSimulator_producesRiskFactor() {
        let mock = MockSystemInfoProvider(deviceModel: "iPhone Simulator")
        let checker = EnvironmentChecker(systemInfo: mock)

        let factors = checker.check()

        let modelFactor = factors.first { $0.penalty == 10 }
        XCTAssertNotNil(modelFactor)
        XCTAssertEqual(modelFactor?.category, "simulator")
    }

    func testSimulatorDeviceNamePresent_producesRiskFactor() {
        let mock = MockSystemInfoProvider(simulatorDeviceName: "iPhone 15 Pro")
        let checker = EnvironmentChecker(systemInfo: mock)

        let factors = checker.check()

        let envFactor = factors.first { $0.penalty == 30 }
        XCTAssertNotNil(envFactor)
        XCTAssertEqual(envFactor?.category, "simulator")
    }

    func testCleanDevice_producesNoRiskFactors() {
        let mock = MockSystemInfoProvider(
            isSimulator: false,
            deviceModel: "iPhone",
            simulatorDeviceName: nil
        )
        let checker = EnvironmentChecker(systemInfo: mock)

        let factors = checker.check()

        XCTAssertTrue(factors.isEmpty)
    }

    func testMultipleSimulatorSignals_producesMultipleFactors() {
        let mock = MockSystemInfoProvider(
            isSimulator: true,
            deviceModel: "iPhone Simulator",
            simulatorDeviceName: "iPhone 15"
        )
        let checker = EnvironmentChecker(systemInfo: mock)

        let factors = checker.check()

        XCTAssertEqual(factors.count, 3)
        XCTAssertEqual(factors.filter { $0.category == "simulator" }.count, 3)
    }
}
