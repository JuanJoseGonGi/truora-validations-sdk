import Foundation

/// Checks for jailbreak indicators (Layer 1 and Layer 3).
///
/// Detects jailbreak via file system artifacts (Cydia/Sileo/Zebra/su/sshd),
/// sandbox write integrity, and dyld inspection for MobileSubstrate/TweakInject.
///
/// NOTE: Does NOT use `canOpenURL("cydia://")` as it requires Info.plist
/// LSApplicationQueriesSchemes entries which is intrusive for an SDK.
struct JailbreakChecker {
    private let systemInfo: SystemInfoProviding

    /// File system paths associated with common jailbreak tools and artifacts.
    private let jailbreakPaths = [
        "/Applications/Cydia.app",
        "/Applications/Sileo.app",
        "/Applications/Zebra.app",
        "/Library/MobileSubstrate/MobileSubstrate.dylib",
        "/bin/bash",
        "/usr/sbin/sshd",
        "/etc/apt",
        "/usr/bin/ssh",
        "/private/var/lib/apt/",
        "/private/var/lib/cydia",
        "/private/var/stash"
    ]

    /// Dynamic library substrings associated with jailbreak injection frameworks.
    private let suspiciousLibs = [
        "MobileSubstrate",
        "TweakInject",
        "SSLKillSwitch",
        "PreferenceLoader",
        "libcycript",
        "SubstrateLoader"
    ]

    init(systemInfo: SystemInfoProviding) {
        self.systemInfo = systemInfo
    }

    /// Runs all jailbreak checks and returns detected risk factors.
    func check() -> [RiskFactor] {
        var factors: [RiskFactor] = []
        factors.append(contentsOf: checkFileSystemArtifacts())
        factors.append(contentsOf: checkSandboxIntegrity())
        factors.append(contentsOf: checkLoadedDylibs())
        return factors
    }

    // MARK: - Private

    private func checkFileSystemArtifacts() -> [RiskFactor] {
        var factors: [RiskFactor] = []
        for path in jailbreakPaths {
            guard systemInfo.fileExists(at: path) else { continue }
            factors.append(RiskFactor(
                category: "jailbreak",
                signal: "File found: \(path)",
                penalty: 20,
                confidence: "high"
            ))
        }
        return factors
    }

    private func checkSandboxIntegrity() -> [RiskFactor] {
        let testPath = "/private/jailbreak_test_\(UUID().uuidString)"

        guard systemInfo.canWriteOutsideSandbox(testPath: testPath) else {
            return []
        }

        return [RiskFactor(
            category: "jailbreak",
            signal: "Sandbox compromised: write outside sandbox succeeded",
            penalty: 50,
            confidence: "high"
        )]
    }

    private func checkLoadedDylibs() -> [RiskFactor] {
        var factors: [RiskFactor] = []
        for dylib in systemInfo.loadedDylibs {
            for suspect in suspiciousLibs {
                guard dylib.contains(suspect) else { continue }
                factors.append(RiskFactor(
                    category: "jailbreak",
                    signal: "Suspicious dylib: \(suspect)",
                    penalty: 40,
                    confidence: "high"
                ))
            }
        }
        return factors
    }
}
