//
//  PassiveCaptureConfigurator.swift
//  TruoraValidationsSDK
//
//  Created by Truora on 30/10/25.
//

import Foundation
import SwiftUI
import UIKit

enum PassiveCaptureConfigurator {
    @MainActor static func buildModule(
        router: ValidationRouter,
        validationId: String
    ) throws -> UIViewController {
        let viewModel = PassiveCaptureViewModel()
        let useAutocapture = ValidationConfig.shared.faceConfig.useAutocapture

        let presenter = PassiveCapturePresenter(
            view: viewModel,
            interactor: nil,
            router: router,
            validationId: validationId,
            useAutocapture: useAutocapture
        )

        let logger = try TruoraLoggerImplementation.shared
        let interactor = PassiveCaptureInteractor(
            presenter: presenter,
            validationId: validationId,
            logger: logger
        )

        presenter.interactor = interactor
        viewModel.presenter = presenter

        let uiConfig = ValidationConfig.shared.uiConfig
        let swiftUIView = PassiveCaptureView(viewModel: viewModel, config: uiConfig)
            .sdkLocaleEnvironment(locale: TruoraLocalization.currentLocale)
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.view.backgroundColor = .clear // Ensure transparent background
        hostingController.modalPresentationStyle = .fullScreen

        return hostingController
    }
}
