//
//  DocumentIntroInteractor.swift
//  TruoraValidationsSDK
//
//  Created by Truora on 23/12/25.
//

import Foundation

class DocumentIntroInteractor {
    weak var presenter: DocumentIntroInteractorToPresenter?
    private var validationTask: Task<Void, Never>?
    private let country: String
    private let documentType: String
    private let createValidationHandler: ((NativeValidationRequest) async throws -> NativeValidationCreateResponse)?
    private let logger: TruoraLogger

    /// Constants for logging
    private static let viewName = "doc_intro"
    private static let validationType = "doc_validation"

    init(
        presenter: DocumentIntroInteractorToPresenter?,
        country: String,
        documentType: String,
        createValidationHandler: ((NativeValidationRequest) async throws -> NativeValidationCreateResponse)? = nil,
        logger: TruoraLogger
    ) {
        self.presenter = presenter
        self.country = country
        self.documentType = documentType
        self.createValidationHandler = createValidationHandler
        self.logger = logger
    }

    deinit {
        validationTask?.cancel()
    }
}

extension DocumentIntroInteractor: DocumentIntroPresenterToInteractor {
    func createValidation(accountId: String) {
        validationTask?.cancel()
        validationTask = Task {
            do {
                let response = try await performValidationRequest(accountId: accountId)
                guard !Task.isCancelled else {
                    print("⚠️ DocumentIntroInteractor: Task was cancelled")
                    return
                }
                await notifySuccess(response: response)
            } catch is CancellationError {
                print("⚠️ DocumentIntroInteractor: Task was cancelled")
            } catch {
                await notifyFailure(error: error)
            }
        }
    }

    // MARK: - Logging Methods

    func logViewRendered() async {
        await logger.logView(
            viewName: "render_\(Self.viewName)_succeeded",
            level: .info,
            retention: .oneWeek,
            metadata: [
                "name": Self.viewName,
                "validation_type": Self.validationType
            ]
        )
    }

    func logContinueButtonClicked() async {
        await logger.logView(
            viewName: "continue_button_clicked",
            level: .info,
            retention: .oneWeek,
            metadata: [
                "name": Self.viewName,
                "validation_type": Self.validationType,
                "selected_country": country,
                "selected_document": documentType
            ]
        )
    }

    func logCancelButtonClicked() async {
        await logger.logView(
            viewName: "cancel_button_clicked",
            level: .info,
            retention: .oneWeek,
            metadata: [
                "name": Self.viewName,
                "validation_type": Self.validationType
            ]
        )
    }
}

// MARK: - Private Helpers

private extension DocumentIntroInteractor {
    func buildRequest(accountId: String) -> NativeValidationRequest {
        NativeValidationRequest(
            type: NativeValidationTypeEnum.documentValidation.rawValue,
            country: country.lowercased(),
            accountId: accountId,
            threshold: nil,
            subvalidations: nil,
            documentType: documentType,
            timeout: nil,
            userAuthorized: true
        )
    }

    func performValidationRequest(accountId: String) async throws -> NativeValidationCreateResponse {
        let request = buildRequest(accountId: accountId)
        print("🟢 DocumentIntro: Creating validation for account: account=\(accountId)")
        print("🟢 DocumentIntro: country=\(country.lowercased()) documentType=\(documentType)")

        if let createValidationHandler {
            return try await createValidationHandler(request)
        }

        guard let apiClient = ValidationConfig.shared.apiClient else {
            throw TruoraException.sdk(SDKError(type: .invalidConfiguration, details: "API client not configured"))
        }

        return try await apiClient.createValidation(request: request)
    }

    func notifySuccess(response: NativeValidationCreateResponse) async {
        print("🟢 DocumentIntro: Validation created - ID: \(response.validationId)")
        guard let presenter else {
            print("⚠️ DocumentIntro: Presenter deallocated before result")
            return
        }
        await presenter.validationCreated(response: response)
    }

    func notifyFailure(error: Error) async {
        print("❌ DocumentIntro: Validation creation failed: \(error)")
        if let truoraError = error as? TruoraException {
            await presenter?.validationFailed(truoraError)
        } else {
            await presenter?.validationFailed(
                .network(message: "Failed to create validation: \(error.localizedDescription)")
            )
        }
    }
}
