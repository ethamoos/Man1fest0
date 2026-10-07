import Foundation
import SwiftUI

// Shared URL helper to safely construct URLs and surface user-visible errors
struct URLHelpers {
    /// Try to build a URL from a string. If creation fails, returns nil and optionally shows an error using MessageStore.
    static func safeURL(_ s: String?, messageStore: MessageStore? = nil, context: String? = nil) -> URL? {
        guard let s = s, !s.isEmpty else {
            if let ms = messageStore {
                DispatchQueue.main.async { ms.show("Invalid or empty URL: \(context ?? "")", level: .error) }
            }
            return nil
        }
        if let url = URL(string: s) {
            return url
        } else {
            if let ms = messageStore {
                DispatchQueue.main.async { ms.show("Malformed URL: \(s) \(context ?? "")", level: .error) }
            }
            return nil
        }
    }
}
