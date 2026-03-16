import Foundation
@testable import TruoraValidationsSDK

/// Configurable mock for `SystemInfoProviding` used in injection detection tests.
///
/// All properties are settable via init for deterministic test scenarios.
final class MockSystemInfoProvider: SystemInfoProviding, @unchecked Sendable {
    let isSimulator: Bool
    let deviceModel: String
    let simulatorDeviceName: String?
    private let existingFiles: Set<String>
    private let canWriteSandbox: Bool
    let loadedDylibs: [String]

    init(
        isSimulator: Bool = false,
        deviceModel: String = "iPhone",
        simulatorDeviceName: String? = nil,
        existingFiles: Set<String> = [],
        canWriteSandbox: Bool = false,
        loadedDylibs: [String] = []
    ) {
        self.isSimulator = isSimulator
        self.deviceModel = deviceModel
        self.simulatorDeviceName = simulatorDeviceName
        self.existingFiles = existingFiles
        self.canWriteSandbox = canWriteSandbox
        self.loadedDylibs = loadedDylibs
    }

    func fileExists(at path: String) -> Bool {
        existingFiles.contains(path)
    }

    func canWriteOutsideSandbox(testPath: String) -> Bool {
        canWriteSandbox
    }
}
