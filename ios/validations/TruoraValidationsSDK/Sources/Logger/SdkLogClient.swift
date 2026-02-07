//
//  SdkLogClient.swift
//  TruoraValidationsSDK
//
//  Created by AI Assistant on 2025-02-01.
//

import Foundation

/// HTTP client for SDK log API.
///
/// This is the Swift equivalent of the KMP SdkLogClient.
/// Handles batch event logging to /v1/sdk/log endpoint with retry logic.
///
/// Memory Management:
/// - If urlSession is provided via constructor, it is assumed to be externally managed
///   and close() will NOT invalidate it
/// - If urlSession is not provided, a new one is created and close() will invalidate it
public actor SdkLogClient {
    // MARK: - Constants

    private static let sdkName = "truora-validations-sdk"
    private static let maxRetries = 3
    private static let baseDelayMs: Int64 = 1000
    private static let maxDelayMs: Int64 = 10000

    // MARK: - Properties

    private let baseUrl: String
    private let apiKey: String
    private let sdkVersion: String
    private let externalUrlSession: URLSession?
    private let internalUrlSession: URLSession?

    private var urlSession: URLSession {
        if let external = externalUrlSession {
            return external
        }
        // internalUrlSession is guaranteed to be non-nil by init if external is nil
        return internalUrlSession ?? SdkLogClient.createDefaultSession()
    }

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    // MARK: - Initialization

    /// Creates a new SdkLogClient.
    ///
    /// - Parameters:
    ///   - baseUrl: Base URL for the API (default: https://api.validations.truora.com/v1)
    ///   - apiKey: API key for authentication
    ///   - sdkVersion: SDK version string
    ///   - urlSession: Optional external URLSession (if nil, creates internal session)
    /// - Throws: SdkLogClientError if configuration is invalid
    public init(
        baseUrl: String = "https://api.validations.truora.com/v1",
        apiKey: String,
        sdkVersion: String,
        urlSession: URLSession? = nil
    ) throws {
        guard !apiKey.isEmpty else {
            throw SdkLogClientError.invalidConfiguration("apiKey cannot be empty")
        }
        guard URL(string: "\(baseUrl)/sdk/log") != nil else {
            throw SdkLogClientError.invalidConfiguration("Invalid URL configuration")
        }

        self.baseUrl = baseUrl
        self.apiKey = apiKey
        self.sdkVersion = sdkVersion
        self.externalUrlSession = urlSession
        self.internalUrlSession = urlSession == nil ? SdkLogClient.createDefaultSession() : nil

        // Configure JSON encoder/decoder
        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .useDefaultKeys
        self.encoder.dateEncodingStrategy = .iso8601

        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .useDefaultKeys
        self.decoder.dateDecodingStrategy = .iso8601
    }

    /// Creates a default URLSession with timeout configuration.
    private static func createDefaultSession() -> URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 30.0
        config.waitsForConnectivity = true
        return URLSession(configuration: config)
    }

    // MARK: - Public Methods

    /// Send SDK log batch to the server.
    ///
    /// - Parameter sdkLog: The SDK log batch containing events to log
    /// - Returns: SDKLogResponse with confirmation details
    /// - Throws: SdkLogClientError if validation or request fails
    public func log(_ sdkLog: SDKLog) async throws -> SDKLogResponse {
        // Validate the request
        do {
            try sdkLog.validate()
        } catch let error as SdkLogValidationError {
            #if DEBUG
            print("🔴 [SdkLogClient] Validation failed: \(error)")
            #endif
            throw SdkLogClientError.validationFailed(error)
        }

        let normalizedLog = sdkLog.normalized()

        // Perform request with retry logic
        return try await performLogRequest(normalizedLog)
    }

    /// Close the HTTP client and release resources.
    ///
    /// Only invalidates internally created URLSession.
    /// If URLSession was provided externally, it's the caller's responsibility to invalidate it.
    public func close() async {
        internalUrlSession?.invalidateAndCancel()
    }

    // MARK: - Private Methods

    private func performLogRequest(_ sdkLog: SDKLog) async throws -> SDKLogResponse {
        let request = try buildRequest(sdkLog: sdkLog)
        return try await executeWithRetry(request: request)
    }

    private func buildRequest(sdkLog: SDKLog) throws -> URLRequest {
        guard let url = URL(string: "\(baseUrl)/sdk/log") else {
            throw SdkLogClientError.networkError("Invalid URL: \(baseUrl)/sdk/log")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "Truora-API-Key")
        request.addValue(buildUserAgent(), forHTTPHeaderField: "User-Agent")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        do {
            request.httpBody = try encoder.encode(sdkLog)
        } catch {
            throw SdkLogClientError.requestFailed(
                type: "encoding",
                message: "Failed to encode SDKLog: \(error.localizedDescription)"
            )
        }

        return request
    }

    private func executeWithRetry(request: URLRequest) async throws -> SDKLogResponse {
        var lastError: Error?

        for attempt in 0 ..< SdkLogClient.maxRetries {
            do {
                return try await executeSingleRequest(request: request)
            } catch let error as SdkLogClientError {
                throw error
            } catch let error as URLError {
                lastError = error
                if attempt < SdkLogClient.maxRetries - 1 {
                    #if DEBUG
                    print("⚠️ [SdkLogClient] Network error, retrying...")
                    print("Attempt \(attempt + 1)/\(SdkLogClient.maxRetries): \(error)")
                    #endif
                    await delay(attempt: attempt)
                    continue
                }
            } catch {
                lastError = error
                if attempt < SdkLogClient.maxRetries - 1 {
                    #if DEBUG
                    print("⚠️ [SdkLogClient] Error, retrying...")
                    print("Attempt \(attempt + 1)/\(SdkLogClient.maxRetries): \(error)")
                    #endif
                    await delay(attempt: attempt)
                    continue
                }
            }
        }

        throw lastError.map { SdkLogClientError.unknown($0) }
            ?? SdkLogClientError.requestFailed(type: "retry_exhausted", message: "All retry attempts failed")
    }

    private func executeSingleRequest(request: URLRequest) async throws -> SDKLogResponse {
        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SdkLogClientError.invalidResponse
        }

        if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
            do {
                return try decoder.decode(SDKLogResponse.self, from: data)
            } catch {
                throw SdkLogClientError.decodingError(error)
            }
        }

        let isRetryable = (500 ... 599).contains(httpResponse.statusCode) || httpResponse.statusCode == 429
        if isRetryable {
            throw URLError(.unknown)
        }

        let responseBody = String(data: data, encoding: .utf8)
        throw SdkLogClientError.fromHttpStatus(
            statusCode: httpResponse.statusCode,
            responseBody: responseBody
        )
    }

    private func delay(attempt: Int) async {
        let delayMs = calculateDelay(attempt: attempt)
        do {
            try await Task.sleep(nanoseconds: UInt64(delayMs) * 1_000_000)
        } catch is CancellationError {
            // Task cancelled, stop retrying
            return
        } catch {
            // Ignore other errors (unlikely for sleep)
        }
    }

    /// Calculate exponential backoff delay.
    private func calculateDelay(attempt: Int) -> Int64 {
        // Prevent overflow: clamp attempt to safe range
        let safeAttempt = min(attempt, 30)
        let exponentialDelay = SdkLogClient.baseDelayMs * Int64(pow(2.0, Double(safeAttempt)))
        return min(exponentialDelay, SdkLogClient.maxDelayMs)
    }

    /// Build User-Agent header.
    /// Format: truora-validations-sdk/2.1.0
    private func buildUserAgent() -> String {
        "\(Self.sdkName)/\(sdkVersion)"
    }
}

// MARK: - SdkLogClientError Extension

extension SdkLogClientError {
    /// Decoding error case
    static func decodingError(_ error: Error) -> SdkLogClientError {
        .requestFailed(type: "decoding", message: "Failed to decode response: \(error.localizedDescription)")
    }
}

// MARK: - Math Helper

import Darwin

private func pow(_ base: Double, _ exponent: Double) -> Double {
    Darwin.pow(base, exponent)
}
