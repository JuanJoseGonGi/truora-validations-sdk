//
//  SdkLogValidationError.swift
//  TruoraValidationsSDK
//
//  Created by AI Assistant on 2025-02-01.
//

import Foundation

/// Validation error codes for SDK log requests.
///
/// This is the Swift equivalent of the KMP SdkLogValidationCode enum.
public enum SdkLogValidationCode {
    case emptySdkVersion
    case emptyPlatform
    case invalidPlatform
    case emptyEvents
    case tooManyEvents
    case invalidEventName
    case eventNameTooLong
    case invalidDuration

    /// Human-readable error message
    public var message: String {
        switch self {
        case .emptySdkVersion:
            "SDK version is empty"
        case .emptyPlatform:
            "Platform is empty"
        case .invalidPlatform:
            "Platform must be 'android' or 'ios'"
        case .emptyEvents:
            "Events list is empty"
        case .tooManyEvents:
            "Too many events per request (maximum 50)"
        case .invalidEventName:
            "Event name cannot be blank"
        case .eventNameTooLong:
            "Event name exceeds 35 characters"
        case .invalidDuration:
            "Duration must be non-negative"
        }
    }
}

/// Validation error for SDK log requests.
///
/// This is the Swift equivalent of the KMP SdkLogValidationException.
public struct SdkLogValidationError: Error, LocalizedError {
    public let code: SdkLogValidationCode

    public init(code: SdkLogValidationCode) {
        self.code = code
    }

    public var errorDescription: String? {
        code.message
    }
}

// MARK: - SdkLog Client Errors

/// Error types for SDK log client operations.
public enum SdkLogClientError: Error, LocalizedError {
    case validationFailed(SdkLogValidationError)
    case invalidConfiguration(String)
    case networkError(String)
    case timeout(type: TimeoutType)
    case serverError(statusCode: Int, responseBody: String?)
    case requestFailed(type: String, message: String)
    case invalidResponse
    case unknown(Error)

    public enum TimeoutType {
        case request
        case connect
        case socket
    }

    public var errorDescription: String? {
        switch self {
        case .validationFailed(let error):
            "Validation failed: \(error.localizedDescription ?? "Unknown")"
        case .invalidConfiguration(let message):
            "Invalid configuration: \(message)"
        case .networkError(let message):
            "Network error: \(message)"
        case .timeout(let type):
            "Timeout: \(type) timeout occurred"
        case .serverError(let statusCode, let body):
            "Server error \(statusCode): \(body ?? "No response body")"
        case .requestFailed(let type, let message):
            "Request failed (\(type)): \(message)"
        case .invalidResponse:
            "Invalid response from server"
        case .unknown(let error):
            "Unknown error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Helper Extensions

extension SdkLogClientError {
    /// Create error from HTTP status code
    static func fromHttpStatus(statusCode: Int, responseBody: String?) -> SdkLogClientError {
        switch statusCode {
        case 400:
            .serverError(statusCode: statusCode, responseBody: responseBody ?? "Bad Request")
        case 401:
            .serverError(statusCode: statusCode, responseBody: responseBody ?? "Unauthorized")
        case 403:
            .serverError(statusCode: statusCode, responseBody: responseBody ?? "Forbidden")
        case 404:
            .serverError(statusCode: statusCode, responseBody: responseBody ?? "Not Found")
        case 429:
            .serverError(statusCode: statusCode, responseBody: responseBody ?? "Rate Limited")
        case 500 ... 599:
            .serverError(statusCode: statusCode, responseBody: responseBody ?? "Server Error")
        default:
            .serverError(statusCode: statusCode, responseBody: responseBody ?? "Unknown Error")
        }
    }
}
