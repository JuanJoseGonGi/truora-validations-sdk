//
//  Bundle+SPMPublic.swift
//  TruoraValidationsSDK
//
//  Provides public access to the SDK resource bundle when building with Swift Package Manager.
//  SPM generates Bundle.module as internal, so we find the bundle by name at runtime.
//

#if SWIFT_PACKAGE
import Foundation

private class BundleFinder {}

public extension Bundle {
    /// Public accessor for the SDK resource bundle when built as Swift Package.
    /// Locates the resource bundle by name since SPM's Bundle.module is internal.
    static var truoraModule: Bundle {
        let bundleName = "TruoraValidationsSDK_TruoraValidationsSDK"
        let candidates: [URL?] = [
            Bundle.main.resourceURL,
            Bundle(for: BundleFinder.self).resourceURL,
            Bundle(for: BundleFinder.self).bundleURL
        ]
        for candidate in candidates {
            guard let base = candidate else { continue }
            let bundleURL = base.appendingPathComponent(bundleName + ".bundle")
            if let bundle = Bundle(url: bundleURL) {
                return bundle
            }
        }
        // Fallback to the bundle containing BundleFinder to avoid crashes
        return Bundle(for: BundleFinder.self)
    }
}
#endif
