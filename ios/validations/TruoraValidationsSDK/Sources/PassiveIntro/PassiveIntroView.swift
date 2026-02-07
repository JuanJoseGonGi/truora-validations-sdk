//
//  PassiveIntroView.swift
//  TruoraValidationsSDK
//
//  Created by Truora on 31/10/25.
//

import SwiftUI

struct PassiveIntroView: View {
    @ObservedObject var viewModel: PassiveIntroViewModel
    @ObservedObject private var theme: TruoraTheme

    init(viewModel: PassiveIntroViewModel, config: UIConfig?) {
        self.viewModel = viewModel
        self.theme = TruoraTheme(config: config)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                if viewModel.showCancelButton {
                    TruoraHeaderView {
                        viewModel.cancel()
                    }
                }

                // Content
                PassiveIntroContentView()

                Spacer()

                // Footer
                TruoraFooterView(
                    securityTip: TruoraLocalization.string(
                        forKey: LocalizationKeys.passiveInstructionsSecurityTip
                    ),
                    buttonText: TruoraLocalization.string(
                        forKey: LocalizationKeys.passiveInstructionsStartVerification
                    ),
                    isLoading: viewModel.isLoading,
                    buttonAccessibilityIdentifier: "intro_start_button"
                ) {
                    viewModel.start()
                }
            }

            // Loading overlay
            if viewModel.isLoading {
                LoadingOverlayView(
                    message: TruoraLocalization.string(forKey: LocalizationKeys.passiveCaptureLoadingTitle)
                )
            }
        }
        .environmentObject(theme)
        .background(theme.colors.surface.extendingIntoSafeArea())
        .navigationBarHidden(true)
        .alert(isPresented: $viewModel.showError) {
            Alert(
                title: Text(TruoraLocalization.string(forKey: LocalizationKeys.commonError)),
                message: Text(viewModel.errorMessage ?? ""),
                dismissButton: .default(Text(TruoraLocalization.string(forKey: LocalizationKeys.commonOk)))
            )
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
}

// MARK: - Previews

#Preview {
    PassiveIntroView(
        viewModel: PassiveIntroViewModel(),
        config: nil
    )
}
