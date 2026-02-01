//
//  Bundle+SPMPublic.swift
//  TruoraValidationsSDK
//
//  Exposes Bundle.module as public when building with Swift Package Manager.
//  SPM generates Bundle.module as internal; this file provides public access.
//

#if SWIFT_PACKAGE
import Foundation

public extension Bundle {
    /// Public accessor for the SDK resource bundle when built as Swift Package.
    static var truoraModule: Bundle { .module }
}
#endif
