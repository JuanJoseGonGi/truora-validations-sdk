//
//  PerformanceAdvisorTests.swift
//  TruoraValidationsSDKTests
//

import XCTest
@testable import TruoraValidationsSDK

// MARK: - Mock Monitors

private final class MockThermalMonitor: ThermalMonitoring, @unchecked Sendable {
    var currentState: ThermalLevel = .nominal
}

private final class MockMemoryMonitor: MemoryMonitoring, @unchecked Sendable {
    var currentPressure: MemoryPressureLevel = .normal
}

private final class MockNetworkMonitor: NetworkMonitoring, @unchecked Sendable {
    var currentQuality: NetworkQualityLevel = .good
}

private final class MockBatteryMonitor: BatteryMonitoring, @unchecked Sendable {
    var isLowPowerMode: Bool = false
}

private struct MockProcessorInfo: ProcessorInfoProviding {
    var activeProcessorCount: Int = 6
}

// MARK: - Tests

/// Tests for `PerformanceAdvisor` — the central rules engine that maps device
/// signals to recommended parameter values.
///
/// Uses hand-written mock monitors (protocol-based) and a controllable clock
/// for hysteresis testing. No real system monitors are started.
final class PerformanceAdvisorTests: XCTestCase {
    private var thermal: MockThermalMonitor!
    private var memory: MockMemoryMonitor!
    private var network: MockNetworkMonitor!
    private var battery: MockBatteryMonitor!
    private var processorInfo: MockProcessorInfo!
    private var inferenceTracker: InferenceLatencyTracker!
    private var fakeNow: Date!
    private var advisor: PerformanceAdvisor!

    override func setUp() {
        super.setUp()
        thermal = MockThermalMonitor()
        memory = MockMemoryMonitor()
        network = MockNetworkMonitor()
        battery = MockBatteryMonitor()
        processorInfo = MockProcessorInfo()
        inferenceTracker = InferenceLatencyTracker()
        fakeNow = Date()

        advisor = PerformanceAdvisor(
            thermal: thermal,
            memory: memory,
            network: network,
            battery: battery,
            inferenceTracker: inferenceTracker,
            processorInfo: processorInfo,
            clock: { [unowned self] in self.fakeNow }
        )
    }

    override func tearDown() {
        advisor = nil
        inferenceTracker = nil
        super.tearDown()
    }

    // MARK: - Video Resolution

    func testVideoResolution_nominal_returns720p() {
        XCTAssertEqual(advisor.recommendedVideoResolution, .hd720p)
    }

    func testVideoResolution_thermalSerious_returns540p() {
        thermal.currentState = .serious
        XCTAssertEqual(advisor.recommendedVideoResolution, .sd540p)
    }

    func testVideoResolution_thermalCritical_returns540p() {
        thermal.currentState = .critical
        XCTAssertEqual(advisor.recommendedVideoResolution, .sd540p)
    }

    func testVideoResolution_memoryCritical_returns540p() {
        memory.currentPressure = .critical
        XCTAssertEqual(advisor.recommendedVideoResolution, .sd540p)
    }

    func testVideoResolution_thermalFairOnly_returns720p() {
        thermal.currentState = .fair
        XCTAssertEqual(advisor.recommendedVideoResolution, .hd720p)
    }

    func testVideoResolution_memoryLowOnly_returns720p() {
        memory.currentPressure = .low
        XCTAssertEqual(advisor.recommendedVideoResolution, .hd720p)
    }

    // MARK: - Autocapture

    func testAutocapture_nominal_returnsTrue() {
        XCTAssertTrue(advisor.shouldUseAutocapture)
    }

    func testAutocapture_thermalCritical_returnsFalse() {
        thermal.currentState = .critical
        XCTAssertFalse(advisor.shouldUseAutocapture)
    }

    func testAutocapture_memoryCritical_returnsFalse() {
        memory.currentPressure = .critical
        XCTAssertFalse(advisor.shouldUseAutocapture)
    }

    func testAutocapture_inferenceTooSlow_returnsFalse() {
        // Default budget: (1/30)*5 = 0.1666s. >90% = >0.15s. Use 0.20s.
        for _ in 0 ..< 3 {
            inferenceTracker.record(latency: 0.20)
        }
        XCTAssertFalse(advisor.shouldUseAutocapture)
    }

    func testAutocapture_thermalSeriousOnly_returnsTrue() {
        thermal.currentState = .serious
        XCTAssertTrue(advisor.shouldUseAutocapture)
    }

    // MARK: - JPEG Quality

    func testJpegQuality_nominal_returns085() {
        XCTAssertEqual(advisor.recommendedJpegQuality, 0.85)
    }

    func testJpegQuality_networkPoor_returns050() {
        network.currentQuality = .poor
        XCTAssertEqual(advisor.recommendedJpegQuality, 0.50)
    }

    func testJpegQuality_networkConstrained_returns065() {
        network.currentQuality = .constrained
        XCTAssertEqual(advisor.recommendedJpegQuality, 0.65)
    }

    func testJpegQuality_lowPowerMode_returns065() {
        battery.isLowPowerMode = true
        XCTAssertEqual(advisor.recommendedJpegQuality, 0.65)
    }

    func testJpegQuality_constrainedAndLowPower_returns065() {
        network.currentQuality = .constrained
        battery.isLowPowerMode = true
        XCTAssertEqual(advisor.recommendedJpegQuality, 0.65)
    }

    // MARK: - TFLite Thread Count

    func testTFLiteThreads_nominal_returns2() {
        XCTAssertEqual(advisor.recommendedTFLiteThreadCount, 2)
    }

    func testTFLiteThreads_thermalSerious_returns1() {
        thermal.currentState = .serious
        XCTAssertEqual(advisor.recommendedTFLiteThreadCount, 1)
    }

    func testTFLiteThreads_lowCoreCount_returns1() {
        processorInfo.activeProcessorCount = 2
        // Re-create advisor with new processor info
        advisor = PerformanceAdvisor(
            thermal: thermal,
            memory: memory,
            network: network,
            battery: battery,
            inferenceTracker: inferenceTracker,
            processorInfo: processorInfo,
            clock: { [unowned self] in self.fakeNow }
        )
        XCTAssertEqual(advisor.recommendedTFLiteThreadCount, 1)
    }

    // MARK: - Max Image Size

    func testMaxImageSize_nominal_returns1024() {
        XCTAssertEqual(advisor.recommendedMaxImageSize, 1024)
    }

    func testMaxImageSize_memoryLow_returns768() {
        memory.currentPressure = .low
        XCTAssertEqual(advisor.recommendedMaxImageSize, 768)
    }

    func testMaxImageSize_networkPoor_returns768() {
        network.currentQuality = .poor
        XCTAssertEqual(advisor.recommendedMaxImageSize, 768)
    }

    // MARK: - Combined Conditions

    func testCombined_thermalAndMemory_downgradesResolution() {
        thermal.currentState = .serious
        memory.currentPressure = .critical
        XCTAssertEqual(advisor.recommendedVideoResolution, .sd540p)
    }

    func testCombined_networkPoorAndThermalCritical_minimizeAll() {
        network.currentQuality = .poor
        thermal.currentState = .critical
        XCTAssertEqual(advisor.recommendedJpegQuality, 0.50)
        XCTAssertFalse(advisor.shouldUseAutocapture)
    }

    func testAllSignalsUnknown_shouldReturnDefaults() {
        thermal.currentState = .unknown
        memory.currentPressure = .unknown
        network.currentQuality = .unknown
        XCTAssertEqual(advisor.recommendedVideoResolution, .hd720p)
        XCTAssertTrue(advisor.shouldUseAutocapture)
        XCTAssertEqual(advisor.recommendedJpegQuality, 0.85)
        XCTAssertEqual(advisor.recommendedMaxImageSize, 1024)
    }

    // MARK: - Hysteresis

    func testHysteresis_resolution_staysDegradedWithin10Seconds() {
        // Trigger downgrade
        thermal.currentState = .serious
        XCTAssertEqual(advisor.recommendedVideoResolution, .sd540p)

        // Conditions recover, but within hysteresis window
        thermal.currentState = .nominal
        fakeNow = fakeNow.addingTimeInterval(5)
        XCTAssertEqual(advisor.recommendedVideoResolution, .sd540p)
    }

    func testHysteresis_resolution_upgradesAfter10Seconds() {
        // Trigger downgrade
        thermal.currentState = .serious
        XCTAssertEqual(advisor.recommendedVideoResolution, .sd540p)

        // Conditions recover after hysteresis window
        thermal.currentState = .nominal
        fakeNow = fakeNow.addingTimeInterval(11)
        XCTAssertEqual(advisor.recommendedVideoResolution, .hd720p)
    }

    func testHysteresis_autocapture_staysDisabledWithin10Seconds() {
        thermal.currentState = .critical
        XCTAssertFalse(advisor.shouldUseAutocapture)

        thermal.currentState = .nominal
        fakeNow = fakeNow.addingTimeInterval(5)
        XCTAssertFalse(advisor.shouldUseAutocapture)
    }

    func testHysteresis_autocapture_reEnablesAfter10Seconds() {
        thermal.currentState = .critical
        XCTAssertFalse(advisor.shouldUseAutocapture)

        thermal.currentState = .nominal
        fakeNow = fakeNow.addingTimeInterval(11)
        XCTAssertTrue(advisor.shouldUseAutocapture)
    }

    func testHysteresis_parametersAreIndependent() {
        // Downgrade resolution at T=0
        thermal.currentState = .serious
        XCTAssertEqual(advisor.recommendedVideoResolution, .sd540p)

        // Move to T=5, then downgrade autocapture
        fakeNow = fakeNow.addingTimeInterval(5)
        thermal.currentState = .critical
        XCTAssertFalse(advisor.shouldUseAutocapture)

        // Move to T=11 — resolution should upgrade (>10s since resolution downgrade),
        // but autocapture should stay disabled (only 6s since autocapture downgrade)
        fakeNow = fakeNow.addingTimeInterval(6)
        thermal.currentState = .nominal
        XCTAssertEqual(advisor.recommendedVideoResolution, .hd720p)
        XCTAssertFalse(advisor.shouldUseAutocapture)

        // Move to T=16 — autocapture should also re-enable
        fakeNow = fakeNow.addingTimeInterval(5)
        XCTAssertTrue(advisor.shouldUseAutocapture)
    }
}
