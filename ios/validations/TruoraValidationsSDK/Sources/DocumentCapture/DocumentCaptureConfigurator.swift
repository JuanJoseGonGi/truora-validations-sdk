//
//  DocumentCaptureConfigurator.swift
//  TruoraValidationsSDK
//
//  Created by Truora on 23/12/25.
//

import SwiftUI
import UIKit

enum DocumentCaptureConfigurator {
    /// Resolves whether autocapture should be enabled based on the document config.
    /// Passport documents always disable autocapture because the ML model
    /// does not work reliably on that document type.
    static func resolveAutocapture(from documentConfig: Document) -> Bool {
        let isPassport = documentConfig.documentType == NativeDocumentType.passport.rawValue
        return documentConfig.useAutocapture && !isPassport
    }

    @MainActor static func buildModule(
        router: ValidationRouter,
        validationId: String,
        frontUploadUrl: String,
        reverseUploadUrl: String?
    ) throws -> UIViewController {
        let viewModel = DocumentCaptureViewModel()
        let useAutocapture = resolveAutocapture(from: ValidationConfig.shared.documentConfig)

        // Create performance advisor for adaptive behavior on constrained devices
        let performanceAdvisor = PerformanceAdvisor()

        let presenter = DocumentCapturePresenter(
            view: viewModel,
            interactor: nil,
            router: router,
            validationId: validationId,
            useAutocapture: useAutocapture
        )

        let logger = try TruoraLoggerImplementation.shared
        let interactor = DocumentCaptureInteractor(
            presenter: presenter,
            logger: logger
        )

        // Configure upload URLs immediately (presenter also validates via router on load).
        interactor.setUploadUrls(frontUploadUrl: frontUploadUrl, reverseUploadUrl: reverseUploadUrl)

        viewModel.presenter = presenter
        viewModel.useAutocapture = useAutocapture
        viewModel.tfliteThreadCount = performanceAdvisor.recommendedTFLiteThreadCount
        presenter.interactor = interactor

        #if DEBUG
        viewModel.performanceAdvisor = performanceAdvisor
        #endif

        let config = ValidationConfig.shared.uiConfig
        let swiftUIView = DocumentCaptureView(viewModel: viewModel, config: config)
            .sdkLocaleEnvironment(locale: TruoraLocalization.currentLocale)
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.modalPresentationStyle = .fullScreen
        return hostingController
    }
}
