import Foundation
@testable import TruoraValidationsSDK

/// Mock implementing DetectionBridging for unit tests.
///
/// Thread-safe via `@unchecked Sendable`: stubs are immutable `let`
/// properties; mutable call counters and argument captures are protected by NSLock.
final class MockDetectionBridge: DetectionBridging, @unchecked Sendable {
    let stubbedBitmaskVersion: UInt32
    let stubbedRunChecksResult: UInt32
    let stubbedSignature: String
    let stubbedEscalationThreshold: UInt32

    private let lock = NSLock()
    private var _runChecksCallCount: Int = 0
    private var _signReportCallCount: Int = 0
    private var _lastSignReportValidationId: String?
    private var _lastSignReportFlowType: String?

    var runChecksCallCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return _runChecksCallCount
    }

    var signReportCallCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return _signReportCallCount
    }

    var lastSignReportValidationId: String? {
        lock.lock()
        defer { lock.unlock() }
        return _lastSignReportValidationId
    }

    var lastSignReportFlowType: String? {
        lock.lock()
        defer { lock.unlock() }
        return _lastSignReportFlowType
    }

    init(
        bitmaskVersion: UInt32 = 1,
        runChecksResult: UInt32 = 0,
        signature: String = "mock-hmac-signature",
        escalationThreshold: UInt32 = 50
    ) {
        self.stubbedBitmaskVersion = bitmaskVersion
        self.stubbedRunChecksResult = runChecksResult
        self.stubbedSignature = signature
        self.stubbedEscalationThreshold = escalationThreshold
    }

    func runChecks(checksMask: UInt32) -> UInt32 {
        lock.lock()
        _runChecksCallCount += 1
        lock.unlock()
        return stubbedRunChecksResult
    }

    func signReport(
        validationId: String,
        flowType: String,
        trustScore: UInt32,
        riskBitmask: UInt32,
        timestamp: UInt64
    ) -> String {
        lock.lock()
        _signReportCallCount += 1
        _lastSignReportValidationId = validationId
        _lastSignReportFlowType = flowType
        lock.unlock()
        return stubbedSignature
    }

    func bitmaskVersion() -> UInt32 {
        stubbedBitmaskVersion
    }

    func getEscalationThreshold() -> UInt32 {
        stubbedEscalationThreshold
    }
}
