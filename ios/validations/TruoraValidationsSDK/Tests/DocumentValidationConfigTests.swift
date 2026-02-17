//
//  DocumentValidationConfigTests.swift
//  TruoraValidationsSDK
//
//  Created by Truora on 05/02/26.
//

import XCTest
@testable import TruoraValidationsSDK

@MainActor final class DocumentValidationConfigTests: XCTestCase {
    var sut: Document!

    override func setUp() {
        super.setUp()
        sut = Document()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Finish View Configuration Tests

    func testFinishViewConfigDefaultIsNil() {
        XCTAssertNil(sut.finishViewConfig, "Finish view config should be nil by default")
    }

    func testSetFinishViewConfiguration() {
        // Given
        let config = FinishViewConfiguration(success: .show, failure: .hide)

        // When
        let result = sut.setFinishViewConfiguration(config)

        // Then
        XCTAssertNotNil(sut.finishViewConfig, "Should set finish view config")
        XCTAssertEqual(sut.finishViewConfig?.success, .show)
        XCTAssertEqual(sut.finishViewConfig?.failure, .hide)
        XCTAssertTrue(result === sut, "Should return self for chaining")
    }

    func testSetFinishViewConfigurationImplicitlyEnablesWaitForResults() {
        // Given
        _ = sut.waitForResults(false)
        XCTAssertFalse(sut.waitForResults, "Precondition: wait for results disabled")

        // When
        _ = sut.setFinishViewConfiguration(FinishViewConfiguration(success: .hide, failure: .hide))

        // Then
        XCTAssertTrue(sut.waitForResults, "Should implicitly enable wait for results")
    }

    func testWaitForResultsFalseWithoutFinishViewConfig_succeeds() {
        // When — disabling waitForResults without finishViewConfig is valid
        _ = sut.waitForResults(false)

        // Then
        XCTAssertFalse(sut.waitForResults)
        XCTAssertNil(sut.finishViewConfig)
    }

    // Note: waitForResults(false) after setFinishViewConfiguration
    // triggers a preconditionFailure, which cannot be tested with XCTest
    // since it terminates the process. The precondition protects against
    // developer misconfiguration at the call site.
    // ValidationConfig.setValidation also throws invalidConfiguration as a
    // defense-in-depth check, but that path is unreachable through the
    // public builder API since the precondition fires first.

    // MARK: - Passport Autocapture Validation Tests

    // Note: useAutocapture(true) after setDocumentType("passport") and
    // setDocumentType("passport") after useAutocapture(true) both trigger
    // preconditionFailure, which cannot be tested with XCTest since it
    // terminates the process. The precondition protects against developer
    // misconfiguration at the call site.
    // ValidationConfig.setValidation also throws invalidConfiguration as a
    // defense-in-depth check for passport + autocapture.

    func testPassportWithDefaultAutocapture_succeeds() {
        // When the developer does NOT explicitly call useAutocapture(true),
        // configuration should succeed (autocapture will be silently disabled at runtime)
        _ = sut.setDocumentType("passport")

        XCTAssertEqual(sut.documentType, "passport")
        XCTAssertTrue(sut.useAutocapture, "Default autocapture should remain true")
    }

    func testPassportWithAutocaptureDisabled_succeeds() {
        _ = sut
            .setDocumentType("passport")
            .useAutocapture(false)

        XCTAssertEqual(sut.documentType, "passport")
        XCTAssertFalse(sut.useAutocapture)
    }

    func testPassportWithAutocaptureEnabledThenDisabled_succeeds() {
        // Calling useAutocapture(false) after useAutocapture(true) should reset the flag,
        // so setDocumentType("passport") must not crash.
        _ = sut
            .useAutocapture(true)
            .useAutocapture(false)
            .setDocumentType("passport")

        XCTAssertEqual(sut.documentType, "passport")
        XCTAssertFalse(sut.useAutocapture)
    }

    func testNonPassportWithAutocapture_succeeds() {
        _ = sut
            .setDocumentType("national-id")
            .useAutocapture(true)

        XCTAssertEqual(sut.documentType, "national-id")
        XCTAssertTrue(sut.useAutocapture)
    }

    func testMethodChainingWithFinishViewConfig() {
        // Given
        let finishConfig = FinishViewConfiguration(success: .hide, failure: .show)

        // When
        let result =
            sut
                .setCountry("CO")
                .setDocumentType("national-id")
                .setFinishViewConfiguration(finishConfig)
                .setTimeout(90)

        // Then
        XCTAssertTrue(result === sut, "Should support method chaining")
        XCTAssertEqual(sut.country, "CO")
        XCTAssertEqual(sut.documentType, "national-id")
        XCTAssertNotNil(sut.finishViewConfig)
        XCTAssertTrue(sut.waitForResults)
        XCTAssertEqual(sut.timeout, 90)
    }
}
