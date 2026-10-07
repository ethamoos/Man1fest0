import Foundation

// Centralized app-level Notification names used by the global menu commands
// and by views that want to react to them. Keep these here to avoid ad-hoc
// stringly-typed notification names scattered around the codebase.
extension Notification.Name {
    /// Posted by the app-level "Refresh" command. Views may observe this to
    /// refresh their currently-visible data. Where possible observers should
    /// scope the refresh to the relevant resource (e.g. a policy ID) to avoid
    /// unnecessarily reloading unrelated views.
    static let globalRefresh = Notification.Name("globalRefresh")

    /// Posted by the app-level "Focus Search" command. Views containing an
    /// inline search field should listen for this and focus their search field
    /// (via @FocusState) so the user can start typing immediately.
    static let focusSearch = Notification.Name("focusSearch")

    /// Posted by the app-level "Export" command. Views that support an export
    /// flow (e.g. policy detail) can observe this and present their export UI.
    static let globalExport = Notification.Name("globalExport")
}
