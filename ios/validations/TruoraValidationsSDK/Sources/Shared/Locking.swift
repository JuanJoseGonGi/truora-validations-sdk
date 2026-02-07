import Foundation

// MARK: - NSLock scoped locking

extension NSLock {
    /// Executes `body` while holding the lock.
    ///
    /// Using a scoped helper like this keeps lock/unlock in the same synchronous scope,
    /// which is required under Swift 6 strict concurrency checks.
    @inlinable
    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try body()
    }
}
