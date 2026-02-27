import Foundation

/// Manages API key validation for SDK-type keys only.
///
/// The manager:
/// 1. Decodes the JWT to extract expiration, key type, and application_id
/// 2. Validates key_type is "sdk"
/// 3. Validates the key hasn't expired
/// 4. Validates application_id matches the app's bundle ID
public class ApiKeyManager {
    private let jwtDecoder: JwtDecoder
    private let currentTimeProvider: () -> TimeInterval
    private let bundleIdentifierProvider: () -> String?

    /// Creates a new API key manager.
    ///
    /// - Parameters:
    ///   - jwtDecoder: Decoder for JWT tokens (defaults to new instance)
    ///   - currentTimeProvider: Provider for current time (defaults to Date())
    ///   - bundleIdentifierProvider: Provider for app bundle ID (defaults to Bundle.main.bundleIdentifier)
    public init(
        jwtDecoder: JwtDecoder = JwtDecoder(),
        currentTimeProvider: @escaping () -> TimeInterval = { Date().timeIntervalSince1970 },
        bundleIdentifierProvider: @escaping () -> String? = { Bundle.main.bundleIdentifier }
    ) {
        self.jwtDecoder = jwtDecoder
        self.currentTimeProvider = currentTimeProvider
        self.bundleIdentifierProvider = bundleIdentifierProvider
    }

    /// Validates an SDK API key for use with the Validations API.
    ///
    /// - Parameter apiKey: The SDK API key to validate
    /// - Returns: The validated API key
    /// - Throws: `ApiKeyError` if validation fails
    public func validateApiKey(_ apiKey: String) async throws -> String {
        let jwtData = try jwtDecoder.extractJwtData(apiKey)

        guard jwtData.keyType == ApiKeyTypes.sdk else {
            throw ApiKeyError.invalidKeyType(jwtData.keyType)
        }

        if jwtDecoder.isExpired(jwtData.expiration, currentTime: currentTimeProvider()) {
            throw ApiKeyError.expiredKey(expiration: jwtData.expiration)
        }

        guard let expectedBundleId = bundleIdentifierProvider(),
              let actualApplicationId = jwtData.applicationId,
              expectedBundleId == actualApplicationId else {
            throw ApiKeyError.invalidJwtFormat
        }

        return apiKey
    }
}
