//
//  DocumentFeedbackViewModel.swift
//  TruoraValidationsSDK
//
//  Created by Truora on 05/01/26.
//

import Foundation

// MARK: - View Model

@MainActor final class DocumentFeedbackViewModel: ObservableObject {
    let feedback: FeedbackScenario
    let capturedImageData: Data?
    let retriesLeft: Int
    var presenter: DocumentFeedbackViewToPresenter?

    init(feedback: FeedbackScenario, capturedImageData: Data?, retriesLeft: Int) {
        self.feedback = feedback
        self.capturedImageData = capturedImageData
        self.retriesLeft = retriesLeft
    }

    func onAppear() {
        guard let presenter else {
            debugLog("⚠️ DocumentFeedbackViewModel: presenter is nil in onAppear")
            return
        }
        Task { await presenter.viewDidLoad() }
    }

    func retryTapped() {
        Task { await presenter?.retryTapped() }
    }

    func cancelTapped() {
        Task { await presenter?.cancelTapped() }
    }
}

// MARK: - DocumentFeedbackPresenterToView

extension DocumentFeedbackViewModel: DocumentFeedbackPresenterToView {}
