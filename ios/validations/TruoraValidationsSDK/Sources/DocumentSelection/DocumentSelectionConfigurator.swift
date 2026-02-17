//
//  DocumentSelectionConfigurator.swift
//  TruoraValidationsSDK
//
//  Created by Truora on 07/01/26.
//

import Foundation
import SwiftUI
import UIKit

enum DocumentSelectionConfigurator {
    @MainActor static func buildModule(
        router: ValidationRouter
    ) throws -> UIViewController {
        let viewModel = DocumentSelectionViewModel()

        let presenter = DocumentSelectionPresenter(
            view: viewModel,
            interactor: nil,
            router: router
        )

        let logger = try TruoraLoggerImplementation.shared
        let interactor = DocumentSelectionInteractor(
            presenter: presenter,
            logger: logger
        )

        viewModel.presenter = presenter
        presenter.interactor = interactor

        let swiftUIView = DocumentSelectionView(viewModel: viewModel, config: ValidationConfig.shared.uiConfig)
            .sdkLocaleEnvironment(locale: TruoraLocalization.currentLocale)
        return UIHostingController(rootView: swiftUIView)
    }
}
