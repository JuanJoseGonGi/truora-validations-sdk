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
        _ = sut.enableWaitForResults(false)
        XCTAssertFalse(sut.shouldWaitForResults, "Precondition: wait for results disabled")

        // When
        _ = sut.setFinishViewConfiguration(FinishViewConfiguration(success: .hide, failure: .hide))

        // Then
        XCTAssertTrue(sut.shouldWaitForResults, "Should implicitly enable wait for results")
    }

    func testEnableWaitForResultsFalseWithoutFinishViewConfig_succeeds() {
        // When — disabling waitForResults without finishViewConfig is valid
        _ = sut.enableWaitForResults(false)

        // Then
        XCTAssertFalse(sut.shouldWaitForResults)
        XCTAssertNil(sut.finishViewConfig)
    }

    // Note: enableWaitForResults(false) after setFinishViewConfiguration
    // triggers a preconditionFailure, which cannot be tested with XCTest
    // since it terminates the process. The precondition protects against
    // developer misconfiguration at the call site.
    // ValidationConfig.setValidation also throws invalidConfiguration as a
    // defense-in-depth check, but that path is unreachable through the
    // public builder API since the precondition fires first.

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
        XCTAssertTrue(sut.shouldWaitForResults)
        XCTAssertEqual(sut.timeoutSeconds, 90)
    }
}
