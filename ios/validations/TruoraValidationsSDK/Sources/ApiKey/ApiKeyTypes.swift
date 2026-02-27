import Foundation

/// Constants for API key types used in the Truora Validations SDK.
///
/// Only SDK-type API keys are supported. The JWT must include key_type "sdk"
/// and application_id matching the app's bundle ID.
public enum ApiKeyTypes {
    /// API key type that can be used directly for API calls
    public static let sdk = "sdk"
}
