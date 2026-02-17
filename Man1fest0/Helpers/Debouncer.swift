import Foundation

/// Simple debouncer that schedules a synchronous closure on the main queue after a delay and cancels previous scheduled work.
final class Debouncer: ObservableObject {
    private var workItem: DispatchWorkItem?

    /// Debounce the provided action by `interval` seconds.
    /// Cancels any previously scheduled action.
    func debounce(interval: TimeInterval, action: @escaping () -> Void) {
        workItem?.cancel()
        let item = DispatchWorkItem(block: action)
        workItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: item)
    }

    deinit {
        workItem?.cancel()
    }
}
