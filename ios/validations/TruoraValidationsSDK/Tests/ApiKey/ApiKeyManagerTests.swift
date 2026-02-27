import XCTest
@testable import TruoraValidationsSDK

@MainActor final class ApiKeyManagerTests: XCTestCase {
    private var sut: ApiKeyManager!
    private var fixedTime: TimeInterval!
    private let testBundleId = "com.example.app"

    override func setUp() {
        super.setUp()
        fixedTime = 1_700_000_000 // Fixed time for testing
        sut = ApiKeyManager(
            jwtDecoder: JwtDecoder(),
            currentTimeProvider: { [unowned self] in self.fixedTime },
            bundleIdentifierProvider: { [unowned self] in self.testBundleId }
        )
    }

    override func tearDown() {
        sut = nil
        fixedTime = nil
        super.tearDown()
    }

    // MARK: - Valid SDK Key Tests

    func testValidateApiKey_withValidSdkKeyAndMatchingApplicationId_returnsKey() async throws {
        // Given: Valid SDK key with future expiration and matching application_id
        // Payload: {"exp": 1893456000, "key_type": "sdk", "application_id": "com.example.app"}
        let sdkKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE4OTM0NTYwMDAsImtleV90eXBlIjoic2RrIiwiYXBwbGljYXRpb25faWQiOiJjb20uZXhhbXBsZS5hcHAifQ.signature"

        // When
        let result = try await sut.validateApiKey(sdkKey)

        // Then
        XCTAssertEqual(result, sdkKey)
    }

    // MARK: - Invalid Key Type Tests

    func testValidateApiKey_withNonSdkKeyType_throwsInvalidKeyType() async {
        // Given: Generator key (no longer supported)
        // Payload: {"exp": 1893456000, "key_type": "generator", "application_id": "com.example.app"}
        let generatorKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE4OTM0NTYwMDAsImtleV90eXBlIjoiZ2VuZXJhdG9yIiwiYXBwbGljYXRpb25faWQiOiJjb20uZXhhbXBsZS5hcHAifQ.signature"

        // When/Then
        do {
            _ = try await sut.validateApiKey(generatorKey)
            XCTFail("Expected invalidKeyType error")
        } catch let error as ApiKeyError {
            if case .invalidKeyType(let keyType) = error {
                XCTAssertEqual(keyType, "generator")
            } else {
                XCTFail("Expected invalidKeyType error, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testValidateApiKey_withInvalidKeyType_throwsInvalidKeyType() async {
        // Given: Key with invalid key_type
        // Payload: {"exp": 1893456000, "key_type": "invalid", "application_id": "com.example.app"}
        let invalidKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE4OTM0NTYwMDAsImtleV90eXBlIjoiaW52YWxpZCIsImFwcGxpY2F0aW9uX2lkIjoiY29tLmV4YW1wbGUuYXBwIn0.signature"

        // When/Then
        do {
            _ = try await sut.validateApiKey(invalidKey)
            XCTFail("Expected invalidKeyType error")
        } catch let error as ApiKeyError {
            if case .invalidKeyType(let keyType) = error {
                XCTAssertEqual(keyType, "invalid")
            } else {
                XCTFail("Expected invalidKeyType error, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Application ID Tests

    func testValidateApiKey_withMissingApplicationId_throwsInvalidJwtFormat() async {
        // Given: SDK key without application_id
        // Payload: {"exp": 1893456000, "key_type": "sdk"}
        let missingAppIdKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE4OTM0NTYwMDAsImtleV90eXBlIjoic2RrIn0.signature"

        // When/Then
        do {
            _ = try await sut.validateApiKey(missingAppIdKey)
            XCTFail("Expected invalidJwtFormat error")
        } catch let error as ApiKeyError {
            XCTAssertEqual(error, .invalidJwtFormat)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testValidateApiKey_withNonMatchingApplicationId_throwsInvalidJwtFormat() async {
        // Given: SDK key with application_id that doesn't match bundle ID
        // Payload: {"exp": 1893456000, "key_type": "sdk", "application_id": "com.other.app"}
        let wrongAppIdKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE4OTM0NTYwMDAsImtleV90eXBlIjoic2RrIiwiYXBwbGljYXRpb25faWQiOiJjb20ub3RoZXIuYXBwIn0.signature"

        // When/Then
        do {
            _ = try await sut.validateApiKey(wrongAppIdKey)
            XCTFail("Expected invalidJwtFormat error")
        } catch let error as ApiKeyError {
            XCTAssertEqual(error, .invalidJwtFormat)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testValidateApiKey_whenBundleIdentifierProviderReturnsNil_throwsInvalidJwtFormat() async {
        // Given: Manager with nil bundle ID provider
        let sutWithNilBundle = ApiKeyManager(
            jwtDecoder: JwtDecoder(),
            currentTimeProvider: { [unowned self] in self.fixedTime },
            bundleIdentifierProvider: { nil }
        )
        // Payload: {"exp": 1893456000, "key_type": "sdk", "application_id": "com.example.app"}
        let sdkKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE4OTM0NTYwMDAsImtleV90eXBlIjoic2RrIiwiYXBwbGljYXRpb25faWQiOiJjb20uZXhhbXBsZS5hcHAifQ.signature"

        // When/Then
        do {
            _ = try await sutWithNilBundle.validateApiKey(sdkKey)
            XCTFail("Expected invalidJwtFormat error")
        } catch let error as ApiKeyError {
            XCTAssertEqual(error, .invalidJwtFormat)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Expiration Tests

    func testValidateApiKey_withExpiredSdkKey_throwsExpiredKey() async {
        // Given: Expired SDK key (exp in the past)
        // Payload: {"exp": 1600000000, "key_type": "sdk", "application_id": "com.example.app"}
        let expiredKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2MDAwMDAwMDAsImtleV90eXBlIjoic2RrIiwiYXBwbGljYXRpb25faWQiOiJjb20uZXhhbXBsZS5hcHAifQ.signature"

        // When/Then
        do {
            _ = try await sut.validateApiKey(expiredKey)
            XCTFail("Expected expiredKey error")
        } catch let error as ApiKeyError {
            if case .expiredKey(let expiration) = error {
                XCTAssertEqual(expiration, 1_600_000_000)
            } else {
                XCTFail("Expected expiredKey error, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Invalid JWT Tests

    func testValidateApiKey_withInvalidJwt_throwsInvalidJwtFormat() async {
        // Given
        let invalidJwt = "not-a-valid-jwt"

        // When/Then
        do {
            _ = try await sut.validateApiKey(invalidJwt)
            XCTFail("Expected invalidJwtFormat error")
        } catch let error as ApiKeyError {
            XCTAssertEqual(error, .invalidJwtFormat)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testValidateApiKey_withMissingKeyType_throwsMissingKeyType() async {
        // Given: JWT without key_type
        // Payload: {"exp": 1893456000, "application_id": "com.example.app"}
        let missingKeyTypeJwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE4OTM0NTYwMDAsImFwcGxpY2F0aW9uX2lkIjoiY29tLmV4YW1wbGUuYXBwIn0.signature"

        // When/Then
        do {
            _ = try await sut.validateApiKey(missingKeyTypeJwt)
            XCTFail("Expected missingKeyType error")
        } catch let error as ApiKeyError {
            XCTAssertEqual(error, .missingKeyType)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
