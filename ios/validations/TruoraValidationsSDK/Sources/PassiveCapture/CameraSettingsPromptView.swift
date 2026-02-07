//
//  CameraSettingsPromptView.swift
//  TruoraValidationsSDK
//
//  Created by Truora on 23/01/26.
//

import SwiftUI

struct CameraSettingsPromptView: View {
    let onOpenSettings: () -> Void
    let onDismiss: () -> Void
    @EnvironmentObject var theme: TruoraTheme

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .extendingIntoSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 24) {
                Text(TruoraLocalization.string(forKey: LocalizationKeys.cameraPermissionDeniedTitle))
                    .font(theme.typography.titleLarge)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.onSurface)
                    .multilineTextAlignment(.center)

                Text(TruoraLocalization.string(forKey: LocalizationKeys.cameraPermissionDeniedDescription))
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.onSurface)
                    .multilineTextAlignment(.center)

                VStack(spacing: 12) {
                    TruoraPrimaryButton(
                        title: TruoraLocalization.string(forKey: LocalizationKeys.cameraPermissionOpenSettings),
                        isLoading: false,
                        action: onOpenSettings
                    )

                    Button(action: onDismiss) {
                        Text(
                            TruoraLocalization.string(forKey: LocalizationKeys.passiveCaptureTryAgain)
                        )
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.primary)
                    }
                }
            }
            .padding(24)
            .background(theme.colors.surface)
            .cornerRadius(16)
            .padding(32)
        }
    }
}

// MARK: - Previews

#Preview {
    CameraSettingsPromptView(
        onOpenSettings: {},
        onDismiss: {}
    )
    .environmentObject(TruoraTheme(config: nil))
}
