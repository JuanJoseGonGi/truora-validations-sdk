//
//  DocumentCaptureConfiguratorTests.swift
//  TruoraValidationsSDK
//
//  Created by Truora on 13/02/26.
//

import XCTest
@testable import TruoraValidationsSDK

final class DocumentCaptureConfiguratorTests: XCTestCase {
    // MARK: - resolveAutocapture Tests

    func testResolveAutocapture_passportWithDefaultAutocapture_returnsFalse() {
        // Given — passport type with default autocapture (true)
        let document = Document().setDocumentType("passport")

        // When
        let result = DocumentCaptureConfigurator.resolveAutocapture(from: document)

        // Then
        XCTAssertFalse(result, "Autocapture should be disabled for passport")
    }

    func testResolveAutocapture_passportWithAutocaptureDisabled_returnsFalse() {
        // Given
        let document = Document()
            .setDocumentType("passport")
            .useAutocapture(false)

        // When
        let result = DocumentCaptureConfigurator.resolveAutocapture(from: document)

        // Then
        XCTAssertFalse(result, "Autocapture should remain disabled for passport")
    }

    func testResolveAutocapture_nationalIdWithDefaultAutocapture_returnsTrue() {
        // Given
        let document = Document().setDocumentType("national-id")

        // When
        let result = DocumentCaptureConfigurator.resolveAutocapture(from: document)

        // Then
        XCTAssertTrue(result, "Autocapture should be enabled for national-id")
    }

    func testResolveAutocapture_nationalIdWithAutocaptureDisabled_returnsFalse() {
        // Given
        let document = Document()
            .setDocumentType("national-id")
            .useAutocapture(false)

        // When
        let result = DocumentCaptureConfigurator.resolveAutocapture(from: document)

        // Then
        XCTAssertFalse(
            result,
            "Autocapture should be disabled when explicitly turned off"
        )
    }

    func testResolveAutocapture_driverLicenseWithDefaultAutocapture_returnsTrue() {
        // Given
        let document = Document().setDocumentType("driver-license")

        // When
        let result = DocumentCaptureConfigurator.resolveAutocapture(from: document)

        // Then
        XCTAssertTrue(result, "Autocapture should be enabled for driver-license")
    }

    func testResolveAutocapture_noDocumentType_returnsTrue() {
        // Given — no document type set (user will select later)
        let document = Document()

        // When
        let result = DocumentCaptureConfigurator.resolveAutocapture(from: document)

        // Then
        XCTAssertTrue(
            result,
            "Autocapture should default to true when no document type set"
        )
    }
}
