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
        guard let frameString = UserDefaults.standard.string(forKey: defaultsKey) else { return }
        print("[AppDelegate] Found saved frame: \(frameString)")
        var rect = NSRectFromString(frameString)
        // Ensure restored rect is visible on at least one connected screen. If not, center/clamp on main screen.
        let screens = NSScreen.screens
        if !screens.contains(where: { $0.visibleFrame.intersects(rect) }) {
            // Use main screen (fallback to first) visible frame
            let mainVisible = NSScreen.main?.visibleFrame ?? (screens.first?.visibleFrame ?? NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600))
            // Limit restored size to not exceed visible area
            let clampedWidth = min(rect.size.width, mainVisible.width)
            let clampedHeight = min(rect.size.height, mainVisible.height)
            let centeredX = mainVisible.origin.x + (mainVisible.width - clampedWidth) / 2.0
            let centeredY = mainVisible.origin.y + (mainVisible.height - clampedHeight) / 2.0
            rect.origin.x = max(mainVisible.origin.x, centeredX)
            rect.origin.y = max(mainVisible.origin.y, centeredY)
            rect.size.width = clampedWidth
            rect.size.height = clampedHeight
        }

        // Find a main/styled window to apply the saved frame to
        if let window = NSApp.windows.first(where: { $0.styleMask.contains(.titled) }) {
            window.setFrame(rect, display: true, animate: false)
            print("[AppDelegate] Applied saved frame to window: \(rect)")
        }
    }

    private func applySavedFrame(to window: NSWindow) {
        guard let frameString = UserDefaults.standard.string(forKey: defaultsKey) else { return }
        print("[AppDelegate] applySavedFrame(to:) found saved frame: \(frameString)")
        var rect = NSRectFromString(frameString)
        // Ensure rect is visible on current screens; if not, clamp/center on main visible frame
        let screens = NSScreen.screens
        if !screens.contains(where: { $0.visibleFrame.intersects(rect) }) {
            let mainVisible = NSScreen.main?.visibleFrame ?? (screens.first?.visibleFrame ?? NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600))
            let clampedWidth = min(rect.size.width, mainVisible.width)
            let clampedHeight = min(rect.size.height, mainVisible.height)
            let centeredX = mainVisible.origin.x + (mainVisible.width - clampedWidth) / 2.0
            let centeredY = mainVisible.origin.y + (mainVisible.height - clampedHeight) / 2.0
            rect.origin.x = max(mainVisible.origin.x, centeredX)
            rect.origin.y = max(mainVisible.origin.y, centeredY)
            rect.size.width = clampedWidth
            rect.size.height = clampedHeight
        }
        window.setFrame(rect, display: true, animate: false)
        print("[AppDelegate] Applied saved frame to specific window: \(rect)")
    }
}
#endif

// Lightweight inline preferences view to ensure it's always in-scope for the App
#if os(macOS)
fileprivate struct AppPolicyDelayPreferencesView: View {
    @EnvironmentObject var networkController: NetBrain
    @State private var delayValue: Double = 3.0
    @State private var showSavedToast = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Policy fetch delay (seconds)")
                .font(.headline)

            HStack {
                Slider(value: $delayValue, in: 0...60, step: 0.1)
                Stepper(value: $delayValue, in: 0...600, step: 1) {
                    Text("\(Int(delayValue)) s")
                        .frame(minWidth: 60)
                }
            }

            HStack(spacing: 12) {
                Button(action: {
                    networkController.setPolicyRequestDelay(delayValue)
                    showSavedToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showSavedToast = false
                    }
                }) {
                    Text("Save")
                }

                Button(action: {
                    delayValue = networkController.getPolicyRequestDelay()
                }) {
                    Text("Reset to current")
                }

                Spacer()

                Text(networkController.policyDelayStatus)
                    .foregroundColor(.secondary)
            }

            if showSavedToast {
                Text("Saved")
                    .foregroundColor(.green)
            }

            Divider()

            Text("Human readable: \(networkController.humanReadableDuration(delayValue))")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
        .onAppear {
            delayValue = networkController.getPolicyRequestDelay()
        }
        .frame(minWidth: 420, minHeight: 180)
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
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
            
//                .environmentObject(photoController)
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
//                .environmentObject(jamfcontroller)
                .environmentObject(scopingController)
                .environmentObject(policyController)
                .environmentObject(exportController)
                // Present the preferences view as a sheet on macOS when requested from the menu
                #if os(macOS)
                .sheet(isPresented: $showingPreferences) {
                    AppPolicyDelayPreferencesView()
                        .environmentObject(networkController)
                }
                #endif
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
