//
//  DocumentIntroViewModel.swift
//  TruoraValidationsSDK
//
//  Created by Truora on 23/12/25.
//

import Foundation

/// ViewModel for the document intro screen.
/// Uses @Published properties which automatically notify SwiftUI on the main thread.
@MainActor final class DocumentIntroViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    var presenter: DocumentIntroViewToPresenter?
    private var didLoadOnce: Bool = false

    func onAppear() {
        guard !didLoadOnce else { return }
        didLoadOnce = true
        Task { await presenter?.viewDidLoad() }
    }

    func start() {
        Task { await presenter?.startTapped() }
    }

    func cancel() {
        Task { await presenter?.cancelTapped() }
    }
}

// MARK: - DocumentIntroPresenterToView

extension DocumentIntroViewModel: DocumentIntroPresenterToView {
    func showLoading() {
        isLoading = true
    }

    func hideLoading() {
        isLoading = false
    }

    func showError(_ message: String) {
        errorMessage = message
        showError = true
    }
}
