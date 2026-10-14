import Foundation

/// Simple debouncer that schedules a synchronous closure on the main queue after a delay and cancels previous scheduled work.
final class Debouncer: ObservableObject {
    private var workItem: DispatchWorkItem?

    /// Debounce the provided action by `interval` seconds.
    /// Cancels any previously scheduled action.
    func debounce(interval: TimeInterval, action: @escaping () -> Void) {
        // Ensure state is only ever touched on the main thread
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in self?.debounce(interval: interval, action: action) }
            return
        }
        workItem?.cancel()
        let item = DispatchWorkItem(block: action)
        workItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: item)
    }

    deinit {
        workItem?.cancel()
    }
}
