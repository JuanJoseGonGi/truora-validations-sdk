//
//  SDKLocaleEnvironment.swift
//  TruoraValidationsSDK
//
//  Injects the given locale into the SwiftUI environment so that
//  all views in the flow use the SDK-configured language.
//

import SwiftUI

extension View {
    /// Applies the given locale to the environment (use TruoraLocalization.currentLocale).
    /// Use at the root of each SDK screen so that locale-dependent behavior uses the right language.
    func sdkLocaleEnvironment(locale: Locale) -> some View {
        environment(\.locale, locale)
    }
}
