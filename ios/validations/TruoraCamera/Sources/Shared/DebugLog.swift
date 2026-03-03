//
//  DebugLog.swift
//  TruoraCamera
//

/// Prints a message to the console only in DEBUG builds.
/// String interpolation is not evaluated in Release, so there is no
/// runtime cost beyond the (inlined) compile-time guard.
@inline(__always)
func debugLog(_ message: @autoclosure () -> String) {
    #if DEBUG
    print(message())
    #endif
}
