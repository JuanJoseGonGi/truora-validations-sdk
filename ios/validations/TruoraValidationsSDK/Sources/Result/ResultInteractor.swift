//
//  ResultInteractor.swift
//  TruoraValidationsSDK
//
//  Created by Truora on 21/12/25.
//

import Foundation

final class ResultInteractor {
    weak var presenter: ResultInteractorToPresenter?

    let validationId: String
    private let loadingType: ResultLoadingType
    private var pollingTask: Task<Void, Never>?
    private let timeProvider: TimeProvider
    private let logger: TruoraLogger

    /// Constants for logging
    private static let viewName = "result"

    init(
        validationId: String,
        loadingType: ResultLoadingType = .face,
        timeProvider: TimeProvider = RealTimeProvider(),
        logger: TruoraLogger
    ) {
        self.validationId = validationId
        self.loadingType = loadingType
        self.timeProvider = timeProvider
        self.logger = logger
    }

    deinit {
        pollingTask?.cancel()
    }
}

// MARK: - ResultPresenterToInteractor

extension ResultInteractor: ResultPresenterToInteractor {
    func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            await self?.performPolling()
        }
    }

    func cancelPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    // MARK: - Logging Methods

    func logViewRendered() async {
        await logger.logView(
            viewName: "render_\(Self.viewName)_succeeded",
            level: .info,
            retention: .oneWeek,
            metadata: [
                "name": Self.viewName
            ]
        )
    }

    func logSdkExecutionFinished() async {
        let validationType = loadingType == .face
            ? "face_validation" : "doc_validation"
        await logger.logSdk(
            eventName: "sdk_execution_finished",
            level: .info,
            errorMessage: nil,
            retention: .oneMonth,
            metadata: [
                "\(validationType)_id": validationId
            ]
        )
    }
}

// MARK: - Private Methods

private extension ResultInteractor {
    func getBackoffIntervals() -> [UInt64] {
        // Exponential-ish backoff: 1s, 2s, 4s, 8s, then 10s, 12s intervals (max ~68s total)
        [
            1_000_000_000, // 1s
            2_000_000_000, // 2s
            4_000_000_000, // 4s
            8_000_000_000, // 8s
            8_000_000_000, // 8s
            8_000_000_000, // 8s
            8_000_000_000, // 8s
            8_000_000_000, // 8s
            10_000_000_000, // 10s
            12_000_000_000 // 12s
        ]
    }

    func shouldReturnResult(for validationDetail: NativeValidationDetailResponse) -> Bool {
        // Stop polling if validation_status is not pending OR if failure_status is set
        validationDetail.validationStatus.lowercased() != "pending"
            || validationDetail.failureStatus != nil
    }

    func fetchValidationDetail(
        apiClient: TruoraAPIClient
    ) async throws -> NativeValidationDetailResponse {
        try await apiClient.getValidation(validationId: validationId)
    }

    func performPolling() async {
        guard let apiClient = ValidationConfig.shared.apiClient else {
            let details = "API client not configured"
            await presenter?.pollingFailed(
                error: .sdk(SDKError(type: .invalidConfiguration, details: details))
            )
            return
        }

        do {
            let result = try await pollForResult(apiClient: apiClient)

            // Check cancellation before notifying presenter to avoid UI updates after navigation
            guard !Task.isCancelled else {
                print("⚠️ ResultInteractor: Polling task was cancelled after completion")
                return
            }

            await presenter?.pollingCompleted(result: result)
        } catch is CancellationError {
            print("⚠️ ResultInteractor: Polling task was cancelled")
        } catch let error as TruoraException {
            guard !Task.isCancelled else { return }
            await presenter?.pollingFailed(error: error)
        } catch let error as DecodingError {
            // JSON parsing errors
            guard !Task.isCancelled else { return }
            await presenter?.pollingFailed(
                error: .sdk(
                    SDKError(
                        type: .internalError,
                        details: "Failed to parse server response: \(error.localizedDescription)"
                    )
                )
            )
        } catch {
            // Network and other errors
            guard !Task.isCancelled else { return }
            await presenter?.pollingFailed(
                error: .network(message: "API request failed: \(error.localizedDescription)")
            )
        }
    }

    func pollForResult(apiClient: TruoraAPIClient) async throws -> ValidationResult {
        let backoffIntervals = getBackoffIntervals()

        if loadingType == .document {
            try await timeProvider.sleep(nanoseconds: 1_000_000_000) // 1s
        }

        for (attempt, interval) in backoffIntervals.enumerated() {
            guard !Task.isCancelled else {
                throw CancellationError()
            }

            print("🟢 ResultInteractor: Polling attempt \(attempt + 1)/\(backoffIntervals.count)...")

            do {
                let validationDetail = try await fetchValidationDetail(apiClient: apiClient)
                if shouldReturnResult(for: validationDetail) {
                    return createValidationResult(from: validationDetail)
                }
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                // On last attempt, propagate the error; otherwise log and retry
                if attempt == backoffIntervals.count - 1 {
                    throw error
                }
                let errorMsg = error.localizedDescription
                let retryNum = attempt + 1
                let log = "⚠️ ResultInteractor: Transient error on attempt "
                    + "\(retryNum), retrying: \(errorMsg)"
                print(log)
            }

            // Sleep throws CancellationError if task is cancelled, which is expected behavior
            if attempt < backoffIntervals.count - 1 {
                try await timeProvider.sleep(nanoseconds: interval)
            }
        }

        print("❌ ResultInteractor: Polling timeout after \(backoffIntervals.count) attempts")
        throw TruoraException.sdk(
            SDKError(
                type: .validationResultsTimedOut,
                details: "Validation processing timeout. Please check back later."
            )
        )
    }

    func createValidationResult(
        from validationDetail: NativeValidationDetailResponse
    ) -> ValidationResult {
        // If failure_status is present, treat as failed regardless of validation_status
        let status: ValidationStatus = if validationDetail.failureStatus != nil {
            .failure
        } else {
            switch validationDetail.validationStatus.lowercased() {
            case "success":
                .success
            case "failed", "failure":
                .failure
            default:
                .pending
            }
        }

        let confidence = validationDetail.details?.faceRecognitionValidations?.confidenceScore
        let detail = mapToValidationDetail(from: validationDetail)

        return ValidationResult(
            validationId: validationDetail.validationId,
            status: status,
            confidence: confidence,
            metadata: nil,
            detail: detail
        )
    }

    // MARK: - Detail Mapping

    func mapToValidationDetail(
        from response: NativeValidationDetailResponse
    ) -> ValidationDetail {
        ValidationDetail(
            validationId: response.validationId,
            type: response.type,
            validationStatus: response.validationStatus,
            failureStatus: response.failureStatus,
            creationDate: response.creationDate,
            accountId: response.accountId,
            details: mapDetailInfo(from: response.details),
            validationInputs: mapInputs(from: response.validationInputs),
            userResponse: mapUserResponse(from: response.userResponse)
        )
    }

    func mapDetailInfo(
        from details: NativeValidationDetails?
    ) -> ValidationDetailInfo? {
        guard let details else { return nil }
        return ValidationDetailInfo(
            faceRecognitionValidations: mapFaceRecognition(
                from: details.faceRecognitionValidations
            ),
            documentDetails: mapDocumentDetails(from: details.documentDetails),
            documentValidations: mapDocumentValidations(
                from: details.documentValidations
            ),
            backgroundCheck: mapBackgroundCheck(from: details.backgroundCheck)
        )
    }

    func mapFaceRecognition(
        from face: NativeFaceRecognitionValidations?
    ) -> FaceRecognitionDetail? {
        guard let face else { return nil }
        return FaceRecognitionDetail(
            confidenceScore: face.confidenceScore,
            similarityStatus: face.similarityStatus,
            passiveLivenessStatus: face.passiveLivenessStatus,
            enrollmentId: face.enrollmentId,
            ageRange: face.ageRange.map {
                AgeRangeDetail(high: $0.high, low: $0.low)
            },
            faceSearch: face.faceSearch.map {
                FaceSearchDetail(
                    status: $0.status,
                    confidenceScore: $0.confidenceScore
                )
            }
        )
    }

    func mapDocumentDetails(
        from doc: NativeDocumentDetails?
    ) -> DocumentDetail? {
        guard let doc else { return nil }
        return DocumentDetail(
            docId: doc.docId,
            country: doc.country,
            documentType: doc.documentType,
            documentNumber: doc.documentNumber,
            name: doc.name,
            lastName: doc.lastName,
            dateOfBirth: doc.dateOfBirth,
            gender: doc.gender,
            issueDate: doc.issueDate,
            expirationDate: doc.expirationDate,
            expeditionPlace: doc.expeditionPlace,
            birthPlace: doc.birthPlace,
            height: doc.height,
            rh: doc.rh,
            mimeType: doc.mimeType,
            clientId: doc.clientId,
            creationDate: doc.creationDate,
            frontUrl: doc.frontUrl,
            reverseUrl: doc.reverseUrl
        )
    }

    func mapDocumentValidations(
        from validations: NativeDocumentSubValidations?
    ) -> DocumentSubValidationResults? {
        guard let validations else { return nil }
        return DocumentSubValidationResults(
            dataConsistency: validations.dataConsistency?.map(mapSubResult),
            governmentDatabase: validations.governmentDatabase?.map(mapSubResult),
            imageAnalysis: validations.imageAnalysis?.map(mapSubResult),
            photocopyAnalysis: validations.photocopyAnalysis?.map(mapSubResult),
            manualAnalysis: validations.manualAnalysis?.map(mapSubResult),
            photoOfPhoto: validations.photoOfPhoto?.map(mapSubResult)
        )
    }

    func mapSubResult(
        from result: NativeSubValidationResult
    ) -> SubValidationDetail {
        SubValidationDetail(
            validationName: result.validationName,
            result: result.result,
            validationType: result.validationType,
            message: result.message,
            manuallyReviewed: result.manuallyReviewed,
            createdAt: result.createdAt,
            dataValidations: result.dataValidations
        )
    }

    func mapBackgroundCheck(
        from check: NativeBackgroundCheck?
    ) -> BackgroundCheckDetail? {
        guard let check else { return nil }
        return BackgroundCheckDetail(
            checkId: check.checkId,
            checkUrl: check.checkUrl
        )
    }

    func mapInputs(
        from inputs: NativeValidationInputs?
    ) -> ValidationDetailInputs? {
        guard let inputs else { return nil }
        return ValidationDetailInputs(
            country: inputs.country,
            documentType: inputs.documentType
        )
    }

    func mapUserResponse(
        from response: NativeUserResponse?
    ) -> ValidationDetailUserResponse? {
        guard let response else { return nil }
        return ValidationDetailUserResponse(
            inputFiles: response.inputFiles
        )
    }
}
