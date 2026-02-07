//
//  LoggerConfiguration.swift
//  TruoraValidationsSDK
//
//  Created by AI Assistant on 2025-02-01.
//

import Foundation

/// Configuration for the Truora SDK logger.
///
/// Defines buffering behavior, flush intervals, and output destinations.
/// All properties are immutable (let) for thread safety.
public struct LoggerConfiguration: Sendable {
    // MARK: - API Configuration

    /// API key for authentication with Truora logging endpoint
    public let apiKey: String

    /// SDK version string (e.g., "1.2.3")
    public let sdkVersion: String

    /// Base URL for the logging API endpoint
    public let loggingEndpoint: String

    // MARK: - Buffer Configuration

    /// Maximum number of events to buffer before auto-flush
    /// Default: 20 events
    public let maxBufferSize: Int

    /// Interval between automatic flushes (in milliseconds)
    /// Default: 30000 (30 seconds)
    public let flushIntervalMs: Int64

    // MARK: - Sampling Configuration

    /// Sampling rate for events (1.0 = 100%, 0.0 = 0%)
    /// Default: 1.0 (keep all events)
    public let sampleRate: Double

    /// Sampling rate for error events (should typically be 1.0)
    /// Default: 1.0 (keep all errors)
    public let errorSampleRate: Double

    // MARK: - Output Configuration

    /// Enable console output in DEBUG builds
    /// Default: true
    public let enableConsoleOutput: Bool

    /// Enable sending to Truora API endpoint
    /// Default: true
    public let enableApiOutput: Bool

    // MARK: - Initialization

    /// Creates a new logger configuration
    ///
    /// - Parameters:
    ///   - apiKey: API key for authentication
    ///   - sdkVersion: SDK version string
    ///   - loggingEndpoint: Base URL for logging API
    ///   - maxBufferSize: Maximum events in buffer (default: 20)
    ///   - flushIntervalMs: Auto-flush interval in ms (default: 30000)
    ///   - sampleRate: Sampling rate 0.0-1.0 (default: 1.0)
    ///   - errorSampleRate: Error sampling rate (default: 1.0)
    ///   - enableConsoleOutput: Console output in DEBUG (default: true)
    ///   - enableApiOutput: Send to Truora API (default: true)
    public init(
        apiKey: String,
        sdkVersion: String,
        loggingEndpoint: String = "https://api.validations.truora.com/v1",
        maxBufferSize: Int = 20,
        flushIntervalMs: Int64 = 30000,
        sampleRate: Double = 1.0,
        errorSampleRate: Double = 1.0,
        enableConsoleOutput: Bool = true,
        enableApiOutput: Bool = true
    ) {
        guard !apiKey.isEmpty else {
            preconditionFailure("apiKey cannot be empty")
        }
        guard !sdkVersion.isEmpty else {
            preconditionFailure("sdkVersion cannot be empty")
        }
        guard URL(string: loggingEndpoint) != nil else {
            preconditionFailure("Invalid loggingEndpoint URL: \(loggingEndpoint)")
        }
        guard maxBufferSize > 0 else {
            preconditionFailure("maxBufferSize must be positive")
        }
        guard flushIntervalMs >= 1000 else {
            preconditionFailure("flushIntervalMs must be at least 1000ms")
        }

        self.apiKey = apiKey
        self.sdkVersion = sdkVersion
        self.loggingEndpoint = loggingEndpoint
        self.maxBufferSize = maxBufferSize
        self.flushIntervalMs = flushIntervalMs
        self.sampleRate = max(0.0, min(1.0, sampleRate)) // Clamp to 0.0-1.0
        self.errorSampleRate = max(0.0, min(1.0, errorSampleRate)) // Clamp to 0.0-1.0
        self.enableConsoleOutput = enableConsoleOutput
        self.enableApiOutput = enableApiOutput
    }

    // MARK: - Preset Configurations

    /// Configuration for production use (no console output)
    public static func production(apiKey: String, sdkVersion: String) -> LoggerConfiguration {
        LoggerConfiguration(
            apiKey: apiKey,
            sdkVersion: sdkVersion,
            enableConsoleOutput: false,
            enableApiOutput: true
        )
    }

    /// Configuration for development (verbose console output)
    public static func development(apiKey: String, sdkVersion: String) -> LoggerConfiguration {
        LoggerConfiguration(
            apiKey: apiKey,
            sdkVersion: sdkVersion,
            maxBufferSize: 10, // Smaller buffer for faster feedback
            flushIntervalMs: 5000, // 5 seconds for faster feedback
            enableConsoleOutput: true,
            enableApiOutput: true
        )
    }

    /// Configuration for testing (no API calls)
    public static func testing() -> LoggerConfiguration {
        LoggerConfiguration(
            apiKey: "test-key",
            sdkVersion: "1.0.0",
            enableConsoleOutput: false,
            enableApiOutput: false
        )
    }
}
