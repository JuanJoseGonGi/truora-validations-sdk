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
//    Language is read from ValidationConfig.shared.uiConfig.language (UIConfig).
//    - If the integrator called uiConfig.setLanguage(.spanish) → language is .spanish.
//    - If setLanguage() was not called → language is nil → device language is used.
//
// 2. WHAT THIS FILE DOES
//    - bundle(for:): given a TruoraLanguage (or nil), returns the Bundle containing
//      strings for that language (e.g. es.lproj, en.lproj, pt.lproj inside the module).
//    - currentBundle: the bundle for the current UIConfig language (or device language).
//    - currentLocale: the Locale for formatting dates/numbers in that language.
//    - string(forKey:): returns the localized string for a key (e.g. "document_selection_title").
//    - string(forKey:arguments:): same but with placeholders like "Verification performed on %@".
//
// 3. RUNTIME FLOW
//    Views call TruoraLocalization.string(forKey: LocalizationKeys.documentSelectionTitle).
//    That uses currentBundle, which in turn calls bundle(for: ValidationConfig.shared.uiConfig.language).
//    If language == .spanish → es.lproj is used → Spanish string is returned.
//    If language == nil → Bundle.truoraModule is used → iOS picks language from device preferences.
//

enum TruoraLocalization {
    /// Returns the resource bundle for a given language.
    /// - If language is nil → Bundle.truoraModule (system chooses language from device).
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

    /// Current bundle: depends on UIConfig.language (or device language if nil).
    static var currentBundle: Bundle {
        bundle(for: ValidationConfig.shared.uiConfig.language)
    }

    /// Localized string for the key. Uses UIConfig language or device language.
    static func string(forKey key: String, table: String? = nil) -> String {
        currentBundle.localizedString(forKey: key, value: nil, table: table)
    }

    /// Locale for formatting dates/numbers according to the configured language.
    static var currentLocale: Locale {
        ValidationConfig.shared.uiConfig.language?.locale ?? Locale.current
    }

    /// Localized string with arguments (e.g. "Verification performed on %@" with the date).
    static func string(forKey key: String, arguments: CVarArg...) -> String {
        let format = currentBundle.localizedString(forKey: key, value: nil, table: "Localizable")
        return String(format: format, locale: currentLocale, arguments: arguments)
    }
}
