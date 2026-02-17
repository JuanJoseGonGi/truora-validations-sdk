//
//  ResultPresenterTests.swift
//  TruoraValidationsSDKTests
//
//  Created by Truora on 21/12/25.
//

import XCTest
@testable import TruoraValidationsSDK

@MainActor final class ResultPresenterTests: XCTestCase {
    private var mockView: MockResultView!
    private var mockInteractor: MockResultInteractor!
    private var mockRouter: MockResultRouter!
    private var mockDelegate: MockValidationDelegate!

    override func setUp() {
        super.setUp()
        mockView = MockResultView()
        mockInteractor = MockResultInteractor()
        let navController = TruoraNavigationController()
        mockRouter = MockResultRouter(navigationController: navController)
        mockDelegate = MockValidationDelegate()
        ValidationConfig.shared.reset()
    }

    override func tearDown() {
        mockView = nil
        mockInteractor = nil
        mockRouter = nil
        mockDelegate = nil
        ValidationConfig.shared.reset()
        super.tearDown()
    }

    // MARK: - Lifecycle Tests

    func testViewDidLoad_waitingForResults_startsPollingAndShowsLoading() async {
        // Given
        ValidationConfig.shared.faceConfig.waitForResults(true)
        let sut = createPresenter()

        // When
        await sut.viewDidLoad()

        // Then
        XCTAssertTrue(mockView.showLoadingCalled)
        XCTAssertTrue(mockInteractor.startPollingCalled)
    }

    func testViewDidLoad_notWaitingForResults_startsPollingAndShowsCompleted() async {
        // Given
        let sut = createPresenter(loadingType: .face, waitForResults: false)

        // When
        await sut.viewDidLoad()

        // Then
        XCTAssertTrue(mockView.showCompletedCalled)
        XCTAssertTrue(mockInteractor.startPollingCalled)
    }

    // MARK: - Action Tests

    func testDoneTapped_withResult_dismissesFlowAndNotifiesDelegate() async {
        // Given
        ValidationConfig.shared.faceConfig.waitForResults(true)
        let sut = createPresenter()
        let result = ValidationResult(validationId: "id", status: .success)
        await sut.pollingCompleted(result: result)

        // When
        await sut.doneTapped()

        // Then
        XCTAssertTrue(mockRouter.dismissFlowCalled)
    }

    // MARK: - Interactor Callback Tests

    func testPollingCompleted_waitingForResults_showsResult() async {
        // Given
        ValidationConfig.shared.faceConfig.waitForResults(true)
        let sut = createPresenter()
        let result = ValidationResult(validationId: "id", status: .success)

        // When
        await sut.pollingCompleted(result: result)

        // Then
        XCTAssertTrue(mockView.showResultCalled)
        XCTAssertEqual(mockView.lastResult, result)
    }

    func testPollingFailed_waitingForResults_showsFailedResult() async {
        // Given
        ValidationConfig.shared.faceConfig.waitForResults(true)
        let sut = createPresenter()

        // When
        await sut.pollingFailed(error: .network(message: "error"))

        // Then
        XCTAssertTrue(mockView.showResultCalled)
        XCTAssertEqual(mockView.lastResult?.status, .failure)
    }

    // MARK: - Cancellation Tests

    func testViewDidLoad_whenCanceled_showsFailedResultImmediately() async {
        // Given
        let sut = createPresenter(isCanceled: true)

        // When
        await sut.viewDidLoad()

        // Then
        XCTAssertTrue(mockView.showResultCalled)
        XCTAssertEqual(mockView.lastResult?.status, .failure)
        XCTAssertFalse(mockInteractor.startPollingCalled)
    }

    func testDoneTapped_whenCanceled_dismissesFlowAndNotifiesCancellation() async throws {
        // Given
        try await ValidationConfig.shared.configure(
            apiKey: "test-key",
            accountId: "test-account",
            delegate: mockDelegate.closure
        )
        let sut = createPresenter(isCanceled: true)
        await sut.viewDidLoad()

        // When
        await sut.doneTapped()

        // Then
        XCTAssertTrue(mockRouter.dismissFlowCalled)
        XCTAssertTrue(mockDelegate.failureCalled)
    }

    // MARK: - Finish View Configuration Tests

    func testPollingCompleted_successHidden_autoDismissesAndNotifiesDelegate() async throws {
        // Given
        try await ValidationConfig.shared.configure(
            apiKey: "test-key",
            accountId: "test-account",
            delegate: mockDelegate.closure
        )
        let config = FinishViewConfiguration(success: .hide, failure: .show)
        ValidationConfig.shared.faceConfig.setFinishViewConfiguration(config)
        let sut = createPresenter()

        await sut.viewDidLoad()

        // When
        let result = ValidationResult(validationId: "id", status: .success)
        await sut.pollingCompleted(result: result)

        // Then
        XCTAssertTrue(mockRouter.dismissFlowCalled, "Should auto-dismiss when success is hidden")
        XCTAssertFalse(mockView.showResultCalled, "Should NOT show result screen")
        XCTAssertTrue(mockDelegate.completeCalled, "Should notify delegate")
    }

    func testPollingCompleted_successShown_showsResultScreen() async {
        // Given
        let config = FinishViewConfiguration(success: .show, failure: .hide)
        ValidationConfig.shared.faceConfig.setFinishViewConfiguration(config)
        let sut = createPresenter()

        await sut.viewDidLoad()

        // When
        let result = ValidationResult(validationId: "id", status: .success)
        await sut.pollingCompleted(result: result)

        // Then
        XCTAssertTrue(mockView.showResultCalled, "Should show result screen")
        XCTAssertFalse(mockRouter.dismissFlowCalled, "Should NOT auto-dismiss")
    }

    func testPollingCompleted_failureHidden_autoDismissesAndNotifiesDelegate() async throws {
        // Given
        try await ValidationConfig.shared.configure(
            apiKey: "test-key",
            accountId: "test-account",
            delegate: mockDelegate.closure
        )
        let config = FinishViewConfiguration(success: .show, failure: .hide)
        ValidationConfig.shared.faceConfig.setFinishViewConfiguration(config)
        let sut = createPresenter()

        await sut.viewDidLoad()

        // When
        let result = ValidationResult(validationId: "id", status: .failure)
        await sut.pollingCompleted(result: result)

        // Then
        XCTAssertTrue(mockRouter.dismissFlowCalled, "Should auto-dismiss when failure is hidden")
        XCTAssertFalse(mockView.showResultCalled, "Should NOT show result screen")
        XCTAssertTrue(mockDelegate.completeCalled, "Should notify delegate")
    }

    func testPollingCompleted_failureShown_showsResultScreen() async {
        // Given
        let config = FinishViewConfiguration(success: .hide, failure: .show)
        ValidationConfig.shared.faceConfig.setFinishViewConfiguration(config)
        let sut = createPresenter()

        await sut.viewDidLoad()

        // When
        let result = ValidationResult(validationId: "id", status: .failure)
        await sut.pollingCompleted(result: result)

        // Then
        XCTAssertTrue(mockView.showResultCalled, "Should show result screen")
        XCTAssertFalse(mockRouter.dismissFlowCalled, "Should NOT auto-dismiss")
    }

    func testPollingFailed_failureHidden_autoDismisses() async throws {
        // Given
        try await ValidationConfig.shared.configure(
            apiKey: "test-key",
            accountId: "test-account",
            delegate: mockDelegate.closure
        )
        let config = FinishViewConfiguration(success: .show, failure: .hide)
        ValidationConfig.shared.faceConfig.setFinishViewConfiguration(config)
        let sut = createPresenter()

        await sut.viewDidLoad()

        // When
        await sut.pollingFailed(error: .network(message: "error"))

        // Then
        XCTAssertTrue(mockRouter.dismissFlowCalled, "Should auto-dismiss on polling failure")
        XCTAssertFalse(mockView.showResultCalled, "Should NOT show result screen")
        XCTAssertTrue(mockDelegate.failureCalled, "Should notify delegate of failure")
    }

    func testPollingFailed_failureShown_showsFailedResult() async {
        // Given
        let config = FinishViewConfiguration(success: .hide, failure: .show)
        ValidationConfig.shared.faceConfig.setFinishViewConfiguration(config)
        let sut = createPresenter()

        await sut.viewDidLoad()

        // When
        await sut.pollingFailed(error: .network(message: "error"))

        // Then
        XCTAssertTrue(mockView.showResultCalled, "Should show failure result screen")
        XCTAssertEqual(mockView.lastResult?.status, .failure)
        XCTAssertFalse(mockRouter.dismissFlowCalled, "Should NOT auto-dismiss")
    }

    func testPollingCompleted_noFinishViewConfig_showsResultAsDefault() async {
        // Given - no finishViewConfig set, waitForResults = true
        ValidationConfig.shared.faceConfig.waitForResults(true)
        let sut = createPresenter()

        await sut.viewDidLoad()

        // When
        let result = ValidationResult(validationId: "id", status: .success)
        await sut.pollingCompleted(result: result)

        // Then
        XCTAssertTrue(mockView.showResultCalled, "Should show result screen by default")
        XCTAssertFalse(mockRouter.dismissFlowCalled, "Should NOT auto-dismiss")
    }

    func testFinishViewConfig_impliesWaitForResults_showsLoading() async {
        // Given
        let config = FinishViewConfiguration(success: .hide, failure: .hide)
        ValidationConfig.shared.faceConfig.setFinishViewConfiguration(config)
        let sut = createPresenter()

        // When
        await sut.viewDidLoad()

        // Then
        XCTAssertTrue(mockView.showLoadingCalled, "Should show loading (waitForResults is implied)")
        XCTAssertTrue(mockInteractor.startPollingCalled, "Should start polling")
    }

    func testFinishViewConfig_canceledIgnoresConfig_showsFailure() async {
        // Given - even with both hidden, cancellation should still show failure
        let config = FinishViewConfiguration(success: .hide, failure: .hide)
        ValidationConfig.shared.faceConfig.setFinishViewConfiguration(config)
        let sut = createPresenter(isCanceled: true)

        // When
        await sut.viewDidLoad()

        // Then
        XCTAssertTrue(mockView.showResultCalled, "Cancellation should still show failure screen")
        XCTAssertEqual(mockView.lastResult?.status, .failure)
        XCTAssertFalse(mockInteractor.startPollingCalled, "Should NOT start polling on cancel")
    }

    // MARK: - Helper Methods

    private func createPresenter(
        loadingType: ResultLoadingType = .face,
        waitForResults: Bool = true,
        isCanceled: Bool = false
    ) -> ResultPresenter {
        // Configure the validation config to match the test expectation
        switch loadingType {
        case .face:
            ValidationConfig.shared.faceConfig.waitForResults(waitForResults)
        case .document:
            ValidationConfig.shared.documentConfig.waitForResults(waitForResults)
        }

        return ResultPresenter(
            view: mockView,
            interactor: mockInteractor,
            router: mockRouter,
            loadingType: loadingType,
            isCanceled: isCanceled
        )
    }
}

// MARK: - Mock View

@MainActor private class MockResultView: ResultPresenterToView {
    var showLoadingCalled = false
    var showResultCalled = false
    var showCompletedCalled = false
    var setLoadingButtonStateCalled = false
    var lastResult: ValidationResult?
    var lastButtonLoadingState: Bool?

    func showLoading() {
        showLoadingCalled = true
    }

    func showResult(_ result: ValidationResult) {
        showResultCalled = true
        lastResult = result
    }

    func showCompleted() {
        showCompletedCalled = true
    }

    func setLoadingButtonState(_ isLoading: Bool) {
        setLoadingButtonStateCalled = true
        lastButtonLoadingState = isLoading
    }
}

// MARK: - Mock Interactor

private class MockResultInteractor: ResultPresenterToInteractor {
    var validationId: String = "test-validation-id"
    var startPollingCalled = false
    var cancelPollingCalled = false

    func startPolling() {
        startPollingCalled = true
    }

    func cancelPolling() {
        cancelPollingCalled = true
    }
}

// MARK: - Mock Router

@MainActor private class MockResultRouter: ValidationRouter {
    var dismissFlowCalled = false

    override func dismissFlow() {
        dismissFlowCalled = true
    }
}

// MARK: - Mock Delegate

@MainActor private class MockValidationDelegate {
    var completeCalled = false
    var failureCalled = false
    var lastResult: ValidationResult?
    var lastError: TruoraException?

    var closure: (TruoraValidationResult<ValidationResult>) -> Void {
        { [weak self] result in
            switch result {
            case .completed(let validationResult):
                self?.completeCalled = true
                self?.lastResult = validationResult
            case .error(let error):
                self?.failureCalled = true
                self?.lastError = error
            case .canceled:
                break
            }
        }
    }
}
