//
//  AnyCodableValue.swift
//  TruoraValidationsSDK
//

import Foundation

/// Type-safe wrapper for metadata values that preserves type information
/// for automatic type-prefix application.
public enum AnyCodableValue: Codable, Sendable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case stringArray([String])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode([String].self) {
            self = .stringArray(value)
        } else {
            self = try .string(container.decode(String.self))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .int(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .stringArray(let value): try container.encode(value)
        }
    }

    /// The raw value as Any for dictionary interop
    public var rawValue: Any {
        switch self {
        case .string(let val): val
        case .int(let val): val
        case .double(let val): val
        case .bool(let val): val
        case .stringArray(let val): val
        }
    }
}
