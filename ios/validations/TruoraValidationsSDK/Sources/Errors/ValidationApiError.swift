//
//  ValidationApiError.swift
//  TruoraValidationsSDK
//
//  Created by Truora on 22/01/26.
//

import Foundation

/// Enum representing errors returned by the Validations API
///
/// Known errors have explicit types, while unknown errors are wrapped in Unknown
///
/// Note: Most API "failures" (expired, declined, system error) are returned as
/// completed validation results with failure status, not as errors.
/// Only authentication errors and unknown errors are thrown as exceptions.
public enum ValidationApiError: Error, LocalizedError, Equatable {
    /// Temporary API key has expired (HTTP 403)
    case expiredApiKey(httpCode: Int)

    /// Generic wrapper for unknown API errors
    case unknown(httpCode: Int, message: String)

    /// The error code for this validation API error
    public var code: Int {
        switch self {
        case .expiredApiKey:
            30003
        case .unknown:
            30000
        }
    }

    /// The HTTP status code associated with this error
    public var httpCode: Int {
        switch self {
        case .expiredApiKey(let httpCode):
            httpCode
        case .unknown(let httpCode, _):
            httpCode
        }
    }

    /// Localized error description
    public var errorDescription: String? {
        switch self {
        case .expiredApiKey:
            "The temporary api key has expired. Please try again"
        case .unknown(_, let message):
            message
        }
    }
}
