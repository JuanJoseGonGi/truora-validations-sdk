//
//  DocumentCaptureConfigurator.swift
//  TruoraValidationsSDK
//
//  Created by Truora on 23/12/25.
//

import SwiftUI
import UIKit

enum DocumentCaptureConfigurator {
    @MainActor static func buildModule(
        router: ValidationRouter,
        validationId: String,
        frontUploadUrl: String,
        reverseUploadUrl: String?
    ) throws -> UIViewController {
        let viewModel = DocumentCaptureViewModel()

        let presenter = DocumentCapturePresenter(
            view: viewModel,
            interactor: nil,
            router: router,
            validationId: validationId
        )

        let logger = try TruoraLoggerImplementation.shared
        let interactor = DocumentCaptureInteractor(
            presenter: presenter,
            logger: logger
        )

        // Configure upload URLs immediately (presenter also validates via router on load).
        interactor.setUploadUrls(frontUploadUrl: frontUploadUrl, reverseUploadUrl: reverseUploadUrl)

        viewModel.presenter = presenter
        presenter.interactor = interactor

        let config = ValidationConfig.shared.uiConfig
        let swiftUIView = DocumentCaptureView(viewModel: viewModel, config: config)
            .sdkLocaleEnvironment(locale: config.language?.locale ?? Locale.current)
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.modalPresentationStyle = .fullScreen
        return hostingController
    }
}
