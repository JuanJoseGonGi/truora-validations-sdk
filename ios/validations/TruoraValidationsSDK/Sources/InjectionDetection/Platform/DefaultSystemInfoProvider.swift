import Foundation
import MachO
#if canImport(UIKit)
import UIKit
#endif

/// Production implementation of `SystemInfoProviding` using real iOS system APIs.
///
/// Wraps ProcessInfo, FileManager, UIDevice, and dyld calls for injection detection.
/// All operations are wrapped in error handling to avoid crashes from sandbox restrictions.
struct DefaultSystemInfoProvider: SystemInfoProviding {
    var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil
        #endif
    }

    var deviceModel: String {
        #if canImport(UIKit)
        return UIDevice.current.model
        #else
        return "Unknown"
        #endif
    }

    var simulatorDeviceName: String? {
        ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"]
    }

    func fileExists(at path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }

    func canWriteOutsideSandbox(testPath: String) -> Bool {
        do {
            try "jailbreak_test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {
            return false
        }
    }

    var loadedDylibs: [String] {
        var dylibs: [String] = []
        let count = _dyld_image_count()
        for index in 0 ..< count {
            guard let name = _dyld_get_image_name(index) else { continue }
            dylibs.append(String(cString: name))
        }
        return dylibs
    }
}
