//
//  PassiveIntroPresenter.swift
//  TruoraValidationsSDK
//
//  Created by Truora on 31/10/25.
//

import Foundation

class PassiveIntroPresenter {
    weak var view: PassiveIntroPresenterToView?
    var interactor: PassiveIntroPresenterToInteractor?
    weak var router: ValidationRouter?
    private var validationTask: Task<Void, Never>?

    init(
        view: PassiveIntroPresenterToView,
        interactor: PassiveIntroPresenterToInteractor?,
        router: ValidationRouter
    ) {
        self.view = view
        self.interactor = interactor
        self.router = router
    }

    deinit {
        validationTask?.cancel()
    }
}

extension PassiveIntroPresenter: PassiveIntroViewToPresenter {
    func viewDidLoad() async {
        // Log view rendered
        await interactor?.logViewRendered()
    }

    func startTapped() async {
        // Log continue button clicked
        await interactor?.logContinueButtonClicked()

        guard let accountId = ValidationConfig.shared.accountId else {
            await view?.showError("Missing account ID")
            return
        }

        guard let interactor else {
            await view?.showError("Interactor not configured")
            return
        }

        await view?.showLoading()

        do {
            try await interactor.enrollmentCompleted()
            interactor.createValidation(accountId: accountId)
        } catch is CancellationError {
            // Task was cancelled - hide loading and exit gracefully
            print("⚠️ PassiveIntroPresenter: Enrollment was cancelled")
            await view?.hideLoading()
        } catch {
            print("❌ PassiveIntroPresenter: Enrollment failed: \(error)")
            await view?.hideLoading()
            if let truoraError = error as? TruoraException {
                await router?.handleError(truoraError)
            } else {
                await router?.handleError(
                    .network(message: "Reference face enrollment failed: \(error.localizedDescription)")
                )
            }
        }
    }

    func cancelTapped() async {
        // Log cancel button clicked
        await interactor?.logCancelButtonClicked()

        validationTask?.cancel()
        await router?.handleCancellation(loadingType: .face)
    }
}

extension PassiveIntroPresenter: PassiveIntroInteractorToPresenter {
    func validationCreated(response: NativeValidationCreateResponse) async {
        guard let router else {
            await view?.hideLoading()
            await view?.showError("Router not configured")
            return
        }

        await view?.hideLoading()

        do {
            let validationId = response.validationId
            let uploadUrl = response.instructions?.fileUploadLink

            ValidationConfig.shared.updateValidationId(validationId)
            try await router.navigateToPassiveCapture(validationId: validationId, uploadUrl: uploadUrl)
        } catch {
            await view?.showError(error.localizedDescription)
        }
    }

    func validationFailed(_ error: TruoraException) async {
        await view?.hideLoading()
        await router?.handleError(error)
    }
}
