//
//  ValidationConfigTests.swift
//  TruoraValidationsSDKTests
//
//  Created by Truora on 11/11/25.
//

import XCTest
@testable import TruoraValidationsSDK

@MainActor class ValidationConfigTests: XCTestCase {
    override func setUp() {
        super.setUp()
        ValidationConfig.shared.reset()
    }

    override func tearDown() {
        ValidationConfig.shared.reset()
        super.tearDown()
    }

    // MARK: - Configuration Tests

    func testConfigureWithValidAccountId() async throws {
        // Given
        let apiKey = "test-api-key"
        let accountId = "test-account-id"

        // When
        try await ValidationConfig.shared.configure(
            apiKey: apiKey,
            accountId: accountId
        )

        // Then
        XCTAssertNotNil(ValidationConfig.shared.apiClient)
        XCTAssertEqual(ValidationConfig.shared.accountId, accountId)
    }

    func testConfigureWithEmptyApiKeyThrowsError() async {
        // Given
        let emptyApiKey = ""
        let accountId = "test-account-id"

        // When/Then
        do {
            try await ValidationConfig.shared.configure(
                apiKey: emptyApiKey,
                accountId: accountId
            )
            XCTFail("Expected error to be thrown")
        } catch let error as TruoraException {
            guard case .sdk(let sdkError) = error,
                  sdkError.type == .invalidConfiguration else {
                XCTFail("Expected SDK invalidConfiguration error")
                return
            }
            XCTAssertNotNil(sdkError.details, "Error details should not be nil")
            XCTAssertTrue(
                sdkError.details?.contains("API key") == true,
                "Error details should mention 'API key'"
            )
        } catch {
            XCTFail("Expected TruoraException, got \(error)")
        }
    }

    func testConfigureWithEnrollmentDataAndEmptyAccountIdThrowsError() async {
        // Given
        let apiKey = "test-api-key"
        let enrollmentData = EnrollmentData(
            enrollmentId: "test-enrollment",
            accountId: "",
            uploadUrl: nil,
            createdAt: Date()
        )

        // When/Then
        do {
            try await ValidationConfig.shared.configure(
                apiKey: apiKey,
                enrollmentData: enrollmentData
            )
            XCTFail("Expected error to be thrown")
        } catch let error as TruoraException {
            guard case .sdk(let sdkError) = error,
                  sdkError.type == .invalidConfiguration else {
                XCTFail("Expected SDK invalidConfiguration error")
                return
            }
            XCTAssertNotNil(sdkError.details, "Error details should not be nil")
            XCTAssertTrue(
                sdkError.details?.contains("Account ID") == true,
                "Error details should mention 'Account ID'"
            )
        } catch {
            XCTFail("Expected TruoraException, got \(error)")
        }
    }

    func testResetClearsConfiguration() async throws {
        // Given
        let apiKey = "test-api-key"
        let accountId = "test-account-id"
        try await ValidationConfig.shared.configure(
            apiKey: apiKey,
            accountId: accountId
        )

        // When
        ValidationConfig.shared.reset()

        // Then
        XCTAssertNil(ValidationConfig.shared.apiClient)
        XCTAssertNil(ValidationConfig.shared.accountId)
        XCTAssertNil(ValidationConfig.shared.delegate)
        XCTAssertNil(ValidationConfig.shared.enrollmentData)
    }

    func testConfigureWithDelegateStoresDelegate() async throws {
        // Given
        let apiKey = "test-api-key"
        let accountId = "test-account-id"
        let mockDelegate = MockValidationDelegate()

        // When
        try await ValidationConfig.shared.configure(
            apiKey: apiKey,
            accountId: accountId,
            delegate: mockDelegate.closure
        )

        // Then
        XCTAssertNotNil(ValidationConfig.shared.delegate)
    }

    // MARK: - Passport Autocapture Validation Tests

    func testSetValidation_passportWithDefaultAutocapture_shouldSucceed() {
        // Given — Document with passport type, default autocapture (true).
        // The developer did NOT explicitly call useAutocapture(true), so
        // defense-in-depth should allow this (autocapture disabled at runtime).
        let document = Document()
            .setDocumentType("passport")

        // When/Then — should not throw (matches Android behavior)
        XCTAssertNoThrow(
            try ValidationConfig.shared.setValidation(.document(document))
        )
        XCTAssertEqual(ValidationConfig.shared.documentConfig.documentType, "passport")
    }

    // Note: The case where passport + explicit useAutocapture(true) reaches
    // validateAutocaptureConfig is unreachable through the public API because
    // preconditionFailure fires first in setDocumentType() or useAutocapture().
    // The defense-in-depth validation exists as a safety net for internal changes.

    func testSetValidation_passportWithAutocaptureDisabled_shouldSucceed() {
        // Given
        let document = Document()
            .setDocumentType("passport")
            .useAutocapture(false)

        // When/Then — should not throw
        XCTAssertNoThrow(
            try ValidationConfig.shared.setValidation(.document(document))
        )
        XCTAssertEqual(ValidationConfig.shared.documentConfig.documentType, "passport")
        XCTAssertFalse(ValidationConfig.shared.documentConfig.useAutocapture)
    }

    func testSetValidation_nonPassportWithAutocapture_shouldSucceed() {
        // Given
        let document = Document()
            .setDocumentType("national-id")
            .useAutocapture(true)

        // When/Then — should not throw
        XCTAssertNoThrow(
            try ValidationConfig.shared.setValidation(.document(document))
        )
        XCTAssertEqual(ValidationConfig.shared.documentConfig.documentType, "national-id")
        XCTAssertTrue(ValidationConfig.shared.documentConfig.useAutocapture)
    }

    func testSetValidation_documentWithNoType_shouldSucceed() {
        // Given — no document type set (user will select later)
        let document = Document()

        // When/Then — should not throw even though autocapture defaults to true
        XCTAssertNoThrow(
            try ValidationConfig.shared.setValidation(.document(document))
        )
    }
}

// MARK: - Test Helpers

@MainActor private class MockValidationDelegate {
    var completionCalled = false
    var failureCalled = false
    var cancellationCalled = false
    var lastResult: ValidationResult?
    var lastError: TruoraException?

    var closure: (TruoraValidationResult<ValidationResult>) -> Void {
        { [unowned self] result in
            switch result {
            case .completed(let validationResult):
                self.completionCalled = true
                self.lastResult = validationResult
            case .error(let err):
                self.failureCalled = true
                self.lastError = err
            case .canceled:
                self.cancellationCalled = true
            }
        }
    }
}
