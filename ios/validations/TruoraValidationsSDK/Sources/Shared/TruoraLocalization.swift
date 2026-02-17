//
//  TruoraLocalization.swift
//  TruoraValidationsSDK
//
//  Created by Truora on 06/02/26.
//

import Foundation

// MARK: - How TruoraLocalization works

//
// 1. LANGUAGE SOURCE
//    Language is read from ValidationConfig.shared.lang (set via Builder.withLanguage).
//    When nil (withLanguage not called), SDK uses device locale internally.
//
// 2. WHAT THIS FILE DOES
//    - bundle(for:): given a TruoraLanguage (or nil), returns the Bundle. nil → Bundle.truoraModule.
//    - currentBundle: the bundle for ValidationConfig.shared.lang.
//    - currentLocale: the Locale for formatting dates/numbers in that language.
//    - string(forKey:): returns the localized string for a key (e.g. "document_selection_title").
//    - string(forKey:arguments:): same but with placeholders like "Verification performed on %@".
//
// 3. RUNTIME FLOW
//    Views call TruoraLocalization.string(forKey: LocalizationKeys.documentSelectionTitle).
//    That uses currentBundle, which in turn calls bundle(for: ValidationConfig.shared.lang).
//

enum TruoraLocalization {
    /// Returns the resource bundle for a given language.
    /// - If language is nil → Bundle.truoraModule (fallback).
    /// - If language is .spanish → bundle pointing to es.lproj (Spanish Localizable.strings).
    static func bundle(for language: TruoraLanguage?) -> Bundle {
        guard let language else { return Bundle.truoraModule }

        let base = Bundle.truoraModule
        let name = language.languageBundleName

        if let lprojURL = base.url(forResource: name, withExtension: "lproj", subdirectory: nil),
           let bundle = Bundle(url: lprojURL) {
            return bundle
        }
        if let path = base.path(forResource: name, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        let explicitPath = (base.bundlePath as NSString).appendingPathComponent("\(name).lproj")
        if FileManager.default.fileExists(atPath: explicitPath),
           let bundle = Bundle(path: explicitPath) {
            return bundle
        }
        return base
    }

    /// Current bundle: depends on ValidationConfig.shared.lang.
    static var currentBundle: Bundle {
        bundle(for: ValidationConfig.shared.lang)
    }

    /// Localized string for the key. Uses ValidationConfig.shared.lang.
    static func string(forKey key: String, table: String? = nil) -> String {
        currentBundle.localizedString(forKey: key, value: nil, table: table)
    }

    /// Locale for formatting dates/numbers. Uses configured language or device locale when nil.
    static var currentLocale: Locale {
        ValidationConfig.shared.lang?.locale ?? Locale.current
    }

    /// Localized string with arguments (e.g. "Verification performed on %@" with the date).
    static func string(forKey key: String, arguments: CVarArg...) -> String {
        let format = currentBundle.localizedString(forKey: key, value: nil, table: "Localizable")
        return String(format: format, locale: currentLocale, arguments: arguments)
    }
}
