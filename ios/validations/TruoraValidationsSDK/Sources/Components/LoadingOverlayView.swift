//
//  LoadingOverlayView.swift
//  TruoraValidationsSDK
//
//  Created by Truora on 23/01/26.
//

import SwiftUI

struct LoadingOverlayView: View {
    let message: String
    @EnvironmentObject var theme: TruoraTheme

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .extendingIntoSafeArea()

            VStack(spacing: 20) {
                ActivityIndicator(
                    isAnimating: .constant(true),
                    style: .large,
                    color: .white
                )

                Text(message)
                    .foregroundColor(.white)
                    .font(theme.typography.bodyLarge)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Previews

#Preview {
    LoadingOverlayView(message: "Loading...")
        .environmentObject(TruoraTheme(config: nil))
}
