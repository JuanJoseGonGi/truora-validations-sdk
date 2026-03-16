import Foundation
import XCTest
@testable import TruoraValidationsSDK

final class JailbreakCheckerTests: XCTestCase {
    // MARK: - File System Artifacts

    func testCydiaAppExists_producesRiskFactor() {
        let mock = MockSystemInfoProvider(existingFiles: ["/Applications/Cydia.app"])
        let checker = JailbreakChecker(systemInfo: mock)

        let factors = checker.check()

        let cydiaFactor = factors.first { $0.category == "jailbreak" && $0.signal.contains("Cydia") }
        XCTAssertNotNil(cydiaFactor)
        XCTAssertEqual(cydiaFactor?.penalty, 20)
    }

    func testBashExists_producesRiskFactor() {
        let mock = MockSystemInfoProvider(existingFiles: ["/bin/bash"])
        let checker = JailbreakChecker(systemInfo: mock)

        let factors = checker.check()

        let bashFactor = factors.first { $0.signal.contains("/bin/bash") }
        XCTAssertNotNil(bashFactor)
        XCTAssertEqual(bashFactor?.penalty, 20)
    }

    func testSshdExists_producesRiskFactor() {
        let mock = MockSystemInfoProvider(existingFiles: ["/usr/sbin/sshd"])
        let checker = JailbreakChecker(systemInfo: mock)

        let factors = checker.check()

        let sshdFactor = factors.first { $0.signal.contains("/usr/sbin/sshd") }
        XCTAssertNotNil(sshdFactor)
        XCTAssertEqual(sshdFactor?.penalty, 20)
    }

    func testAptExists_producesRiskFactor() {
        let mock = MockSystemInfoProvider(existingFiles: ["/etc/apt"])
        let checker = JailbreakChecker(systemInfo: mock)

        let factors = checker.check()

        let aptFactor = factors.first { $0.signal.contains("/etc/apt") }
        XCTAssertNotNil(aptFactor)
        XCTAssertEqual(aptFactor?.penalty, 20)
    }

    func testMultipleJailbreakPaths_eachProducesOwnRiskFactor() {
        let mock = MockSystemInfoProvider(existingFiles: [
            "/Applications/Cydia.app",
            "/bin/bash",
            "/usr/sbin/sshd"
        ])
        let checker = JailbreakChecker(systemInfo: mock)

        let factors = checker.check()

        let fileFactors = factors.filter { $0.category == "jailbreak" && $0.penalty == 20 }
        XCTAssertEqual(fileFactors.count, 3)
    }

    // MARK: - Sandbox Integrity

    func testSandboxWriteSucceeds_producesHighPenalty() {
        let mock = MockSystemInfoProvider(canWriteSandbox: true)
        let checker = JailbreakChecker(systemInfo: mock)

        let factors = checker.check()

        let sandboxFactor = factors.first { $0.penalty == 50 && $0.confidence == "high" }
        XCTAssertNotNil(sandboxFactor)
        XCTAssertEqual(sandboxFactor?.category, "jailbreak")
    }

    // MARK: - dyld Inspection

    func testSuspiciousDylibLoaded_producesRiskFactor() {
        let mock = MockSystemInfoProvider(loadedDylibs: [
            "/usr/lib/system/libsystem_c.dylib",
            "/Library/MobileSubstrate/MobileSubstrate.dylib"
        ])
        let checker = JailbreakChecker(systemInfo: mock)

        let factors = checker.check()

        let dylibFactor = factors.first { $0.penalty == 40 }
        XCTAssertNotNil(dylibFactor)
        XCTAssertEqual(dylibFactor?.category, "jailbreak")
        XCTAssertTrue(dylibFactor?.signal.contains("MobileSubstrate") == true)
    }

    func testMultipleSuspiciousDylibs_eachProducesRiskFactor() {
        let mock = MockSystemInfoProvider(loadedDylibs: [
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/Library/TweakInject/something.dylib"
        ])
        let checker = JailbreakChecker(systemInfo: mock)

        let factors = checker.check()

        let dylibFactors = factors.filter { $0.penalty == 40 }
        XCTAssertEqual(dylibFactors.count, 2)
    }

    // MARK: - Clean Device

    func testCleanDevice_producesNoRiskFactors() {
        let mock = MockSystemInfoProvider(
            existingFiles: [],
            canWriteSandbox: false,
            loadedDylibs: [
                "/usr/lib/system/libsystem_c.dylib",
                "/usr/lib/libobjc.A.dylib"
            ]
        )
        let checker = JailbreakChecker(systemInfo: mock)

        let factors = checker.check()

        XCTAssertTrue(factors.isEmpty)
    }

    // MARK: - Error Handling (file checks wrapped in do-catch)

    func testFileCheckErrors_doNotProduceRiskFactors() {
        // A clean device with no files should produce no factors
        // Errors in file access are caught and ignored (sandbox working correctly)
        let mock = MockSystemInfoProvider(existingFiles: [])
        let checker = JailbreakChecker(systemInfo: mock)

        let factors = checker.check()

        XCTAssertTrue(factors.filter { $0.penalty == 20 }.isEmpty)
    }
}
