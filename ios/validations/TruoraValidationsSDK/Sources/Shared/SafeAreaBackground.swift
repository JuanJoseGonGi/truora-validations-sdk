//
//  SafeAreaBackground.swift
//  TruoraValidationsSDK
//
//  Use for backgrounds only: color (or full-bleed layer) extends into safe
//  area so edges are filled; container content stays inside safe area.
//  iOS 13+: uses edgesIgnoringSafeArea; iOS 14+: uses ignoresSafeArea.
//

import SwiftUI

extension Color {
    /// Returns this color as a view that extends into the safe area.
    /// Use only for backgrounds so content stays inside safe area.
    @ViewBuilder
    func extendingIntoSafeArea() -> some View {
        if #available(iOS 14.0, *) {
            self.ignoresSafeArea(edges: .all)
        } else {
            self.edgesIgnoringSafeArea(.all)
        }
    }
}

extension View {
    /// Applies safe-area extension for full-bleed layers (e.g. camera, overlay).
    /// Use when the entire view should extend into safe area.
    @ViewBuilder
    func extendingIntoSafeArea() -> some View {
        if #available(iOS 14.0, *) {
            self.ignoresSafeArea(edges: .all)
        } else {
            self.edgesIgnoringSafeArea(.all)
        }
    }
}
