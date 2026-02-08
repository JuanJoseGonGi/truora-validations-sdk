//
//  DocumentSelectionInteractor.swift
//  TruoraValidationsSDK
//
//  Created by Truora on 07/01/26.
//

import Foundation

final class DocumentSelectionInteractor {
    weak var presenter: DocumentSelectionInteractorToPresenter?
    private let logger: TruoraLogger

    /// Constants for logging
    private static let viewName = "doc_selection"
    private static let validationType = "doc_validation"

    init(
        presenter: DocumentSelectionInteractorToPresenter?,
        logger: TruoraLogger
    ) {
        self.presenter = presenter
        self.logger = logger
    }
}

extension DocumentSelectionInteractor: DocumentSelectionPresenterToInteractor {
    func fetchSupportedCountries() {
        // Supported countries.
        let countries: [NativeCountry] = [
            .all, .ar, .br, .cl, .co, .cr, .mx, .pe, .sv, .ve
        ]
        Task { await presenter?.didLoadCountries(countries) }
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

    func logContinueButtonClicked(selectedCountry: NativeCountry?, selectedDocument: NativeDocumentType?) async {
        var metadata: [String: Any] = [
            "name": Self.viewName,
            "validation_type": Self.validationType
        ]
        if let country = selectedCountry {
            metadata["selected_country"] = country.rawValue
        }
        if let document = selectedDocument {
            metadata["selected_document"] = document.rawValue
        }
        await logger.logView(
            viewName: "continue_button_clicked",
            level: .info,
            retention: .oneWeek,
            metadata: metadata
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
