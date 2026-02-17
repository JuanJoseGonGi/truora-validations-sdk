//
//  TruoraLanguage.swift
//  TruoraValidationsSDK
//
//  Created by Brayan Escobar on 10/11/25.
//

import Foundation

/// Supported languages for the Truora SDK.
/// When the client does not call withLanguage(), the SDK uses the device locale internally.
public enum TruoraLanguage: String, Codable, CaseIterable {
    case english = "en"
    case spanish = "es"
    case portuguese = "pt"

    /// The .lproj directory name for this language in the resource bundle (e.g. "en", "es", "pt").
    var languageBundleName: String {
        switch self {
        case .english: "en"
        case .spanish: "es"
        case .portuguese: "pt"
        }
    }

    /// The Locale for this language.
    var locale: Locale {
        Locale(identifier: rawValue)
    }
}
