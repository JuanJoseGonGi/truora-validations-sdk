//
//  PassiveCaptureCountdownView.swift
//  TruoraValidationsSDK
//
//  Created by Truora on 23/01/26.
//

import Combine
import SwiftUI
import UIKit

/// Displays the instruction text at the top of the screen during countdown
struct PassiveCaptureCountdownHeaderView: View {
    @EnvironmentObject var theme: TruoraTheme

    var body: some View {
        Text(TruoraLocalization.string(forKey: LocalizationKeys.passiveCaptureStartInstruction))
            .font(theme.typography.titleMedium)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
    }
}

/// Displays the countdown number centered in the oval
struct PassiveCaptureCountdownNumberView: View {
    let countdown: Int
    @EnvironmentObject var theme: TruoraTheme

    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    @State private var previousCountdown: Int = -1

    var body: some View {
        Text("\(countdown)")
            .font(theme.typography.displayLarge)
            .foregroundColor(.white)
            .scaleEffect(scale)
            .opacity(opacity)
            .onReceive(Just(countdown)) { newValue in
                guard newValue != previousCountdown else { return }
                previousCountdown = newValue

                withAnimation(.easeOut(duration: 0.3)) {
                    scale = 1.2
                    opacity = 0.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
    }
}

/// Legacy view for backward compatibility - combines header and number
struct PassiveCaptureCountdownView: View {
    let countdown: Int
    @EnvironmentObject var theme: TruoraTheme

    var body: some View {
        VStack(spacing: 16) {
            PassiveCaptureCountdownHeaderView()
            PassiveCaptureCountdownNumberView(countdown: countdown)
        }
    }
}

// MARK: - Previews

#Preview("Countdown Layout") {
    ZStack {
        Color(red: 0.03, green: 0.13, blue: 0.33) // primary900
        VStack {
            PassiveCaptureCountdownHeaderView()
                .padding(.top, 16)
                .environmentObject(TruoraTheme(config: nil))
            Spacer()
            PassiveCaptureCountdownNumberView(countdown: 3)
                .environmentObject(TruoraTheme(config: nil))
            Spacer()
        }
    }
}

#Preview("Header Only") {
    ZStack {
        Color(red: 0.03, green: 0.13, blue: 0.33)
        PassiveCaptureCountdownHeaderView()
            .environmentObject(TruoraTheme(config: nil))
    }
    .frame(height: 100)
}

#Preview("Number Only") {
    ZStack {
        Color(red: 0.03, green: 0.13, blue: 0.33)
        PassiveCaptureCountdownNumberView(countdown: 1)
            .environmentObject(TruoraTheme(config: nil))
    }
    .frame(height: 150)
}
