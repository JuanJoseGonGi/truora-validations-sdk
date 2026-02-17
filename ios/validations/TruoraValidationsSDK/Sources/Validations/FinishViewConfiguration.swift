//
//  FinishViewConfiguration.swift
//  TruoraValidationsSDK
//
//  Created by Truora on 05/02/26.
//

import Foundation

// MARK: - Finish View Visibility

/// Controls whether a finish view screen is shown or hidden after polling completes.
public enum FinishViewVisibility: Equatable {
    /// Show the result screen to the user. The user must tap "Done" to dismiss.
    case show
    /// Hide the result screen. The SDK auto-dismisses and calls the delegate immediately.
    case hide
}

// MARK: - Finish View Configuration

/// Configuration for controlling the visibility of success and failure screens
/// shown after validation polling completes.
///
/// Setting this configuration implicitly enables `waitForResults`.
/// The SDK will always poll for results, but you can control whether the
/// success and/or failure screens are displayed to the user.
///
/// Example:
/// ```swift
/// .withValidation { (face: Face) in
///     face.setFinishViewConfiguration(
///         FinishViewConfiguration(success: .hide, failure: .show)
///     )
/// }
/// ```
public struct FinishViewConfiguration: Equatable {
    /// Controls visibility of the success result screen.
    public let success: FinishViewVisibility
    /// Controls visibility of the failure result screen.
    public let failure: FinishViewVisibility

    /// Creates a new finish view configuration.
    /// - Parameters:
    ///   - success: Whether to show or hide the success screen (default: `.show`)
    ///   - failure: Whether to show or hide the failure screen (default: `.show`)
    public init(
        success: FinishViewVisibility = .show,
        failure: FinishViewVisibility = .show
    ) {
        self.success = success
        self.failure = failure
    }
}
