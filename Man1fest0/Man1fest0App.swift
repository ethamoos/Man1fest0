import SwiftUI
#if os(macOS)
import AppKit

/// App delegate to persist and restore the main window frame (macOS only).
fileprivate class AppDelegate: NSObject, NSApplicationDelegate {
    private let defaultsKey = "MainWindowFrame"
    private var didRestore = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Print bundle id for debugging
        if let bundleId = Bundle.main.bundleIdentifier {
            print("[AppDelegate] bundle identifier: \(bundleId)")
        } else {
            print("[AppDelegate] bundle identifier: nil")
        }

        // Apply saved frame after a short delay to allow SwiftUI to finish creating windows
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.applySavedFrame()
        }

        // Observe window move/resize notifications so we can persist changes
        NotificationCenter.default.addObserver(self, selector: #selector(windowDidChange(_:)), name: NSWindow.didResizeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(windowDidChange(_:)), name: NSWindow.didMoveNotification, object: nil)
        // Observe when windows close so we can save the frame
        NotificationCenter.default.addObserver(self, selector: #selector(windowWillClose(_:)), name: NSWindow.willCloseNotification, object: nil)
        // Observe when a window becomes key to restore the saved frame once a titled window appears
        NotificationCenter.default.addObserver(self, selector: #selector(windowDidBecomeKey(_:)), name: NSWindow.didBecomeKeyNotification, object: nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Save current frame at termination as a final snapshot
        saveCurrentWindowFrame()
    }

    @objc private func windowDidChange(_ note: Notification) {
        guard let window = note.object as? NSWindow else { return }
        saveFrame(for: window)
    }

    @objc private func windowWillClose(_ note: Notification) {
        guard let window = note.object as? NSWindow else { return }
        saveFrame(for: window)
    }

    @objc private func windowDidBecomeKey(_ note: Notification) {
        guard !didRestore, let window = note.object as? NSWindow else { return }
        // Only restore for standard titled windows (avoid sheets, panels)
        guard window.styleMask.contains(.titled) else { return }
        applySavedFrame(to: window)
        didRestore = true
    }

    // Exposed so the App can request a frame save (e.g., on scenePhase changes)
    func saveCurrentWindowFrame() {
        if let window = NSApp.keyWindow ?? NSApp.windows.first {
            saveFrame(for: window)
        }
    }

    private func saveFrame(for window: NSWindow) {
        // Only persistent frames for standard windows (avoid panels, popovers)
        guard window.styleMask.contains(.titled) else { return }
        let frameString = NSStringFromRect(window.frame)
        UserDefaults.standard.set(frameString, forKey: defaultsKey)
        print("[AppDelegate] Saved window frame: \(frameString)")
    }

    private func applySavedFrame() {
        // If there is a saved frame, try to use it; otherwise compute a proportional default
        let minWidth: CGFloat = 700
        let minHeight: CGFloat = 420
        var rect: NSRect
        if let frameString = UserDefaults.standard.string(forKey: defaultsKey) {
            print("[AppDelegate] Found saved frame: \(frameString)")
            rect = NSRectFromString(frameString)
            // If the saved rect is unreasonably small, fall back to a default proportional rect
            if rect.size.width < minWidth || rect.size.height < minHeight {
                print("[AppDelegate] Saved frame too small, using proportional default")
                rect = proportionalDefaultRect(minWidth: minWidth, minHeight: minHeight)
            }
        } else {
            // No saved frame; use a default rect proportional to main screen
            rect = proportionalDefaultRect(minWidth: minWidth, minHeight: minHeight)
            print("[AppDelegate] No saved frame found, using proportional default: \(rect)")
        }

        // Find a main/styled window to apply the saved frame to
        if let window = NSApp.windows.first(where: { $0.styleMask.contains(.titled) }) {
            window.setFrame(rect, display: true, animate: false)
            print("[AppDelegate] Applied saved frame to window: \(rect)")
        }
    }

    private func applySavedFrame(to window: NSWindow) {
        let minWidth: CGFloat = 700
        let minHeight: CGFloat = 420
        var rect: NSRect
        if let frameString = UserDefaults.standard.string(forKey: defaultsKey) {
            print("[AppDelegate] applySavedFrame(to:) found saved frame: \(frameString)")
            rect = NSRectFromString(frameString)
            if rect.size.width < minWidth || rect.size.height < minHeight {
                print("[AppDelegate] Saved frame too small in applySavedFrame(to:), using proportional default")
                rect = proportionalDefaultRect(minWidth: minWidth, minHeight: minHeight)
            }
        } else {
            rect = proportionalDefaultRect(minWidth: minWidth, minHeight: minHeight)
            print("[AppDelegate] No saved frame in applySavedFrame(to:), using proportional default: \(rect)")
        }
        window.setFrame(rect, display: true, animate: false)
        print("[AppDelegate] Applied saved frame to specific window: \(rect)")
    }

    private func proportionalDefaultRect(minWidth: CGFloat, minHeight: CGFloat) -> NSRect {
        // Use the main screen visible frame as base, fall back to first screen or a sane default
        let screens = NSScreen.screens
        let baseVisible = NSScreen.main?.visibleFrame ?? (screens.first?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800))
        // Choose proportions of the available area
        let width = max(minWidth, floor(baseVisible.width * 0.85))
        let height = max(minHeight, floor(baseVisible.height * 0.75))
        let originX = baseVisible.origin.x + (baseVisible.width - width) / 2.0
        let originY = baseVisible.origin.y + (baseVisible.height - height) / 2.0
        return NSRect(x: originX, y: originY, width: width, height: height)
    }
}
#endif

@main
struct Man1fest0App: App {
    
//    #################################################################################
//    Order of classes is based on the order in which they were added
//    #################################################################################

    let photoController: PhotoViewModel
//    #################################################################################
//    Core data for persistent notes
//    #################################################################################
    private let coreDataStack = CoreDataStack(modelName: "NotesModel")
    @Environment(\.scenePhase) var scenePhase
    let pushController: PushBrain
    let extensionAttributeController: EaBrain
    let networkController: NetBrain
    let prestageController: PrestageBrain
    let xmlController: XmlBrain
    let progress: Progress
    let backgroundTasks: BackgroundTasks
#if os(macOS)
    let basher = Basher()
#endif
    let layout = Layout()
//    let jamfController: JamfController
    let scopingController: ScopingBrain
    let policyController: PolicyBrain
    let exportController: ImportExportBrain
    // State to control presentation of the Preferences sheet (macOS only)
    @State private var showingPreferences: Bool = false
    #if os(macOS)
    // Hook our AppDelegate to handle window frame persistence
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif
    
    init() {
        self.photoController = PhotoViewModel()
        self.pushController = PushBrain()
        self.extensionAttributeController = EaBrain()
//        self.jamfController = JamfController()
        self.networkController = NetBrain()
        self.prestageController = PrestageBrain()
        self.xmlController = XmlBrain()
        self.progress = Progress()
//        self.basher = Basher()
        self.backgroundTasks = BackgroundTasks()
        self.scopingController = ScopingBrain()
        self.policyController = PolicyBrain()
        self.exportController = ImportExportBrain()
        // Initialize global security settings and inactivity monitor
        self.securitySettings = SecuritySettingsManager()
        self.inactivityMonitor = InactivityMonitor(securitySettings: self.securitySettings)
        // Ensure the file-backed logger is initialized at app launch so a log file exists
        _ = Logger.shared
    }
    
    // Global security objects provided to the environment
    let securitySettings: SecuritySettingsManager
    let inactivityMonitor: InactivityMonitor
    
    var body: some Scene {
        WindowGroup {
            SecureAppWrapper(showPreferences: $showingPreferences) {
                ContentView()
            }
            // Preserve existing environment objects for the app and pass them to the wrapped content
                .environmentObject(coreDataStack)
                .environment(\.managedObjectContext,
                             coreDataStack.managedObjectContext)
                .environmentObject(pushController)
                .environmentObject(extensionAttributeController)
                .environmentObject(networkController)
                .environmentObject(prestageController)
                .environmentObject(xmlController)
                .environmentObject(progress)
#if os(macOS)
                .environmentObject(basher)
#endif

                .environmentObject(layout)
                .environmentObject(backgroundTasks)
                .environmentObject(scopingController)
                .environmentObject(policyController)
                .environmentObject(exportController)
                // Provide global security objects
                .environmentObject(securitySettings)
                .environmentObject(inactivityMonitor)
        }.commands {
            SidebarCommands()
        }
        // Add a macOS-only menu command to open Preferences directly from the app menu
        #if os(macOS)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Preferences…") {
                    showingPreferences = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
        #endif
        .onChange(of: scenePhase) { newPhase in
            coreDataStack.save()
#if os(macOS)
            // Explicitly save the window frame on scene phase changes (e.g., backgrounding)
            if newPhase == .background || newPhase == .inactive {
                appDelegate.saveCurrentWindowFrame()
            }
#endif
        }
    }
}
