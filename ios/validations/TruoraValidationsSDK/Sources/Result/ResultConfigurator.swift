//
//  ResultConfigurator.swift
//  TruoraValidationsSDK
//
//  Created by Truora on 21/12/25.
//

import SwiftUI
import UIKit

enum ResultConfigurator {
    @MainActor static func buildModule(
        router: ValidationRouter,
        validationId: String,
        loadingType: ResultLoadingType = .face,
        isCanceled: Bool = false
    ) throws -> UIViewController {
        let logger = try TruoraLoggerImplementation.shared
        let interactor = ResultInteractor(
            validationId: validationId,
            loadingType: loadingType,
            logger: logger
        )

        let viewModel = ResultViewModel(loadingType: loadingType)
        let presenter = ResultPresenter(
            view: viewModel,
            interactor: interactor,
            router: router,
            loadingType: loadingType,
            isCanceled: isCanceled
        )

        viewModel.presenter = presenter
        interactor.presenter = presenter

        let config = ValidationConfig.shared.uiConfig
        let swiftUIView = ResultView(viewModel: viewModel, config: config)
            .sdkLocaleEnvironment(locale: TruoraLocalization.currentLocale)
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.modalPresentationStyle = .fullScreen

        return hostingController
    }
}
