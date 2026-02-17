import Foundation

/// Simple debouncer that schedules an async closure after a delay and cancels previous scheduled work.
final class Debouncer: ObservableObject {
    private var task: Task<Void, Never>?

    /// Debounce the provided async action by `interval` seconds.
    /// Cancels any previously scheduled action.
    func debounce(interval: TimeInterval, action: @escaping @Sendable () async -> Void) {
        // cancel any existing scheduled task
        task?.cancel()
        task = Task { @MainActor in
            // sleep for the interval, or return early if cancelled
            do {
                try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            } catch {
                return
            }
            await action()
        }
    }

    deinit {
        task?.cancel()
    }
}
