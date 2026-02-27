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

    // MARK: - Passport Autocapture (Public API)

    // setDocumentType("passport") silently disables _useAutocapture but keeps
    // _didExplicitlyEnableAutocapture so validateAutocaptureConfig can throw
    // a catchable TruoraException at start time.
    //
    // useAutocapture(true) on a passport document keeps autocapture disabled
    // (enabled && !isPassport) but records the explicit intent.

    func testPassportWithDefaultAutocapture_disablesAutocapture() {
        // No explicit useAutocapture call — setDocumentType silently disables it.
        _ = sut.setDocumentType("passport")

        XCTAssertEqual(sut.documentType, "passport")
        XCTAssertFalse(sut.useAutocapture, "Autocapture should be disabled for passport")
        XCTAssertFalse(sut.didExplicitlyEnableAutocapture)
    }

    func testPassportWithAutocaptureDisabled_succeeds() {
        _ = sut
            .setDocumentType("passport")
            .useAutocapture(false)

        XCTAssertEqual(sut.documentType, "passport")
        XCTAssertFalse(sut.useAutocapture)
        XCTAssertFalse(sut.didExplicitlyEnableAutocapture)
    }

    func testUseAutocaptureTrueThenPassport_disablesButKeepsExplicitFlag() {
        // Developer misconfiguration: useAutocapture(true) then passport.
        // No crash — validateAutocaptureConfig will throw at start time instead.
        _ = sut
            .useAutocapture(true)
            .setDocumentType("passport")

        XCTAssertEqual(sut.documentType, "passport")
        XCTAssertFalse(sut.useAutocapture, "Autocapture should be disabled for passport")
        XCTAssertTrue(sut.didExplicitlyEnableAutocapture, "Explicit flag preserved for validation")
    }

    func testPassportThenUseAutocaptureTrue_disablesButKeepsExplicitFlag() {
        // Developer misconfiguration: passport then useAutocapture(true).
        // No crash — validateAutocaptureConfig will throw at start time instead.
        _ = sut
            .setDocumentType("passport")
            .useAutocapture(true)

        XCTAssertEqual(sut.documentType, "passport")
        XCTAssertFalse(sut.useAutocapture, "Autocapture should remain disabled for passport")
        XCTAssertTrue(sut.didExplicitlyEnableAutocapture, "Explicit flag preserved for validation")
    }

    func testPassportWithAutocaptureEnabledThenDisabled_succeeds() {
        // useAutocapture(false) resets the explicit flag, so passport is fine.
        _ = sut
            .useAutocapture(true)
            .useAutocapture(false)
            .setDocumentType("passport")

        XCTAssertEqual(sut.documentType, "passport")
        XCTAssertFalse(sut.useAutocapture)
        XCTAssertFalse(sut.didExplicitlyEnableAutocapture)
    }

    func testNonPassportWithAutocapture_succeeds() {
        _ = sut
            .setDocumentType("national-id")
            .useAutocapture(true)

        XCTAssertEqual(sut.documentType, "national-id")
        XCTAssertTrue(sut.useAutocapture)
    }

    // MARK: - applyRuntimeDocumentType (Internal / Presenter API)

    func testApplyRuntimeDocumentType_passport_disablesAutocaptureAndResetsFlag() {
        // Simulates the document selection presenter flow: the developer
        // enabled autocapture via the Builder, and the user picks passport.
        _ = sut.useAutocapture(true)
        XCTAssertTrue(sut.didExplicitlyEnableAutocapture, "Precondition")

        _ = sut.applyRuntimeDocumentType("passport")

        XCTAssertEqual(sut.documentType, "passport")
        XCTAssertFalse(sut.useAutocapture, "Autocapture should be disabled for passport")
        XCTAssertFalse(sut.didExplicitlyEnableAutocapture, "Flag should be reset for runtime selection")
    }

    func testApplyRuntimeDocumentType_nonPassport_keepsAutocapture() {
        // Non-passport runtime selection should not change autocapture settings.
        _ = sut.useAutocapture(true)

        _ = sut.applyRuntimeDocumentType("national-id")

        XCTAssertEqual(sut.documentType, "national-id")
        XCTAssertTrue(sut.useAutocapture)
        XCTAssertTrue(sut.didExplicitlyEnableAutocapture)
    }

    func testApplyRuntimeDocumentType_passportWithoutExplicitAutocapture_succeeds() {
        // No prior useAutocapture call — the default flow.
        _ = sut.applyRuntimeDocumentType("passport")

        XCTAssertEqual(sut.documentType, "passport")
        XCTAssertFalse(sut.useAutocapture)
        XCTAssertFalse(sut.didExplicitlyEnableAutocapture)
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
