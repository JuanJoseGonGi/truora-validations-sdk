import Foundation

/// Represents the result of a validation operation
/// - complete: Validation completed successfully with a result of type T
/// - failure: Validation failed with a TruoraException, with an optional partial result
/// - canceled: Validation was canceled by the user, with an optional partial result
public enum TruoraValidationResult<T> {
    case complete(T)
    case failure(TruoraException, T?)
    case canceled(T?)
}

// MARK: - Equatable conformance (when T is Equatable)

extension TruoraValidationResult: Equatable where T: Equatable {
    public static func == (lhs: TruoraValidationResult<T>, rhs: TruoraValidationResult<T>) -> Bool {
        switch (lhs, rhs) {
        case (.complete(let lhsValue), .complete(let rhsValue)):
            lhsValue == rhsValue
        case (.failure(let lhsError, let lhsValue), .failure(let rhsError, let rhsValue)):
            lhsError == rhsError && lhsValue == rhsValue
        case (.canceled(let lhsValue), .canceled(let rhsValue)):
            lhsValue == rhsValue
        default:
            false
        }
    }
}

// MARK: - CustomStringConvertible

extension TruoraValidationResult: CustomStringConvertible {
    public var description: String {
        switch self {
        case .complete(let value):
            return "TruoraValidationResult.complete(\(value))"
        case .failure(let error, let value):
            let errorDesc = error.localizedDescription
            let valueDesc = String(describing: value)
            return "TruoraValidationResult.failure(\(errorDesc), \(valueDesc))"
        case .canceled(let value):
            return "TruoraValidationResult.canceled(\(String(describing: value)))"
        }
    }
}

// MARK: - Convenience Properties

public extension TruoraValidationResult {
    /// Returns true if the result is a completion
    var isComplete: Bool {
        if case .complete = self { return true }
        return false
    }

    /// Returns true if the result is a failure
    var isFailure: Bool {
        if case .failure = self { return true }
        return false
    }

    /// Returns true if the result is a cancellation
    var isCanceled: Bool {
        if case .canceled = self { return true }
        return false
    }

    /// Extracts the completion value if available
    var completionValue: T? {
        if case .complete(let value) = self { return value }
        return nil
    }

    /// Extracts the error if this is a failure
    var error: TruoraException? {
        if case .failure(let error, _) = self { return error }
        return nil
    }

    /// Extracts the partial validation result if this is a failure
    var failureValue: T? {
        if case .failure(_, let value) = self { return value }
        return nil
    }

    /// Extracts the partial validation result if this is a cancellation
    var canceledValue: T? {
        if case .canceled(let value) = self { return value }
        return nil
    }
}
