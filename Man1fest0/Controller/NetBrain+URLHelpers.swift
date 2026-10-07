import Foundation

extension NetBrain {
    /// Convenience wrapper that uses the controller's messageStore when building URLs.
    func safeURL(_ s: String?, context: String? = nil) -> URL? {
        return URLHelpers.safeURL(s, messageStore: self.messageStore, context: context)
    }
}
