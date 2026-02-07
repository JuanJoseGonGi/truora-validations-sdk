//
//  ValidationResultHelperTests.swift
//  TruoraValidationsSDK
//
//  Created by Truora on 05/02/26.
//

import XCTest
@testable import TruoraValidationsSDK

final class ValidationResultHelperTests: XCTestCase {
    // MARK: - getFaceReferenceImage Tests

    func testGetFaceReferenceImage_returnsUrl_whenDocumentDetailHasFrontUrl() {
        // Given
        let expectedUrl = "https://cdn.example.com/doc_front.png?sig=abc"
        let result = createResult(frontUrl: expectedUrl)

        // When
        let url = result.getFaceReferenceImage()

        // Then
        XCTAssertEqual(url, expectedUrl)
    }

    func testGetFaceReferenceImage_returnsNil_whenNoDetail() {
        // Given
        let result = ValidationResult(
            validationId: "VLD-123",
            status: .success
        )

        // When
        let url = result.getFaceReferenceImage()

        // Then
        XCTAssertNil(url, "Should return nil when detail is nil")
    }

    func testGetFaceReferenceImage_returnsNil_whenNoDetails() {
        // Given
        let detail = ValidationDetail(
            validationId: "VLD-123",
            type: "document-validation",
            validationStatus: "success",
            creationDate: "2026-01-30T00:00:00Z",
            accountId: "ACC-123",
            details: nil
        )
        let result = ValidationResult(
            validationId: "VLD-123",
            status: .success,
            detail: detail
        )

        // When
        let url = result.getFaceReferenceImage()

        // Then
        XCTAssertNil(url, "Should return nil when details is nil")
    }

    func testGetFaceReferenceImage_returnsNil_whenNoDocumentDetails() {
        // Given
        let detailInfo = ValidationDetailInfo(
            faceRecognitionValidations: FaceRecognitionDetail(
                confidenceScore: 0.95
            )
        )
        let detail = ValidationDetail(
            validationId: "VLD-123",
            type: "face-recognition",
            validationStatus: "success",
            creationDate: "2026-01-30T00:00:00Z",
            accountId: "ACC-123",
            details: detailInfo
        )
        let result = ValidationResult(
            validationId: "VLD-123",
            status: .success,
            detail: detail
        )

        // When
        let url = result.getFaceReferenceImage()

        // Then
        XCTAssertNil(url, "Should return nil for face-type validations")
    }

    func testGetFaceReferenceImage_returnsNil_whenNoFrontUrlAndNoInputFiles() {
        // Given
        let result = createResult(frontUrl: nil)

        // When
        let url = result.getFaceReferenceImage()

        // Then
        XCTAssertNil(url, "Should return nil when frontUrl is nil and no input files")
    }

    func testGetFaceReferenceImage_fallsBackToInputFiles_whenFrontUrlIsNil() {
        // Given — no frontUrl in documentDetails, but user_response has _front file
        let frontFileUrl = "https://s3.example.com/doc_front.png?sig=abc"
        let reverseFileUrl = "https://s3.example.com/doc_reverse.png?sig=def"
        let faceFileUrl = "https://s3.example.com/doc_face.png?sig=ghi"
        let result = createResultWithInputFiles(
            frontUrl: nil,
            inputFiles: [frontFileUrl, reverseFileUrl, faceFileUrl]
        )

        // When
        let url = result.getFaceReferenceImage()

        // Then
        XCTAssertEqual(url, frontFileUrl)
    }

    func testGetFaceReferenceImage_prefersFrontUrl_overInputFiles() {
        // Given — both frontUrl and input files present
        let directFrontUrl = "https://cdn.example.com/direct_front.png"
        let inputFileFrontUrl = "https://s3.example.com/doc_front.png?sig=abc"
        let result = createResultWithInputFiles(
            frontUrl: directFrontUrl,
            inputFiles: [inputFileFrontUrl]
        )

        // When
        let url = result.getFaceReferenceImage()

        // Then
        XCTAssertEqual(url, directFrontUrl, "Should prefer documentDetails.frontUrl")
    }

    func testGetFaceReferenceImage_returnsNil_whenInputFilesHaveNoFront() {
        // Given — no frontUrl, input files exist but none contain _front
        let result = createResultWithInputFiles(
            frontUrl: nil,
            inputFiles: [
                "https://s3.example.com/doc_reverse.png",
                "https://s3.example.com/doc_face.png"
            ]
        )

        // When
        let url = result.getFaceReferenceImage()

        // Then
        XCTAssertNil(url, "Should return nil when no input file contains _front")
    }

    // MARK: - ValidationDetail Mapping Tests

    func testValidationDetail_preservesAllTopLevelFields() {
        // Given
        let detail = ValidationDetail(
            validationId: "VLD-456",
            type: "document-validation",
            validationStatus: "success",
            failureStatus: "expired",
            creationDate: "2026-02-05T12:00:00Z",
            accountId: "ACC-789"
        )

        // Then
        XCTAssertEqual(detail.validationId, "VLD-456")
        XCTAssertEqual(detail.type, "document-validation")
        XCTAssertEqual(detail.validationStatus, "success")
        XCTAssertEqual(detail.failureStatus, "expired")
        XCTAssertEqual(detail.creationDate, "2026-02-05T12:00:00Z")
        XCTAssertEqual(detail.accountId, "ACC-789")
    }

    func testValidationDetail_documentDetailPreservesFrontAndReverseUrls() {
        // Given
        let frontUrl = "https://cdn.example.com/front.png"
        let reverseUrl = "https://cdn.example.com/reverse.png"
        let docDetail = DocumentDetail(
            country: "CO",
            documentType: "national-id",
            name: "John",
            frontUrl: frontUrl,
            reverseUrl: reverseUrl
        )

        // Then
        XCTAssertEqual(docDetail.frontUrl, frontUrl)
        XCTAssertEqual(docDetail.reverseUrl, reverseUrl)
        XCTAssertEqual(docDetail.country, "CO")
        XCTAssertEqual(docDetail.name, "John")
    }

    func testValidationDetail_faceRecognitionPreservesAllFields() {
        // Given
        let face = FaceRecognitionDetail(
            confidenceScore: 0.95,
            similarityStatus: "match",
            passiveLivenessStatus: "success",
            enrollmentId: "ENR-123",
            ageRange: AgeRangeDetail(high: 35, low: 25),
            faceSearch: FaceSearchDetail(status: "found", confidenceScore: 0.98)
        )

        // Then
        XCTAssertEqual(face.confidenceScore, 0.95)
        XCTAssertEqual(face.similarityStatus, "match")
        XCTAssertEqual(face.passiveLivenessStatus, "success")
        XCTAssertEqual(face.enrollmentId, "ENR-123")
        XCTAssertEqual(face.ageRange?.high, 35)
        XCTAssertEqual(face.ageRange?.low, 25)
        XCTAssertEqual(face.faceSearch?.status, "found")
        XCTAssertEqual(face.faceSearch?.confidenceScore, 0.98)
    }

    func testValidationDetail_validationInputsPreservesFields() {
        // Given
        let inputs = ValidationDetailInputs(
            country: "CO",
            documentType: "national-id"
        )

        // Then
        XCTAssertEqual(inputs.country, "CO")
        XCTAssertEqual(inputs.documentType, "national-id")
    }

    func testValidationDetail_userResponsePreservesFiles() {
        // Given
        let files = ["https://s3.example.com/upload1.jpg"]
        let response = ValidationDetailUserResponse(inputFiles: files)

        // Then
        XCTAssertEqual(response.inputFiles, files)
    }

    func testValidationDetail_backgroundCheckPreservesFields() {
        // Given
        let check = BackgroundCheckDetail(
            checkId: "BCK-123",
            checkUrl: "https://checks.example.com/BCK-123"
        )

        // Then
        XCTAssertEqual(check.checkId, "BCK-123")
        XCTAssertEqual(check.checkUrl, "https://checks.example.com/BCK-123")
    }

    // MARK: - Helper Methods

    private func createResult(frontUrl: String?) -> ValidationResult {
        let docDetail = DocumentDetail(
            country: "CO",
            documentType: "national-id",
            frontUrl: frontUrl
        )
        let detailInfo = ValidationDetailInfo(documentDetails: docDetail)
        let detail = ValidationDetail(
            validationId: "VLD-123",
            type: "document-validation",
            validationStatus: "success",
            creationDate: "2026-01-30T00:00:00Z",
            accountId: "ACC-123",
            details: detailInfo
        )
        return ValidationResult(
            validationId: "VLD-123",
            status: .success,
            detail: detail
        )
    }

    private func createResultWithInputFiles(
        frontUrl: String?,
        inputFiles: [String]
    ) -> ValidationResult {
        let docDetail = DocumentDetail(
            country: "CO",
            documentType: "national-id",
            frontUrl: frontUrl
        )
        let detailInfo = ValidationDetailInfo(documentDetails: docDetail)
        let userResponse = ValidationDetailUserResponse(inputFiles: inputFiles)
        let detail = ValidationDetail(
            validationId: "VLD-123",
            type: "document-validation",
            validationStatus: "success",
            creationDate: "2026-01-30T00:00:00Z",
            accountId: "ACC-123",
            details: detailInfo,
            userResponse: userResponse
        )
        return ValidationResult(
            validationId: "VLD-123",
            status: .success,
            detail: detail
        )
    }
}
