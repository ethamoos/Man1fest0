import SwiftUI

#if os(macOS)
import AppKit
#endif

// MARK: - Secure App Wrapper
struct SecureAppWrapper<Content: View>: View {
    
    // MARK: - Content
    let content: Content
    // Binding to control preferences sheet visibility (provided by App)
    private let showingPreferences: Binding<Bool>
    
    // MARK: - Environment Objects (provided by App)
    @EnvironmentObject var securitySettings: SecuritySettingsManager
    @EnvironmentObject var inactivityMonitor: InactivityMonitor
    @EnvironmentObject var networkController: NetBrain
    
    // MARK: - macOS Preferences Window Handle
    #if os(macOS)
    @State private var preferencesWindow: NSWindow?
    #endif
    
    // MARK: - Initialization
    init(showPreferences: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.showingPreferences = showPreferences
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Main app content
            content
                .environmentObject(securitySettings)
                .environmentObject(inactivityMonitor)
                .disabled(inactivityMonitor.isLocked) // Disable interaction when locked
                .blur(radius: inactivityMonitor.isLocked ? 5 : 0) // Blur background when locked
                .animation(.easeInOut(duration: 0.3), value: inactivityMonitor.isLocked)
                .trackUserActivity(inactivityMonitor: inactivityMonitor) // Track user interactions
            
            // Lock screen overlay
            if inactivityMonitor.showLockScreen {
                LockScreenView()
                    .environmentObject(securitySettings)
                    .environmentObject(inactivityMonitor)
                    .environmentObject(networkController)
                    .transition(.opacity)
                    .zIndex(1000)
            }
        }
        // Preferences: on macOS present a separate resizable window (sheets are not user-resizable)
        #if os(macOS)
        .onChange(of: showingPreferences.wrappedValue) { newValue in
            if newValue {
                openPreferencesWindow()
            } else {
                closePreferencesWindow()
            }
        }
        #else
        // macOS-only preferences window handled above; keep existing sheet for non-mac platforms if desired
        .sheet(isPresented: showingPreferences) {
            // Inline preferences UI to ensure compilation and avoid symbol-scope issues
            NavigationView {
                Form {
                    Section(header: Text("Security")) {
                        PreferencesSecuritySection()
                    }
                    Section(header: Text("Policy Fetch")) {
                        // Inlined Policy Delay controls
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Policy fetch delay (seconds)")
                                .font(.headline)
                            // local state via transient view
                            PolicyDelayInlineViewLocal()
                                .environmentObject(networkController)
                        }
                     }
                }
                .navigationTitle("Preferences")
                .frame(minWidth: 250, minHeight: 200)
            }
         }
        #endif
        .onAppear {
            // Start monitoring when app appears
            inactivityMonitor.resetInactivityTimer()
        }
        // Only subscribe to foreground notifications on iOS/Catalyst
        #if os(iOS) || targetEnvironment(macCatalyst)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Check lock status when app comes to foreground
            inactivityMonitor.checkLockStatus()
        }
        #else
        // For macOS we can observe NSWorkspace notifications inside InactivityMonitor directly; no-op here
        #endif
    }

    // MARK: - macOS helpers to open/close a separate preferences window
    #if os(macOS)
    private func openPreferencesWindow() {
        guard preferencesWindow == nil else {
            // already open
            preferencesWindow?.makeKeyAndOrderFront(nil)
            return
        }

        // Build the SwiftUI content and attach environment objects
        let prefsContent = PreferencesWindowContent()
            .environmentObject(securitySettings)
            .environmentObject(inactivityMonitor)
            .environmentObject(networkController)

        let hostingController = NSHostingController(rootView: prefsContent)
        // Allow the hosting view to resize with the window
        hostingController.view.translatesAutoresizingMaskIntoConstraints = true
        hostingController.view.autoresizingMask = [.width, .height]
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Preferences"
        window.setContentSize(NSSize(width: 560, height: 360))
        // Ensure window is resizable
        window.styleMask = [.titled, .closable, .resizable, .miniaturizable]
        // Set a sensible minimum size so the window can't be shrunk to too small
        window.minSize = NSSize(width: 300, height: 200)
        window.center()
        window.isReleasedWhenClosed = false

        // Keep a strong reference so it doesn't get deallocated
        preferencesWindow = window

        // When the user closes the window, keep the binding in sync
        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { _ in
            showingPreferences.wrappedValue = false
            preferencesWindow = nil
        }

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func closePreferencesWindow() {
        preferencesWindow?.close()
        preferencesWindow = nil
    }
    #endif
}

// MARK: - Preferences window content (reused for the custom NSWindow)
#if os(macOS)
fileprivate struct PreferencesWindowContent: View {
    @EnvironmentObject var securitySettings: SecuritySettingsManager
    @EnvironmentObject var inactivityMonitor: InactivityMonitor
    @EnvironmentObject var networkController: NetBrain

    var body: some View {
        
        NavigationView {
            
            VStack(alignment: .leading) {
                
                Form {
                    Section(header: Text("Security")) {
                        PreferencesSecuritySection()
                    }
                    
                    Divider()
                    
                    Section(header: Text("Policy Fetch")) {
                        //                        VStack(alignment: .leading, spacing: 12) {
                        Text("Policy fetch delay (seconds)")
//                            .font(.headline)
                        PolicyDelayInlineViewLocal()
                            .environmentObject(networkController)
                    }
//                }
                }
                .navigationTitle("Preferences")
                .frame(minWidth: 250, minHeight: 200)
            }
            .padding()
        }
//        .frame(minWidth: 250, minHeight: 200)
     }
 }
 #endif

// MARK: - Enhanced View Extension for User Activity Tracking
extension View {
    func secureWithActivityTracking() -> some View {
        self.modifier(SecureActivityModifier())
    }
}

// MARK: - Secure Activity Modifier
struct SecureActivityModifier: ViewModifier {
    @EnvironmentObject var inactivityMonitor: InactivityMonitor
    
    func body(content: Content) -> some View {
        var view = content
            .onTapGesture {
                inactivityMonitor.trackUserActivity()
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        inactivityMonitor.trackUserActivity()
                    }
            )
        
        // Add iOS/Catalyst-specific notification listeners only when available
        #if os(iOS) || targetEnvironment(macCatalyst)
        view = view
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)) { _ in
                inactivityMonitor.trackUserActivity()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { _ in
                inactivityMonitor.trackUserActivity()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)) { _ in
                inactivityMonitor.trackUserActivity()
            }
        #endif
        
        return view
    }
}

// MARK: - Local Inline Views used by the SecureAppWrapper
fileprivate struct PolicyDelayInlineViewLocal: View {
    @EnvironmentObject var networkController: NetBrain
    @State private var delayValue: Double = 0.0

    var body: some View {
        VStack(alignment: .leading) {
            Slider(value: $delayValue, in: 0...60, step: 0.1)
            HStack {
                Button("Save") {
                    networkController.setPolicyRequestDelay(delayValue)
                }
                Button("Reset") {
                    delayValue = networkController.getPolicyRequestDelay()
                }
//                Spacer()
                Text(networkController.humanReadableDuration(delayValue))
            }
            .onAppear { delayValue = networkController.getPolicyRequestDelay() }
        }
    }
}

// MARK: - Preferences Security Section
struct PreferencesSecuritySection: View {
    @EnvironmentObject var securitySettings: SecuritySettingsManager
    @EnvironmentObject var inactivityMonitor: InactivityMonitor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Picker("Auto-lock after:", selection: $securitySettings.inactivityTimeout) {
                ForEach(SecuritySettingsManager.InactivityTimeout.allCases) { t in
                    Text(t.displayName).tag(t)
                }
            }
            .pickerStyle(RadioGroupPickerStyle())
            
            Toggle("Require password on wake", isOn: $securitySettings.requirePasswordOnWake)
            Toggle("Use keychain for password", isOn: $securitySettings.useKeychainForPassword)
            
            Button("Force lock now") {
                inactivityMonitor.lockApp()
            }
            .buttonStyle(BorderlessButtonStyle())
        }
//        .padding(.vertical, 8)
    }
}

// MARK: - Usage Example
/*
struct MainAppView: View {
    var body: some View {
        SecureAppWrapper {
            // Your main app content here
            ContentView()
                .secureWithActivityTracking()
        }
    }
}
*/
