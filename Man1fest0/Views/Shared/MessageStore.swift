import Foundation
import SwiftUI

final class MessageStore: ObservableObject {
    enum Level: String, Codable {
        case info, success, warning, error, debug
    }

    @Published var message: String = ""
    @Published var level: Level = .info
    @Published var isVisible: Bool = false
    @Published var showSpinner: Bool = false
    @Published var details: String? = nil

    // Convenience methods
    func show(_ text: String, level: Level = .info, details: String? = nil, showSpinner: Bool = false) {
        DispatchQueue.main.async {
            self.message = text
            self.level = level
            self.details = details
            self.showSpinner = showSpinner
            withAnimation { self.isVisible = true }
        }
    }

    func hide() {
        DispatchQueue.main.async {
            withAnimation { self.isVisible = false }
            self.showSpinner = false
        }
    }

    // Shortcut helpers
    func info(_ text: String, details: String? = nil) { show(text, level: .info, details: details) }
    func success(_ text: String, details: String? = nil) { show(text, level: .success, details: details) }
    func warn(_ text: String, details: String? = nil) { show(text, level: .warning, details: details) }
    func error(_ text: String, details: String? = nil) { show(text, level: .error, details: details) }
    func debug(_ text: String, details: String? = nil) { show(text, level: .debug, details: details) }
}
