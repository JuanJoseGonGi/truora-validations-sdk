//
//  FaceValidationConfigTests.swift
//  TruoraValidationsSDK
//
//  Created by Truora on 17/11/25.
//

import XCTest
@testable import TruoraValidationsSDK

@MainActor final class FaceValidationConfigTests: XCTestCase {
    var sut: Face!

    override func setUp() {
        super.setUp()
        sut = Face()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        // Then
        XCTAssertNil(sut.referenceFace, "Reference face should be nil by default")
        XCTAssertEqual(sut.similarityThreshold, 0.8, "Similarity threshold should default to 0.8")
        XCTAssertFalse(sut.waitForResults, "Should not wait for results by default")
        XCTAssertTrue(sut.useAutocapture, "Should use autocapture by default")
        XCTAssertEqual(sut.timeout, 60, "Timeout should default to 60 seconds")
    }

    // MARK: - Reference Face Tests

    func testUseReferenceFace() throws {
        // Given
        let referenceFace = try ReferenceFace.from("https://example.com/face.jpg")

        // When
        let result = sut.useReferenceFace(referenceFace)

        // Then
        XCTAssertNotNil(sut.referenceFace, "Should set reference face")
        XCTAssertTrue(result === sut, "Should return self for chaining")
    }

    // MARK: - Similarity Threshold Tests

    func testSetSimilarityThresholdWithValidValue() {
        // Given
        let threshold: Float = 0.85

        // When
        let result = sut.setSimilarityThreshold(threshold)

        // Then
        XCTAssertEqual(sut.similarityThreshold, threshold, "Should set similarity threshold")
        XCTAssertTrue(result === sut, "Should return self for chaining")
    }

    func testSetSimilarityThresholdWithMinValue() {
        // Given
        let threshold: Float = 0.0

        // When
        let result = sut.setSimilarityThreshold(threshold)

        // Then
        XCTAssertEqual(sut.similarityThreshold, threshold, "Should accept 0.0 as threshold")
        XCTAssertTrue(result === sut, "Should return self for chaining")
    }

    func testSetSimilarityThresholdWithMaxValue() {
        // Given
        let threshold: Float = 1.0

        // When
        let result = sut.setSimilarityThreshold(threshold)

        // Then
        XCTAssertEqual(sut.similarityThreshold, threshold, "Should accept 1.0 as threshold")
        XCTAssertTrue(result === sut, "Should return self for chaining")
    }

    func testSetSimilarityThresholdWithInvalidLowValue() {
        // Given
        let threshold: Float = -0.1

        // When
        let result = sut.setSimilarityThreshold(threshold)

        // Then - Should clamp to 0.0
        XCTAssertEqual(sut.similarityThreshold, 0.0, "Should clamp negative threshold to 0.0")
        XCTAssertTrue(result === sut, "Should return self for chaining")
    }

    func testSetSimilarityThresholdWithInvalidHighValue() {
        // Given
        let threshold: Float = 1.1

        // When
        let result = sut.setSimilarityThreshold(threshold)

        // Then - Should clamp to 1.0
        XCTAssertEqual(sut.similarityThreshold, 1.0, "Should clamp high threshold to 1.0")
        XCTAssertTrue(result === sut, "Should return self for chaining")
    }

    // MARK: - Wait For Results Tests

    func testWaitForResults() {
        // When
        let result = sut.waitForResults(false)

        // Then
        XCTAssertFalse(sut.waitForResults, "Should disable wait for results")
        XCTAssertTrue(result === sut, "Should return self for chaining")
    }

    func testWaitForResultsTrue() {
        // Given
        _ = sut.waitForResults(false)

        // When
        let result = sut.waitForResults(true)

        // Then
        XCTAssertTrue(sut.waitForResults, "Should enable wait for results")
        XCTAssertTrue(result === sut, "Should return self for chaining")
    }

    // MARK: - Autocapture Tests

    func testUseAutocapture() {
        // When
        let result = sut.useAutocapture(false)

        // Then
        XCTAssertFalse(sut.useAutocapture, "Should disable autocapture")
        XCTAssertTrue(result === sut, "Should return self for chaining")
    }

    func testUseAutocaptureTrue() {
        // Given
        _ = sut.useAutocapture(false)

        // When
        let result = sut.useAutocapture(true)

        // Then
        XCTAssertTrue(sut.useAutocapture, "Should enable autocapture")
        XCTAssertTrue(result === sut, "Should return self for chaining")
    }

    // MARK: - Timeout Tests

    func testSetTimeout() {
        // Given
        let timeout = 120

        // When
        let result = sut.setTimeout(timeout)

        // Then
        XCTAssertEqual(sut.timeout, timeout, "Should set timeout")
        XCTAssertTrue(result === sut, "Should return self for chaining")
    }

    func testSetTimeoutWithZero() {
        // Given
        let timeout = 0

        // When
        let result = sut.setTimeout(timeout)

        // Then
        XCTAssertEqual(sut.timeout, timeout, "Should accept 0 as timeout")
        XCTAssertTrue(result === sut, "Should return self for chaining")
    }

    func testSetTimeoutWithNegativeValue() {
        // Given
        let timeout = -1

        // When
        let result = sut.setTimeout(timeout)

        // Then - Should clamp to 0
        XCTAssertEqual(sut.timeout, 0, "Should clamp negative timeout to 0")
        XCTAssertTrue(result === sut, "Should return self for chaining")
    }

    // MARK: - Finish View Configuration Tests

    func testFinishViewConfigDefaultIsNil() {
        // Then
        XCTAssertNil(sut.finishViewConfig, "Finish view config should be nil by default")
    }

    func testSetFinishViewConfiguration() {
        // Given
        let config = FinishViewConfiguration(success: .show, failure: .hide)

        // When
        let result = sut.setFinishViewConfiguration(config)

        // Then
        XCTAssertNotNil(sut.finishViewConfig, "Should set finish view config")
        XCTAssertEqual(sut.finishViewConfig?.success, .show, "Success should be .show")
        XCTAssertEqual(sut.finishViewConfig?.failure, .hide, "Failure should be .hide")
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

    func testWaitForResultsTruePreservesFinishViewConfig() {
        // Given
        let config = FinishViewConfiguration(success: .hide, failure: .show)
        _ = sut.setFinishViewConfiguration(config)

        // When
        _ = sut.waitForResults(true)

        // Then
        XCTAssertNotNil(sut.finishViewConfig, "Should preserve finish view config")
        XCTAssertTrue(sut.waitForResults)
    }

    func testSetFinishViewConfigurationBothShow() {
        // When
        _ = sut.setFinishViewConfiguration(FinishViewConfiguration(success: .show, failure: .show))

        // Then
        XCTAssertEqual(sut.finishViewConfig?.success, .show)
        XCTAssertEqual(sut.finishViewConfig?.failure, .show)
    }

    func testSetFinishViewConfigurationBothHide() {
        // When
        _ = sut.setFinishViewConfiguration(FinishViewConfiguration(success: .hide, failure: .hide))

        // Then
        XCTAssertEqual(sut.finishViewConfig?.success, .hide)
        XCTAssertEqual(sut.finishViewConfig?.failure, .hide)
    }

    // MARK: - Method Chaining Tests

    func testMethodChaining() throws {
        // Given
        let referenceFace = try ReferenceFace.from("https://example.com/face.jpg")

        // When
        let result =
            sut
                .useReferenceFace(referenceFace)
                .setSimilarityThreshold(0.9)
                .useAutocapture(false)
                .waitForResults(false)
                .setTimeout(90)

        // Then
        XCTAssertTrue(result === sut, "Should support method chaining")
        XCTAssertNotNil(sut.referenceFace, "Should have set reference face")
        XCTAssertEqual(sut.similarityThreshold, 0.9, "Should have set similarity threshold")
        XCTAssertFalse(sut.useAutocapture, "Should have disabled autocapture")
        XCTAssertFalse(sut.waitForResults, "Should have disabled wait for results")
        XCTAssertEqual(sut.timeout, 90, "Should have set timeout")
    }

    func testMethodChainingWithFinishViewConfig() throws {
        // Given
        let referenceFace = try ReferenceFace.from("https://example.com/face.jpg")
        let finishConfig = FinishViewConfiguration(success: .hide, failure: .show)

        // When
        let result =
            sut
                .useReferenceFace(referenceFace)
                .setSimilarityThreshold(0.9)
                .setFinishViewConfiguration(finishConfig)
                .setTimeout(90)

        // Then
        XCTAssertTrue(result === sut, "Should support method chaining")
        XCTAssertNotNil(sut.finishViewConfig, "Should have set finish view config")
        XCTAssertTrue(sut.waitForResults, "Should have enabled wait for results")
        XCTAssertEqual(sut.timeout, 90, "Should have set timeout")
    }
}
