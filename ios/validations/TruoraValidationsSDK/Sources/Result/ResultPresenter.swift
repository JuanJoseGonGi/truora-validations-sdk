//
//  ResultPresenter.swift
//  TruoraValidationsSDK
//
//  Created by Truora on 21/12/25.
//

import Foundation

final class ResultPresenter {
    weak var view: ResultPresenterToView?
    var interactor: ResultPresenterToInteractor?
    weak var router: ValidationRouter?

    private let validationId: String
    private let waitForResults: Bool
    private let finishViewConfig: FinishViewConfiguration?
    private let loadingType: ResultLoadingType
    private let timeProvider: TimeProvider
    private let isCanceled: Bool

    private var finalResult: ValidationResult?

    private var delegateCalled = false

    init(
        view: ResultPresenterToView,
        interactor: ResultPresenterToInteractor?,
        router: ValidationRouter,
        loadingType: ResultLoadingType,
        isCanceled: Bool = false,
        timeProvider: TimeProvider = RealTimeProvider()
    ) {
        self.view = view
        self.interactor = interactor
        self.router = router
        self.validationId = interactor?.validationId ?? ""
        self.loadingType = loadingType
        self.isCanceled = isCanceled
        self.timeProvider = timeProvider

        let configWaitForResults = switch loadingType {
        case .face: ValidationConfig.shared.faceConfig.waitForResults
        case .document: ValidationConfig.shared.documentConfig.waitForResults
        }

        self.finishViewConfig = switch loadingType {
        case .face: ValidationConfig.shared.faceConfig.finishViewConfig
        case .document: ValidationConfig.shared.documentConfig.finishViewConfig
        }

        self.waitForResults = configWaitForResults
    }

    deinit {
        interactor?.cancelPolling()
    }
}

// MARK: - ResultViewToPresenter

extension ResultPresenter: ResultViewToPresenter {
    func viewDidLoad() async {
        // Log view rendered
        await interactor?.logViewRendered()

        // Handle cancellation case - show failure immediately, skip polling.
        // Design decision: Show failure screen instead of immediate dismissal to provide
        // visual feedback that the validation was canceled. This matches the user expectation
        // that confirming cancellation leads to a definitive end state, not an abrupt dismissal.
        if isCanceled {
            let canceledResult = ValidationResult(
                validationId: validationId,
                status: .failure,
                confidence: nil,
                metadata: nil
            )
            finalResult = canceledResult
            await view?.showResult(canceledResult)
            return
        }

        if waitForResults {
            // Show loading and wait for result
            await view?.showLoading()
            interactor?.startPolling()
        } else {
            // Show completed immediately, poll in background
            await view?.showCompleted()
            interactor?.startPolling()
        }
    }

    func doneTapped() async {
        guard let router else {
            print("⚠️ ResultPresenter: Router is nil, cannot dismiss flow")
            return
        }

        // Handle cancellation case - always return cancellation error
        if isCanceled {
            await router.dismissFlow()
            await notifyDelegateCancellation()
            return
        }

        if waitForResults {
            guard let result = finalResult else {
                print("⚠️ ResultPresenter: Done tapped but no result yet")
                return
            }

            await router.dismissFlow()
            await notifyDelegate(with: result)
        } else {
            await router.dismissFlow()
            // If we have a result, use it (could be success/failure if polling finished)
            // If not, return a pending result
            let result = finalResult ?? ValidationResult(
                validationId: validationId,
                status: .pending,
                confidence: nil,
                metadata: nil
            )
            await notifyDelegate(with: result)
        }
    }
}

// MARK: - ResultInteractorToPresenter

extension ResultPresenter: ResultInteractorToPresenter {
    func pollingCompleted(result: ValidationResult) async {
        finalResult = result
        print("🟢 ResultPresenter: Polling completed with status: \(result.status)")

        // Log SDK execution finished
        await interactor?.logSdkExecutionFinished()

        guard waitForResults else {
            // UI is already showing "Completed", just notify delegate
            await notifyDelegate(with: result)
            return
        }

        if shouldAutoDismiss(for: result.status) {
            await router?.dismissFlow()
            await notifyDelegate(with: result)
            return
        }

        await view?.showResult(result)
    }

    func pollingFailed(error: TruoraException) async {
        print("❌ ResultPresenter: Polling failed: \(error)")

        // Create a failed result for display purposes
        let failedResult = ValidationResult(
            validationId: validationId,
            status: .failure,
            confidence: nil,
            metadata: nil
        )
        finalResult = failedResult

        guard waitForResults else {
            await notifyDelegateError(error)
            return
        }

        if shouldAutoDismiss(for: .failure) {
            await router?.dismissFlow()
            await notifyDelegateError(error)
            return
        }

        await view?.showResult(failedResult)
    }
}

// MARK: - Private Methods

private extension ResultPresenter {
    func shouldAutoDismiss(for status: ValidationStatus) -> Bool {
        guard let config = finishViewConfig else { return false }
        switch status {
        case .success: return config.success == .hide
        case .failure: return config.failure == .hide
        case .pending: return false
        }
    }

    func notifyDelegate(with result: ValidationResult) async {
        guard !delegateCalled else {
            print("⚠️ ResultPresenter: Delegate already called, skipping")
            return
        }
        delegateCalled = true

        // 100ms delay allows the dismiss animation to complete before notifying the delegate.
        // This prevents potential UI glitches where the host app reacts to the delegate
        // callback while the SDK's views are still animating out.
        try? await timeProvider.sleep(nanoseconds: 100_000_000)

        await MainActor.run {
            ValidationConfig.shared.delegate?(.completed(result))
        }
    }

    func notifyDelegateError(_ error: TruoraException) async {
        guard !delegateCalled else {
            print("⚠️ ResultPresenter: Delegate already called, skipping")
            return
        }
        delegateCalled = true

        try? await timeProvider.sleep(nanoseconds: 100_000_000)

        await MainActor.run {
            ValidationConfig.shared.delegate?(.error(error))
        }
    }

    func notifyDelegateCancellation() async {
        guard !delegateCalled else {
            print("⚠️ ResultPresenter: Delegate already called, skipping")
            return
        }
        delegateCalled = true

        // 100ms delay allows the dismiss animation to complete before notifying the delegate.
        // This prevents potential UI glitches where the host app reacts to the delegate
        // callback while the SDK's views are still animating out.
        try? await timeProvider.sleep(nanoseconds: 100_000_000)

        await MainActor.run {
            ValidationConfig.shared.delegate?(.canceled(nil))
        }
    }
}
