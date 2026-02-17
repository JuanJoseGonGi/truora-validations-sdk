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

    func testCompletedCase() {
        // Given
        let validationResult = ValidationResult(
            validationId: "test-id",
            status: .success,
            confidence: 0.95,
            metadata: nil
        )

        // When
        let result: TruoraValidationResult<ValidationResult> = .completed(validationResult)

        // Then
        XCTAssertTrue(result.isCompleted, "Should be completed")
        XCTAssertFalse(result.isError, "Should not be error")
        XCTAssertFalse(result.isCanceled, "Should not be canceled")
        XCTAssertEqual(result.completionValue?.validationId, "test-id", "Should have completion value")
    }

    func testErrorCase() {
        // Given
        let error = TruoraException.sdk(SDKError(type: .invalidConfiguration, details: "Test error"))

        // When
        let result: TruoraValidationResult<ValidationResult> = .error(error)

        // Then
        XCTAssertFalse(result.isCompleted, "Should not be completed")
        XCTAssertTrue(result.isError, "Should be error")
        XCTAssertFalse(result.isCanceled, "Should not be canceled")
        XCTAssertNotNil(result.exception, "Should have exception")
    }

    // MARK: - Convenience Property Tests

    func testCompletionValueForCompleted() {
        // Given
        let validationResult = ValidationResult(
            validationId: "test-id",
            status: .success,
            confidence: 0.95,
            metadata: nil
        )
        let result: TruoraValidationResult<ValidationResult> = .completed(validationResult)

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

    func testCompletionValueForNonCompleted() {
        // Given
        let result: TruoraValidationResult<ValidationResult> = .error(
            .sdk(SDKError(type: .validationCanceledByUser))
        )

        // When
        let value = result.completionValue

        // Then
        XCTAssertNil(value, "Should not have completion value")
    }

    func testExceptionForError() {
        // Given
        let error = TruoraException.network(message: "Network failed", underlyingError: nil)
        let result: TruoraValidationResult<ValidationResult> = .error(error)

        // When
        let extractedError = result.exception

        // Then
        XCTAssertNotNil(extractedError, "Should have exception")
        if case .network(let message, _) = extractedError {
            XCTAssertEqual(message, "Network failed", "Should match error message")
        } else {
            XCTFail("Should be network error")
        }
    }

    func testExceptionForNonError() {
        // Given
        let validationResult = ValidationResult(
            validationId: "test-id",
            status: .success,
            confidence: 0.95,
            metadata: nil
        )
        let result: TruoraValidationResult<ValidationResult> = .completed(validationResult)

        // When
        let error = result.exception

        // Then
        XCTAssertNil(error, "Should not have exception")
    }

    // MARK: - Equatable Tests

    func testEqualityForCompleted() {
        // Given
        let result1 = ValidationResult(validationId: "id1", status: .success, confidence: 0.9, metadata: nil)
        let result2 = ValidationResult(validationId: "id1", status: .success, confidence: 0.9, metadata: nil)

        let validation1: TruoraValidationResult<ValidationResult> = .completed(result1)
        let validation2: TruoraValidationResult<ValidationResult> = .completed(result2)

        // Then
        XCTAssertEqual(validation1, validation2, "Should be equal for same completion values")
    }

    func testEqualityForError() {
        // Given - Create two separate instances with same error content
        let validation1: TruoraValidationResult<ValidationResult> = .error(
            .sdk(SDKError(type: .validationCanceledByUser))
        )
        let validation2: TruoraValidationResult<ValidationResult> = .error(
            .sdk(SDKError(type: .validationCanceledByUser))
        )

        // Then - Should be equal based on error content, not reference
        XCTAssertEqual(validation1, validation2, "Should be equal for same error content")
    }

    func testInequalityBetweenDifferentCases() {
        // Given
        let validationResult = ValidationResult(validationId: "id", status: .success, confidence: 0.9, metadata: nil)
        let completed: TruoraValidationResult<ValidationResult> = .completed(validationResult)
        let error: TruoraValidationResult<ValidationResult> = .error(
            .sdk(SDKError(type: .validationCanceledByUser))
        )
        let canceled: TruoraValidationResult<ValidationResult> = .canceled(nil)

        // Then
        XCTAssertNotEqual(completed, error, "Completed should not equal error")
        XCTAssertNotEqual(completed, canceled, "Completed should not equal canceled")
        XCTAssertNotEqual(error, canceled, "Error should not equal canceled")
    }

    // MARK: - CustomStringConvertible Tests

    func testDescriptionForCompleted() {
        // Given
        let validationResult = ValidationResult(
            validationId: "test-id",
            status: .success,
            confidence: 0.9,
            metadata: nil
        )
        let result: TruoraValidationResult<ValidationResult> = .completed(validationResult)

        // When
        let description = result.description

        // Then
        XCTAssertTrue(description.contains("completed"), "Description should contain 'completed'")
    }

    func testDescriptionForError() {
        // Given
        let result: TruoraValidationResult<ValidationResult> = .error(
            .sdk(SDKError(type: .validationCanceledByUser))
        )

        // When
        let description = result.description

        // Then
        XCTAssertTrue(description.contains("error"), "Description should contain 'error'")
    }

    // MARK: - Canceled Tests

    func testIsCanceledForCanceled() {
        // Given
        let result: TruoraValidationResult<ValidationResult> = .canceled(nil)

        // When/Then
        XCTAssertTrue(result.isCanceled, "Should be canceled")
        XCTAssertFalse(result.isCompleted, "Should not be completed")
        XCTAssertFalse(result.isError, "Should not be error")
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
