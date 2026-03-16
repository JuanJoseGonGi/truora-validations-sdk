import Foundation

/// Protocol abstracting system-level API calls for injection detection.
///
/// All system access (ProcessInfo, FileManager, UIDevice, dyld) is wrapped behind
/// this protocol to enable unit testing with mock implementations.
protocol SystemInfoProviding: Sendable {
    /// Whether the app is running in the iOS Simulator (runtime check)
    var isSimulator: Bool { get }

    /// Device model string from UIDevice (e.g., "iPhone", "iPad", "iPhone Simulator")
    var deviceModel: String { get }

    /// Value of the SIMULATOR_DEVICE_NAME environment variable, if present
    var simulatorDeviceName: String? { get }

    /// Checks whether a file exists at the given absolute path
    func fileExists(at path: String) -> Bool

    /// Attempts to write a test file outside the sandbox. Returns true if the write succeeds.
    func canWriteOutsideSandbox(testPath: String) -> Bool

    /// Returns the list of currently loaded dynamic library paths via dyld inspection
    var loadedDylibs: [String] { get }
}
