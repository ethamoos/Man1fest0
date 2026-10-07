import Foundation

/// Global debug flags for developer-only verbose logging. Default false in production.
enum AppDebug {
    /// When true, per-item verbose prints are allowed. Use sparingly for local troubleshooting.
    static var verbosePerItemLogging: Bool {
        get { UserDefaults.standard.bool(forKey: "AppDebug.verbosePerItemLogging") }
        set { UserDefaults.standard.set(newValue, forKey: "AppDebug.verbosePerItemLogging") }
    }
}
