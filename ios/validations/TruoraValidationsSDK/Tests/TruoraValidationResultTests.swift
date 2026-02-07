//
//  TruoraValidationResultTests.swift
//  TruoraValidationsSDK
//
//  Created by Truora on 17/11/25.
//

import XCTest
@testable import TruoraValidationsSDK

@MainActor final class TruoraValidationResultTests: XCTestCase {
    // MARK: - Initialization Tests

    func testCompleteCase() {
        // Given
        let validationResult = ValidationResult(
            validationId: "test-id",
            status: .success,
            confidence: 0.95,
            metadata: nil
        )

        // When
        let result: TruoraValidationResult<ValidationResult> = .complete(validationResult)

        // Then
        XCTAssertTrue(result.isComplete, "Should be complete")
        XCTAssertFalse(result.isFailure, "Should not be failure")
        XCTAssertFalse(result.isCanceled, "Should not be canceled")
        XCTAssertEqual(result.completionValue?.validationId, "test-id", "Should have completion value")
    }

    func testFailureCase() {
        // Given
        let error = TruoraException.sdk(SDKError(type: .invalidConfiguration, details: "Test error"))

        // When
        let result: TruoraValidationResult<ValidationResult> = .failure(error, nil)

        // Then
        XCTAssertFalse(result.isComplete, "Should not be complete")
        XCTAssertTrue(result.isFailure, "Should be failure")
        XCTAssertFalse(result.isCanceled, "Should not be canceled")
        XCTAssertNotNil(result.error, "Should have error")
        XCTAssertNil(result.failureValue, "Should not have failure value")
    }

    func testFailureCaseWithPartialResult() {
        // Given
        let error = TruoraException.sdk(
            SDKError(type: .validationResultsTimedOut, details: "Timed out")
        )
        let partialResult = ValidationResult(
            validationId: "partial-id",
            status: .pending,
            confidence: nil,
            metadata: nil
        )

        // When
        let result: TruoraValidationResult<ValidationResult> = .failure(error, partialResult)

        // Then
        XCTAssertTrue(result.isFailure, "Should be failure")
        XCTAssertNotNil(result.error, "Should have error")
        XCTAssertNotNil(result.failureValue, "Should have failure value")
        XCTAssertEqual(
            result.failureValue?.validationId,
            "partial-id",
            "Should match partial result"
        )
    }

    // MARK: - Convenience Property Tests

    func testCompletionValueForComplete() {
        // Given
        let validationResult = ValidationResult(
            validationId: "test-id",
            status: .success,
            confidence: 0.95,
            metadata: nil
        )
        let result: TruoraValidationResult<ValidationResult> = .complete(validationResult)

        // When
        let value = result.completionValue

        // Then
        XCTAssertNotNil(value, "Should have completion value")
        XCTAssertEqual(
            value?.validationId,
            "test-id",
            "Should match validation result"
        )
    }

    func testCompletionValueForNonComplete() {
        // Given
        let result: TruoraValidationResult<ValidationResult> = .failure(
            .sdk(SDKError(type: .validationCanceledByUser)), nil
        )

        // When
        let value = result.completionValue

        // Then
        XCTAssertNil(value, "Should not have completion value")
    }

    func testErrorForFailure() {
        // Given
        let error = TruoraException.network(message: "Network failed", underlyingError: nil)
        let result: TruoraValidationResult<ValidationResult> = .failure(error, nil)

        // When
        let extractedError = result.error

        // Then
        XCTAssertNotNil(extractedError, "Should have error")
        if case .network(let message, _) = extractedError {
            XCTAssertEqual(message, "Network failed", "Should match error message")
        } else {
            XCTFail("Should be network error")
        }
    }

    func testErrorForNonFailure() {
        // Given
        let validationResult = ValidationResult(
            validationId: "test-id",
            status: .success,
            confidence: 0.95,
            metadata: nil
        )
        let result: TruoraValidationResult<ValidationResult> = .complete(validationResult)

        // When
        let error = result.error

        // Then
        XCTAssertNil(error, "Should not have error")
    }

    // MARK: - Equatable Tests

    func testEqualityForComplete() {
        // Given
        let result1 = ValidationResult(validationId: "id1", status: .success, confidence: 0.9, metadata: nil)
        let result2 = ValidationResult(validationId: "id1", status: .success, confidence: 0.9, metadata: nil)

        let validation1: TruoraValidationResult<ValidationResult> = .complete(result1)
        let validation2: TruoraValidationResult<ValidationResult> = .complete(result2)

        // Then
        XCTAssertEqual(validation1, validation2, "Should be equal for same completion values")
    }

    func testEqualityForFailure() {
        // Given - Create two separate instances with same error content
        let validation1: TruoraValidationResult<ValidationResult> = .failure(
            .sdk(SDKError(type: .validationCanceledByUser)), nil
        )
        let validation2: TruoraValidationResult<ValidationResult> = .failure(
            .sdk(SDKError(type: .validationCanceledByUser)), nil
        )

        // Then - Should be equal based on error content, not reference
        XCTAssertEqual(validation1, validation2, "Should be equal for same error content")
    }

    func testEqualityForFailureWithPartialResult() {
        // Given
        let partialResult = ValidationResult(
            validationId: "id",
            status: .pending,
            confidence: nil,
            metadata: nil
        )
        let validation1: TruoraValidationResult<ValidationResult> = .failure(
            .sdk(SDKError(type: .validationResultsTimedOut)), partialResult
        )
        let validation2: TruoraValidationResult<ValidationResult> = .failure(
            .sdk(SDKError(type: .validationResultsTimedOut)), partialResult
        )

        // Then
        XCTAssertEqual(
            validation1,
            validation2,
            "Should be equal for same error and partial result"
        )
    }

    func testInequalityBetweenDifferentCases() {
        // Given
        let validationResult = ValidationResult(validationId: "id", status: .success, confidence: 0.9, metadata: nil)
        let complete: TruoraValidationResult<ValidationResult> = .complete(validationResult)
        let failure: TruoraValidationResult<ValidationResult> = .failure(
            .sdk(SDKError(type: .validationCanceledByUser)), nil
        )
        let canceled: TruoraValidationResult<ValidationResult> = .canceled(nil)

        // Then
        XCTAssertNotEqual(complete, failure, "Complete should not equal failure")
        XCTAssertNotEqual(complete, canceled, "Complete should not equal canceled")
        XCTAssertNotEqual(failure, canceled, "Failure should not equal canceled")
    }

    // MARK: - CustomStringConvertible Tests

    func testDescriptionForComplete() {
        // Given
        let validationResult = ValidationResult(
            validationId: "test-id",
            status: .success,
            confidence: 0.9,
            metadata: nil
        )
        let result: TruoraValidationResult<ValidationResult> = .complete(validationResult)

        // When
        let description = result.description

        // Then
        XCTAssertTrue(description.contains("complete"), "Description should contain 'complete'")
    }

    func testDescriptionForFailure() {
        // Given
        let result: TruoraValidationResult<ValidationResult> = .failure(
            .sdk(SDKError(type: .validationCanceledByUser)), nil
        )

        // When
        let description = result.description

        // Then
        XCTAssertTrue(description.contains("failure"), "Description should contain 'failure'")
    }

    // MARK: - Canceled Tests

    func testIsCanceledForCanceled() {
        // Given
        let result: TruoraValidationResult<ValidationResult> = .canceled(nil)

        // When/Then
        XCTAssertTrue(result.isCanceled, "Should be canceled")
        XCTAssertFalse(result.isComplete, "Should not be complete")
        XCTAssertFalse(result.isFailure, "Should not be failure")
    }

    func testCanceledValueWithValue() {
        // Given
        let validationResult = ValidationResult(
            validationId: "partial-id",
            status: .pending,
            confidence: nil,
            metadata: nil
        )
        let result: TruoraValidationResult<ValidationResult> = .canceled(validationResult)

        // When
        let value = result.canceledValue

        // Then
        XCTAssertNotNil(value, "Should have canceled value")
        XCTAssertEqual(value?.validationId, "partial-id", "Should match validation id")
    }

    func testCanceledValueWithNil() {
        // Given
        let result: TruoraValidationResult<ValidationResult> = .canceled(nil)

        // When
        let value = result.canceledValue

        // Then
        XCTAssertNil(value, "Should not have canceled value")
    }

    func testEqualityForCanceled() {
        // Given
        let validation1: TruoraValidationResult<ValidationResult> = .canceled(nil)
        let validation2: TruoraValidationResult<ValidationResult> = .canceled(nil)

        // Then
        XCTAssertEqual(validation1, validation2, "Should be equal for same canceled values")
    }

    func testEqualityForCanceledWithValue() {
        // Given
        let validationResult = ValidationResult(validationId: "id", status: .pending, confidence: nil, metadata: nil)
        let validation1: TruoraValidationResult<ValidationResult> = .canceled(validationResult)
        let validation2: TruoraValidationResult<ValidationResult> = .canceled(validationResult)

        // Then
        XCTAssertEqual(validation1, validation2, "Should be equal for same canceled values")
    }

    func testDescriptionForCanceled() {
        // Given
        let result: TruoraValidationResult<ValidationResult> = .canceled(nil)

        // When
        let description = result.description

        // Then
        XCTAssertTrue(description.contains("canceled"), "Description should contain 'canceled'")
    }
}
