//
//  FaceValidationConfig.swift
//  TruoraValidationsSDK
//
//  Created by Truora on 17/11/25.
//

import Foundation

// MARK: - Face Validation Configuration

/// Configuration for Face Capture validation.
/// Use the builder pattern to configure face validation parameters.
public class Face {
    private var _referenceFace: ReferenceFace?
    private var _similarityThreshold: Float?
    private var _waitForResults: Bool = false
    private var _useAutocapture: Bool = true
    private var _timeout: Int?
    private var _finishViewConfig: FinishViewConfiguration?

    public required init() {}

    public var referenceFace: ReferenceFace? {
        _referenceFace
    }

    public var similarityThreshold: Float? {
        _similarityThreshold
    }

    public var waitForResults: Bool {
        _waitForResults
    }

    public var useAutocapture: Bool {
        _useAutocapture
    }

    public var timeout: Int? {
        _timeout
    }

    public var finishViewConfig: FinishViewConfiguration? {
        _finishViewConfig
    }

    /// Sets the reference face image to compare against.
    ///
    /// - Parameter referenceFace: The reference face image source
    /// - Returns: This Face for method chaining
    @discardableResult
    public func useReferenceFace(_ referenceFace: ReferenceFace) -> Face {
        _referenceFace = referenceFace
        return self
    }

    /// Sets the similarity threshold for face comparison.
    /// Values outside the valid range (0.0 to 1.0) will be clamped automatically.
    ///
    /// - Parameter threshold: A value between 0.0 and 1.0 representing the required similarity
    /// - Returns: This Face for method chaining
    @discardableResult
    public func setSimilarityThreshold(_ threshold: Float) -> Face {
        _similarityThreshold = min(max(threshold, 0.0), 1.0)
        return self
    }

    /// Sets whether to wait and show the validation results to the user.
    ///
    /// - Precondition: Cannot be set to `false` when a `FinishViewConfiguration`
    ///   is already set, because finish view visibility requires waiting for results.
    ///   Remove `setFinishViewConfiguration()` first or keep `waitForResults` enabled.
    /// - Parameter enabled: true to show results view, false to skip it (default: false)
    /// - Returns: This Face for method chaining
    @discardableResult
    public func waitForResults(_ enabled: Bool) -> Face {
        if !enabled, _finishViewConfig != nil {
            preconditionFailure(
                "waitForResults(false) cannot be called when "
                    + "finishViewConfiguration is set. Remove "
                    + "setFinishViewConfiguration() first."
            )
        }
        _waitForResults = enabled
        return self
    }

    /// Sets whether to enable auto-detect and auto-capture of the face.
    ///
    /// - Parameter enabled: true to enable auto-capture, false for manual capture (default: true)
    /// - Returns: This Face for method chaining
    @discardableResult
    public func useAutocapture(_ enabled: Bool) -> Face {
        _useAutocapture = enabled
        return self
    }

    /// Sets the timeout in seconds for completing the validation.
    /// Negative values will be clamped to 0.
    ///
    /// - Parameter seconds: The timeout duration in seconds (default: 60)
    /// - Returns: This Face for method chaining
    @discardableResult
    public func setTimeout(_ seconds: Int) -> Face {
        _timeout = max(seconds, 0)
        return self
    }

    /// Configures the visibility of finish view screens after polling completes.
    ///
    /// - Important: Requires `waitForResults` to be `true` (or not explicitly disabled).
    ///   The SDK will throw an `invalidConfiguration` error at start time if both
    ///   `finishViewConfiguration` is set and `waitForResults` is `false`.
    /// - Parameter config: Configuration controlling success/failure screen visibility
    /// - Returns: This Face for method chaining
    @discardableResult
    public func setFinishViewConfiguration(_ config: FinishViewConfiguration) -> Face {
        _finishViewConfig = config
        _waitForResults = true
        return self
    }
}
