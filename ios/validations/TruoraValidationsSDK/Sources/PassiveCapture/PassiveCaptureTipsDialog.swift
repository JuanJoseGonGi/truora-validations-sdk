//
//  PassiveCaptureTipsDialog.swift
//  TruoraValidationsSDK
//
//  Created by Truora on 23/01/26.
//

import SwiftUI

struct PassiveCaptureTipsDialog: View {
    let onDismiss: () -> Void
    let onManualRecording: () -> Void

    @EnvironmentObject var theme: TruoraTheme

    /// Computed so strings reflect current locale; lookup cost is negligible when dialog is shown.
    private var tips: [String] {
        [
            TruoraLocalization.string(forKey: LocalizationKeys.passiveCaptureTip1),
            TruoraLocalization.string(forKey: LocalizationKeys.passiveCaptureTip2),
            TruoraLocalization.string(forKey: LocalizationKeys.passiveCaptureTip3),
            TruoraLocalization.string(forKey: LocalizationKeys.passiveCaptureTip4)
        ]
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .extendingIntoSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 0) {
                // Header with title and close button
                HStack {
                    Text(TruoraLocalization.string(forKey: LocalizationKeys.passiveCaptureTipsTitle))
                        .font(theme.typography.titleSmall)
                        .foregroundColor(theme.colors.onSurface)

                    Spacer()

                    Button(action: onDismiss) {
                        SwiftUI.Image(systemName: "xmark")
                            .font(theme.typography.bodyLarge)
                            .foregroundColor(theme.colors.onSurface)
                    }
                    .frame(width: 24, height: 24)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)

                // Divider
                Divider()
                    .background(theme.colors.layoutGray200)

                // Tips list with bullet points
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(tips, id: \.self) { tip in
                        TipBulletRow(text: tip, color: theme.colors.onSurface)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)

                // Divider
                Divider()
                    .background(theme.colors.layoutGray200)

                // Manual recording button
                TruoraPrimaryButton(
                    title: TruoraLocalization.string(forKey: LocalizationKeys.passiveCaptureManualRecording),
                    isLoading: false,
                    action: onManualRecording
                )
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .frame(width: 320)
            .background(theme.colors.surface)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(theme.colors.layoutGray200, lineWidth: 1)
            )
        }
    }
}

// MARK: - Tip Bullet Row

private struct TipBulletRow: View {
    let text: String
    let color: Color
    @EnvironmentObject var theme: TruoraTheme

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(theme.typography.bodyMedium)
                .foregroundColor(color)

            Text(text)
                .font(theme.typography.bodyMedium)
                .foregroundColor(color)
                .lineSpacing(7) // 150% line height = 21px, 14px font = 7px extra
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Previews

#Preview {
    PassiveCaptureTipsDialog(
        onDismiss: {},
        onManualRecording: {}
    )
    .environmentObject(TruoraTheme(config: nil))
}
