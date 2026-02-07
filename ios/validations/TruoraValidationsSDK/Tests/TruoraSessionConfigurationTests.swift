//
//  TruoraSessionConfigurationTests.swift
//  TruoraValidationsSDKTests
//
//  Created by Truora on 27/01/26.
//

import XCTest
@testable import TruoraValidationsSDK

// MARK: - Test Helpers

private struct RetryURLProtocolStubResponse {
    let data: Data?
    let response: URLResponse?
    let error: Error?
}

private final class RetryURLProtocolStub: URLProtocol {
    static var responses: [RetryURLProtocolStubResponse] = []
    static var requestCount = 0

    static func reset() {
        responses = []
        requestCount = 0
    }

    override static func canInit(with _: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let index = min(Self.requestCount, Self.responses.count - 1)
        Self.requestCount += 1

        guard index >= 0, index < Self.responses.count else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        let stub = Self.responses[index]

        if let response = stub.response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        if let data = stub.data {
            client?.urlProtocol(self, didLoad: data)
        }
        if let error = stub.error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {}
}

// MARK: - Tests

@MainActor final class TruoraSessionConfigurationTests: XCTestCase {
    private var sut: TruoraSessionConfiguration!
    private var session: URLSession!

    override func setUp() {
        super.setUp()
        RetryURLProtocolStub.reset()

        // Use fast retry for tests
        sut = TruoraSessionConfiguration(
            timeoutIntervalForRequest: 5,
            timeoutIntervalForResource: 10,
            waitsForConnectivity: false,
            maxRetries: 3,
            retryBaseDelay: 0.1,
            retryMaxDelay: 0.5
        )

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [RetryURLProtocolStub.self]
        session = URLSession(configuration: config)
    }

    override func tearDown() {
        RetryURLProtocolStub.reset()
        sut = nil
        session = nil
        super.tearDown()
    }

    // MARK: - Configuration Tests

    func testDefaultConfiguration_hasExpectedValues() {
        let config = TruoraSessionConfiguration.default

        XCTAssertEqual(config.timeoutIntervalForRequest, 30)
        XCTAssertEqual(config.timeoutIntervalForResource, 300)
        XCTAssertTrue(config.waitsForConnectivity)
        XCTAssertEqual(config.maxRetries, 3)
        XCTAssertEqual(config.retryBaseDelay, 1.0)
        XCTAssertEqual(config.retryMaxDelay, 10.0)
    }

    func testNoRetryConfiguration_hasZeroRetries() {
        let config = TruoraSessionConfiguration.noRetry

        XCTAssertEqual(config.maxRetries, 0)
    }

    func testCreateSession_appliesConfiguration() {
        let config = TruoraSessionConfiguration(
            timeoutIntervalForRequest: 15,
            timeoutIntervalForResource: 60,
            waitsForConnectivity: true
        )

        let session = config.createSession()

        XCTAssertEqual(session.configuration.timeoutIntervalForRequest, 15)
        XCTAssertEqual(session.configuration.timeoutIntervalForResource, 60)
        XCTAssertTrue(session.configuration.waitsForConnectivity)
    }

    // MARK: - Success Tests

    func testPerform_success_returnsDataAndResponse() async throws {
        // Given
        let expectedData = "test response".data(using: .utf8)!
        let response = try XCTUnwrap(try HTTPURLResponse(
            url: XCTUnwrap(URL(string: "https://example.com")),
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        ))
        RetryURLProtocolStub.responses = [
            RetryURLProtocolStubResponse(data: expectedData, response: response, error: nil)
        ]

        let request = try URLRequest(url: XCTUnwrap(URL(string: "https://example.com")))

        // When
        let (data, urlResponse) = try await sut.perform(request, using: session)

        // Then
        XCTAssertEqual(data, expectedData)
        XCTAssertEqual((urlResponse as? HTTPURLResponse)?.statusCode, 200)
        XCTAssertEqual(RetryURLProtocolStub.requestCount, 1)
    }

    // MARK: - Retry on Network Error Tests

    func testPerform_retriesOnTimeout_thenSucceeds() async throws {
        // Given - First request times out, second succeeds
        let expectedData = "success".data(using: .utf8)!
        let successResponse = try XCTUnwrap(try HTTPURLResponse(
            url: XCTUnwrap(URL(string: "https://example.com")),
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        ))
        RetryURLProtocolStub.responses = [
            RetryURLProtocolStubResponse(data: nil, response: nil, error: URLError(.timedOut)),
            RetryURLProtocolStubResponse(data: expectedData, response: successResponse, error: nil)
        ]

        let request = try URLRequest(url: XCTUnwrap(URL(string: "https://example.com")))

        // When
        let (data, _) = try await sut.perform(request, using: session)

        // Then
        XCTAssertEqual(data, expectedData)
        XCTAssertEqual(RetryURLProtocolStub.requestCount, 2)
    }

    func testPerform_retriesOnConnectionLost_thenSucceeds() async throws {
        // Given
        let expectedData = "success".data(using: .utf8)!
        let successResponse = try XCTUnwrap(try HTTPURLResponse(
            url: XCTUnwrap(URL(string: "https://example.com")),
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        ))
        RetryURLProtocolStub.responses = [
            RetryURLProtocolStubResponse(data: nil, response: nil, error: URLError(.networkConnectionLost)),
            RetryURLProtocolStubResponse(data: expectedData, response: successResponse, error: nil)
        ]

        let request = try URLRequest(url: XCTUnwrap(URL(string: "https://example.com")))

        // When
        let (data, _) = try await sut.perform(request, using: session)

        // Then
        XCTAssertEqual(data, expectedData)
        XCTAssertEqual(RetryURLProtocolStub.requestCount, 2)
    }

    func testPerform_retriesOnNotConnected_thenSucceeds() async throws {
        // Given
        let expectedData = "success".data(using: .utf8)!
        let successResponse = try XCTUnwrap(try HTTPURLResponse(
            url: XCTUnwrap(URL(string: "https://example.com")),
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        ))
        RetryURLProtocolStub.responses = [
            RetryURLProtocolStubResponse(data: nil, response: nil, error: URLError(.notConnectedToInternet)),
            RetryURLProtocolStubResponse(data: expectedData, response: successResponse, error: nil)
        ]

        let request = try URLRequest(url: XCTUnwrap(URL(string: "https://example.com")))

        // When
        let (data, _) = try await sut.perform(request, using: session)

        // Then
        XCTAssertEqual(data, expectedData)
        XCTAssertEqual(RetryURLProtocolStub.requestCount, 2)
    }

    // MARK: - Retry on HTTP Status Code Tests

    func testPerform_retriesOn503_thenSucceeds() async throws {
        // Given
        let expectedData = "success".data(using: .utf8)!
        let errorResponse = try XCTUnwrap(try HTTPURLResponse(
            url: XCTUnwrap(URL(string: "https://example.com")),
            statusCode: 503,
            httpVersion: nil,
            headerFields: nil
        ))
        let successResponse = try XCTUnwrap(try HTTPURLResponse(
            url: XCTUnwrap(URL(string: "https://example.com")),
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        ))
        RetryURLProtocolStub.responses = [
            RetryURLProtocolStubResponse(data: Data(), response: errorResponse, error: nil),
            RetryURLProtocolStubResponse(data: expectedData, response: successResponse, error: nil)
        ]

        let request = try URLRequest(url: XCTUnwrap(URL(string: "https://example.com")))

        // When
        let (data, response) = try await sut.perform(request, using: session)

        // Then
        XCTAssertEqual(data, expectedData)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
        XCTAssertEqual(RetryURLProtocolStub.requestCount, 2)
    }

    func testPerform_retriesOn429_thenSucceeds() async throws {
        // Given
        let expectedData = "success".data(using: .utf8)!
        let rateLimitResponse = try XCTUnwrap(try HTTPURLResponse(
            url: XCTUnwrap(URL(string: "https://example.com")),
            statusCode: 429,
            httpVersion: nil,
            headerFields: nil
        ))
        let successResponse = try XCTUnwrap(try HTTPURLResponse(
            url: XCTUnwrap(URL(string: "https://example.com")),
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        ))
        RetryURLProtocolStub.responses = [
            RetryURLProtocolStubResponse(data: Data(), response: rateLimitResponse, error: nil),
            RetryURLProtocolStubResponse(data: expectedData, response: successResponse, error: nil)
        ]

        let request = try URLRequest(url: XCTUnwrap(URL(string: "https://example.com")))

        // When
        let (data, _) = try await sut.perform(request, using: session)

        // Then
        XCTAssertEqual(data, expectedData)
        XCTAssertEqual(RetryURLProtocolStub.requestCount, 2)
    }

    // MARK: - Max Retries Exhausted Tests

    func testPerform_exhaustsRetries_throwsLastError() async throws {
        // Given - All requests fail with timeout
        RetryURLProtocolStub.responses = [
            RetryURLProtocolStubResponse(data: nil, response: nil, error: URLError(.timedOut)),
            RetryURLProtocolStubResponse(data: nil, response: nil, error: URLError(.timedOut)),
            RetryURLProtocolStubResponse(data: nil, response: nil, error: URLError(.timedOut)),
            RetryURLProtocolStubResponse(data: nil, response: nil, error: URLError(.timedOut))
        ]

        let request = try URLRequest(url: XCTUnwrap(URL(string: "https://example.com")))

        // When/Then
        do {
            _ = try await sut.perform(request, using: session)
            XCTFail("Should have thrown error")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .timedOut)
            // Initial attempt + 3 retries = 4 total
            XCTAssertEqual(RetryURLProtocolStub.requestCount, 4)
        }
    }

    func testPerform_exhaustsRetriesOn503_returnsLastResponse() async throws {
        // Given - All requests return 503
        let errorResponse = try XCTUnwrap(try HTTPURLResponse(
            url: XCTUnwrap(URL(string: "https://example.com")),
            statusCode: 503,
            httpVersion: nil,
            headerFields: nil
        ))
        RetryURLProtocolStub.responses = [
            RetryURLProtocolStubResponse(data: Data(), response: errorResponse, error: nil),
            RetryURLProtocolStubResponse(data: Data(), response: errorResponse, error: nil),
            RetryURLProtocolStubResponse(data: Data(), response: errorResponse, error: nil),
            RetryURLProtocolStubResponse(data: Data(), response: errorResponse, error: nil)
        ]

        let request = try URLRequest(url: XCTUnwrap(URL(string: "https://example.com")))

        // When
        let (_, response) = try await sut.perform(request, using: session)

        // Then - Returns the 503 response after exhausting retries
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 503)
        XCTAssertEqual(RetryURLProtocolStub.requestCount, 4)
    }

    // MARK: - Non-Retryable Error Tests

    func testPerform_doesNotRetryOnNonRetryableError() async throws {
        // Given - 401 Unauthorized is not retryable
        let unauthorizedResponse = try XCTUnwrap(try HTTPURLResponse(
            url: XCTUnwrap(URL(string: "https://example.com")),
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        ))
        RetryURLProtocolStub.responses = [
            RetryURLProtocolStubResponse(data: Data(), response: unauthorizedResponse, error: nil)
        ]

        let request = try URLRequest(url: XCTUnwrap(URL(string: "https://example.com")))

        // When
        let (_, response) = try await sut.perform(request, using: session)

        // Then - No retry, returns 401 immediately
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 401)
        XCTAssertEqual(RetryURLProtocolStub.requestCount, 1)
    }

    func testPerform_doesNotRetryOnCancellation() async throws {
        // Given
        RetryURLProtocolStub.responses = [
            RetryURLProtocolStubResponse(data: nil, response: nil, error: URLError(.cancelled))
        ]

        let request = try URLRequest(url: XCTUnwrap(URL(string: "https://example.com")))

        // When/Then
        do {
            _ = try await sut.perform(request, using: session)
            XCTFail("Should have thrown error")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .cancelled)
            XCTAssertEqual(RetryURLProtocolStub.requestCount, 1)
        }
    }

    // MARK: - No Retry Configuration Tests

    func testPerform_withNoRetryConfig_doesNotRetry() async throws {
        // Given
        let noRetrySut = TruoraSessionConfiguration.noRetry
        RetryURLProtocolStub.responses = [
            RetryURLProtocolStubResponse(data: nil, response: nil, error: URLError(.timedOut))
        ]

        let request = try URLRequest(url: XCTUnwrap(URL(string: "https://example.com")))

        // When/Then
        do {
            _ = try await noRetrySut.perform(request, using: session)
            XCTFail("Should have thrown error")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .timedOut)
            XCTAssertEqual(RetryURLProtocolStub.requestCount, 1)
        }
    }

    // MARK: - Convenience Method Tests

    func testPerformFromURL_success() async throws {
        // Given
        let expectedData = "test".data(using: .utf8)!
        let response = try XCTUnwrap(try HTTPURLResponse(
            url: XCTUnwrap(URL(string: "https://example.com")),
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        ))
        RetryURLProtocolStub.responses = [
            RetryURLProtocolStubResponse(data: expectedData, response: response, error: nil)
        ]

        // When
        let (data, _) = try await sut.perform(from: XCTUnwrap(URL(string: "https://example.com")), using: session)

        // Then
        XCTAssertEqual(data, expectedData)
    }
}
