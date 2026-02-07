//
//  ValidationDetail.swift
//  TruoraValidationsSDK
//
//  Created by Truora on 05/02/26.
//

import Foundation

// MARK: - Validation Detail

/// Full validation detail returned by the Truora API after polling completes.
/// Contains the complete API response including validation inputs, user response,
/// and detailed results for face recognition, document validation, and background checks.
public struct ValidationDetail: Codable, Equatable {
    public let validationId: String
    public let type: String
    public let validationStatus: String
    public let failureStatus: String?
    public let creationDate: String
    public let accountId: String
    public let details: ValidationDetailInfo?
    public let validationInputs: ValidationDetailInputs?
    public let userResponse: ValidationDetailUserResponse?

    public init(
        validationId: String,
        type: String,
        validationStatus: String,
        failureStatus: String? = nil,
        creationDate: String,
        accountId: String,
        details: ValidationDetailInfo? = nil,
        validationInputs: ValidationDetailInputs? = nil,
        userResponse: ValidationDetailUserResponse? = nil
    ) {
        self.validationId = validationId
        self.type = type
        self.validationStatus = validationStatus
        self.failureStatus = failureStatus
        self.creationDate = creationDate
        self.accountId = accountId
        self.details = details
        self.validationInputs = validationInputs
        self.userResponse = userResponse
    }

    private enum CodingKeys: String, CodingKey {
        case validationId = "validation_id"
        case type
        case validationStatus = "validation_status"
        case failureStatus = "failure_status"
        case creationDate = "creation_date"
        case accountId = "account_id"
        case details
        case validationInputs = "validation_inputs"
        case userResponse = "user_response"
    }
}

// MARK: - Validation Detail Info

/// Contains the detailed results nested under the `details` key in the API response.
public struct ValidationDetailInfo: Codable, Equatable {
    public let faceRecognitionValidations: FaceRecognitionDetail?
    public let documentDetails: DocumentDetail?
    public let documentValidations: DocumentSubValidationResults?
    public let backgroundCheck: BackgroundCheckDetail?

    public init(
        faceRecognitionValidations: FaceRecognitionDetail? = nil,
        documentDetails: DocumentDetail? = nil,
        documentValidations: DocumentSubValidationResults? = nil,
        backgroundCheck: BackgroundCheckDetail? = nil
    ) {
        self.faceRecognitionValidations = faceRecognitionValidations
        self.documentDetails = documentDetails
        self.documentValidations = documentValidations
        self.backgroundCheck = backgroundCheck
    }

    private enum CodingKeys: String, CodingKey {
        case faceRecognitionValidations = "face_recognition_validations"
        case documentDetails = "document_details"
        case documentValidations = "document_validations"
        case backgroundCheck = "background_check"
    }
}

// MARK: - Face Recognition Detail

/// Detailed face recognition validation results.
public struct FaceRecognitionDetail: Codable, Equatable {
    public let confidenceScore: Double?
    public let similarityStatus: String?
    public let passiveLivenessStatus: String?
    public let enrollmentId: String?
    public let ageRange: AgeRangeDetail?
    public let faceSearch: FaceSearchDetail?

    public init(
        confidenceScore: Double? = nil,
        similarityStatus: String? = nil,
        passiveLivenessStatus: String? = nil,
        enrollmentId: String? = nil,
        ageRange: AgeRangeDetail? = nil,
        faceSearch: FaceSearchDetail? = nil
    ) {
        self.confidenceScore = confidenceScore
        self.similarityStatus = similarityStatus
        self.passiveLivenessStatus = passiveLivenessStatus
        self.enrollmentId = enrollmentId
        self.ageRange = ageRange
        self.faceSearch = faceSearch
    }

    private enum CodingKeys: String, CodingKey {
        case confidenceScore = "confidence_score"
        case similarityStatus = "similarity_status"
        case passiveLivenessStatus = "passive_liveness_status"
        case enrollmentId = "enrollment_id"
        case ageRange = "age_range"
        case faceSearch = "face_search"
    }
}

/// Age range estimated from face analysis.
public struct AgeRangeDetail: Codable, Equatable {
    public let high: Int?
    public let low: Int?

    public init(high: Int?, low: Int?) {
        self.high = high
        self.low = low
    }
}

/// Face search results from face recognition.
public struct FaceSearchDetail: Codable, Equatable {
    public let status: String?
    public let confidenceScore: Double?

    public init(status: String?, confidenceScore: Double?) {
        self.status = status
        self.confidenceScore = confidenceScore
    }

    private enum CodingKeys: String, CodingKey {
        case status
        case confidenceScore = "confidence_score"
    }
}

// MARK: - Document Detail

/// Extracted document data and image URLs from a document validation.
public struct DocumentDetail: Codable, Equatable {
    public let docId: String?
    public let country: String?
    public let documentType: String?
    public let documentNumber: String?
    public let name: String?
    public let lastName: String?
    public let dateOfBirth: String?
    public let gender: String?
    public let issueDate: String?
    public let expirationDate: String?
    public let expeditionPlace: String?
    public let birthPlace: String?
    public let height: String?
    public let rh: String?
    public let mimeType: String?
    public let clientId: String?
    public let creationDate: String?

    /// Presigned CloudFront URL to the document front image.
    /// This URL expires approximately 15 minutes after the API response.
    public let frontUrl: String?

    /// Presigned CloudFront URL to the document reverse image.
    /// This URL expires approximately 15 minutes after the API response.
    public let reverseUrl: String?

    // swiftlint:disable function_parameter_count
    public init(
        docId: String? = nil,
        country: String? = nil,
        documentType: String? = nil,
        documentNumber: String? = nil,
        name: String? = nil,
        lastName: String? = nil,
        dateOfBirth: String? = nil,
        gender: String? = nil,
        issueDate: String? = nil,
        expirationDate: String? = nil,
        expeditionPlace: String? = nil,
        birthPlace: String? = nil,
        height: String? = nil,
        rh: String? = nil,
        mimeType: String? = nil,
        clientId: String? = nil,
        creationDate: String? = nil,
        frontUrl: String? = nil,
        reverseUrl: String? = nil
    ) {
        self.docId = docId
        self.country = country
        self.documentType = documentType
        self.documentNumber = documentNumber
        self.name = name
        self.lastName = lastName
        self.dateOfBirth = dateOfBirth
        self.gender = gender
        self.issueDate = issueDate
        self.expirationDate = expirationDate
        self.expeditionPlace = expeditionPlace
        self.birthPlace = birthPlace
        self.height = height
        self.rh = rh
        self.mimeType = mimeType
        self.clientId = clientId
        self.creationDate = creationDate
        self.frontUrl = frontUrl
        self.reverseUrl = reverseUrl
    }

    // swiftlint:enable function_parameter_count

    private enum CodingKeys: String, CodingKey {
        case docId = "doc_id"
        case country
        case documentType = "document_type"
        case documentNumber = "document_number"
        case name
        case lastName = "last_name"
        case dateOfBirth = "date_of_birth"
        case gender
        case issueDate = "issue_date"
        case expirationDate = "expiration_date"
        case expeditionPlace = "expedition_place"
        case birthPlace = "birth_place"
        case height
        case rh
        case mimeType = "mime_type"
        case clientId = "client_id"
        case creationDate = "creation_date"
        case frontUrl = "front_url"
        case reverseUrl = "reverse_url"
    }
}

// MARK: - Document Sub-Validation Results

/// Results of document sub-validations (data consistency, government checks, etc.).
public struct DocumentSubValidationResults: Codable, Equatable {
    public let dataConsistency: [SubValidationDetail]?
    public let governmentDatabase: [SubValidationDetail]?
    public let imageAnalysis: [SubValidationDetail]?
    public let photocopyAnalysis: [SubValidationDetail]?
    public let manualAnalysis: [SubValidationDetail]?
    public let photoOfPhoto: [SubValidationDetail]?

    public init(
        dataConsistency: [SubValidationDetail]? = nil,
        governmentDatabase: [SubValidationDetail]? = nil,
        imageAnalysis: [SubValidationDetail]? = nil,
        photocopyAnalysis: [SubValidationDetail]? = nil,
        manualAnalysis: [SubValidationDetail]? = nil,
        photoOfPhoto: [SubValidationDetail]? = nil
    ) {
        self.dataConsistency = dataConsistency
        self.governmentDatabase = governmentDatabase
        self.imageAnalysis = imageAnalysis
        self.photocopyAnalysis = photocopyAnalysis
        self.manualAnalysis = manualAnalysis
        self.photoOfPhoto = photoOfPhoto
    }

    private enum CodingKeys: String, CodingKey {
        case dataConsistency = "data_consistency"
        case governmentDatabase = "government_database"
        case imageAnalysis = "image_analysis"
        case photocopyAnalysis = "photocopy_analysis"
        case manualAnalysis = "manual_analysis"
        case photoOfPhoto = "photo_of_photo"
    }
}

/// Individual sub-validation result entry.
/// All fields except `dataValidations` are optional to allow partial decoding
/// when the API omits fields, preventing a single missing field from causing
/// the entire validation detail to fail to decode.
public struct SubValidationDetail: Codable, Equatable {
    public let validationName: String?
    public let result: String?
    public let validationType: String?
    public let message: String?
    public let manuallyReviewed: Bool?
    public let createdAt: String?
    public let dataValidations: [String: String]?

    public init(
        validationName: String? = nil,
        result: String? = nil,
        validationType: String? = nil,
        message: String? = nil,
        manuallyReviewed: Bool? = nil,
        createdAt: String? = nil,
        dataValidations: [String: String]? = nil
    ) {
        self.validationName = validationName
        self.result = result
        self.validationType = validationType
        self.message = message
        self.manuallyReviewed = manuallyReviewed
        self.createdAt = createdAt
        self.dataValidations = dataValidations
    }

    private enum CodingKeys: String, CodingKey {
        case validationName = "validation_name"
        case result
        case validationType = "validation_type"
        case message
        case manuallyReviewed = "manually_reviewed"
        case createdAt = "created_at"
        case dataValidations = "data_validations"
    }
}

// MARK: - Background Check Detail

/// Background check results.
public struct BackgroundCheckDetail: Codable, Equatable {
    public let checkId: String?
    public let checkUrl: String?

    public init(checkId: String?, checkUrl: String?) {
        self.checkId = checkId
        self.checkUrl = checkUrl
    }

    private enum CodingKeys: String, CodingKey {
        case checkId = "check_id"
        case checkUrl = "check_url"
    }
}

// MARK: - Validation Inputs

/// Input parameters submitted with the validation (country, document type, etc.).
public struct ValidationDetailInputs: Codable, Equatable {
    public let country: String?
    public let documentType: String?

    public init(
        country: String? = nil,
        documentType: String? = nil
    ) {
        self.country = country
        self.documentType = documentType
    }

    private enum CodingKeys: String, CodingKey {
        case country
        case documentType = "document_type"
    }
}

// MARK: - User Response

/// User response data returned by the API.
public struct ValidationDetailUserResponse: Codable, Equatable {
    public let inputFiles: [String]?

    public init(inputFiles: [String]? = nil) {
        self.inputFiles = inputFiles
    }

    private enum CodingKeys: String, CodingKey {
        case inputFiles = "input_files"
    }
}
