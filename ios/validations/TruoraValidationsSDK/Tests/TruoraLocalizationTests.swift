//
//  TruoraLocalizationTests.swift
//  TruoraValidationsSDK
//
//  Created by Truora on 06/02/26.
//

import XCTest
@testable import TruoraValidationsSDK

@MainActor final class TruoraLocalizationTests: XCTestCase {
    // MARK: - languageBundleName Tests

    func testLanguageBundleName_english() {
        XCTAssertEqual(TruoraLanguage.english.languageBundleName, "en")
    }

    func testLanguageBundleName_spanish() {
        XCTAssertEqual(TruoraLanguage.spanish.languageBundleName, "es")
    }

    func testLanguageBundleName_portuguese() {
        XCTAssertEqual(TruoraLanguage.portuguese.languageBundleName, "pt")
    }

    // MARK: - Locale Tests

    func testLocale_english() {
        XCTAssertEqual(TruoraLanguage.english.locale.identifier, "en")
    }

    func testLocale_spanish() {
        XCTAssertEqual(TruoraLanguage.spanish.locale.identifier, "es")
    }

    func testLocale_portuguese() {
        XCTAssertEqual(TruoraLanguage.portuguese.locale.identifier, "pt")
    }

    // MARK: - Bundle Resolution Tests

    func testBundle_nilLanguage_returnsBundleModule() {
        // When language is nil, should return Bundle.module (device locale)
        let bundle = TruoraLocalization.bundle(for: nil)

        // Bundle.module should be returned for nil language
        XCTAssertNotNil(bundle)
    }

    func testBundle_english_returnsValidBundle() {
        let bundle = TruoraLocalization.bundle(for: .english)

        XCTAssertNotNil(bundle)
    }

    func testBundle_spanish_returnsValidBundle() {
        let bundle = TruoraLocalization.bundle(for: .spanish)

        XCTAssertNotNil(bundle)
    }

    func testBundle_portuguese_returnsValidBundle() {
        let bundle = TruoraLocalization.bundle(for: .portuguese)

        XCTAssertNotNil(bundle)
    }

    // MARK: - currentLocale Tests

    func testCurrentLocale_afterReset_usesDeviceLocale() {
        // Given: ValidationConfig is reset (lang is nil → use device)
        ValidationConfig.shared.reset()

        // When
        let locale = TruoraLocalization.currentLocale

        // Then: Should return device locale when lang was not configured
        XCTAssertEqual(locale, Locale.current)
    }

    // MARK: - String Resolution Tests

    func testString_returnsNonEmptyString() {
        // Test that a known key returns a non-empty string
        let result = TruoraLocalization.string(forKey: LocalizationKeys.commonCancel)

        XCTAssertFalse(result.isEmpty, "Should return a non-empty localized string")
    }

    func testString_unknownKey_returnsKey() {
        // Test that an unknown key returns the key itself (iOS default behavior)
        let unknownKey = "unknown_key_that_does_not_exist_12345"
        let result = TruoraLocalization.string(forKey: unknownKey)

        XCTAssertEqual(result, unknownKey, "Unknown key should return the key itself")
    }
}
