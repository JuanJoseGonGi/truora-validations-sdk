//
//  DocumentValidationConfig.swift
//  TruoraValidationsSDK
//
//  Created by Truora on 07/01/26.
//

import Foundation

// MARK: - Document Validation Configuration

/// Configuration for Document Capture validation.
/// Use the builder pattern to configure document validation parameters.
///
/// - Note: If `country` and `documentType` are not explicitly set, a document selection
///   view will be presented to collect these inputs from the user before proceeding.
///
/// Example:
/// ```swift
/// .withValidation { (document: Document) in
///     document
///         .setCountry("PE")
///         .setDocumentType("national-id")
/// }
/// ```
public class Document {
    private var _country: String = ""
    private var _documentType: String = ""
    private var _waitForResults: Bool = false
    private var _useAutocapture: Bool = true
    private var _didExplicitlyEnableAutocapture: Bool = false
    private var _timeout: Int?
    private var _finishViewConfig: FinishViewConfiguration?

    public required init() {}

    public var country: String {
        _country
    }

    public var documentType: String {
        _documentType
    }

    public var waitForResults: Bool {
        _waitForResults
    }

    public var useAutocapture: Bool {
        _useAutocapture
    }

    /// Whether the developer explicitly called ``useAutocapture(true)``.
    /// Used by ``ValidationConfig`` defense-in-depth validation to distinguish
    /// explicit opt-in from the default `true` value.
    var didExplicitlyEnableAutocapture: Bool {
        _didExplicitlyEnableAutocapture
    }

    public var timeout: Int? {
        _timeout
    }

    public var finishViewConfig: FinishViewConfiguration? {
        _finishViewConfig
    }

    /// Sets the country code for document validation.
    ///
    /// - Note: If not set, a document selection view will be shown to collect this from the user.
    /// - Parameter country: ISO 3166-1 alpha-2 country code (e.g., "PE", "CO", "MX").
    /// - Returns: This Document for method chaining
    @discardableResult
    public func setCountry(_ country: String) -> Document {
        _country = country
        return self
    }

    /// Sets the document type for validation.
    ///
    /// - Precondition: Cannot be set to `"passport"` when autocapture has been explicitly enabled,
    ///   because autocapture is not supported for passport documents.
    /// - Note: If not set, a document selection view will be shown to collect this from the user.
    /// - Parameter documentType: The document type identifier (e.g., "national-id", "passport",
    ///   "driver-license").
    /// - Returns: This Document for method chaining
    @discardableResult
    public func setDocumentType(_ documentType: String) -> Document {
        if documentType == NativeDocumentType.passport.rawValue, _didExplicitlyEnableAutocapture {
            preconditionFailure(
                "Autocapture is not supported for passport document type. "
                    + "Remove useAutocapture(true) or use a different document type."
            )
        }
        _documentType = documentType
        return self
    }

    /// Sets whether to wait and show the validation results to the user.
    ///
    /// - Precondition: Cannot be set to `false` when a `FinishViewConfiguration`
    ///   is already set, because finish view visibility requires waiting for results.
    ///   Remove `setFinishViewConfiguration()` first or keep `waitForResults` enabled.
    /// - Parameter enabled: true to show results view, false to skip it (default: false)
    /// - Returns: This Document for method chaining
    @discardableResult
    public func waitForResults(_ enabled: Bool) -> Document {
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

    /// Sets whether to enable auto-detect and auto-capture of the document.
    ///
    /// - Precondition: Cannot be set to `true` when the document type is `passport`,
    ///   because autocapture is not supported for passport documents.
    /// - Parameter enabled: true to enable auto-capture, false for manual capture (default: true)
    /// - Returns: This Document for method chaining
    @discardableResult
    public func useAutocapture(_ enabled: Bool) -> Document {
        if enabled, _documentType == NativeDocumentType.passport.rawValue {
            preconditionFailure(
                "useAutocapture(true) is not supported for passport document type. "
                    + "Autocapture does not work reliably with passports. "
                    + "Remove useAutocapture(true) or use a different document type."
            )
        }
        _useAutocapture = enabled
        _didExplicitlyEnableAutocapture = enabled
        return self
    }

    /// Sets the timeout in seconds for completing the validation.
    /// Negative values will be clamped to 0.
    ///
    /// - Parameter seconds: The timeout duration in seconds (default: 60)
    /// - Returns: This Document for method chaining
    @discardableResult
    public func setTimeout(_ seconds: Int) -> Document {
        _timeout = max(seconds, 0)
        return self
    }

    /// Configures the visibility of finish view screens after polling completes.
    ///
    /// - Important: Requires `waitForResults` to be `true` (or not explicitly disabled).
    ///   The SDK will throw an `invalidConfiguration` error at start time if both
    ///   `finishViewConfiguration` is set and `waitForResults` is `false`.
    /// - Parameter config: Configuration controlling success/failure screen visibility
    /// - Returns: This Document for method chaining
    @discardableResult
    public func setFinishViewConfiguration(_ config: FinishViewConfiguration) -> Document {
        _finishViewConfig = config
        _waitForResults = true
        return self
    }
}
