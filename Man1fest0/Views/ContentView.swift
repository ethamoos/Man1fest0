//
//  ContentView.swift
//
//  Created by Amos Deane on 22/03/2024.
//

import SwiftUI

// Lightweight local MessageStore and MessageBar fallback so the app compiles
// even if shared files were not added to the project target. These mirror
// the full implementations in Views/Shared when present.
final class MessageStore: ObservableObject {
    enum Level: String { case info, success, warning, error, debug }
    @Published var message: String = ""
    @Published var level: Level = .info
    @Published var isVisible: Bool = false
    @Published var showSpinner: Bool = false
    // Match the signature of the shared MessageStore so callers can pass details and
    // the named `showSpinner` parameter. The full implementation in Views/Shared
    // supports `details: String?` and `showSpinner: Bool`.
    func show(_ text: String, level: Level = .info, details: String? = nil, showSpinner: Bool = false) {
        DispatchQueue.main.async {
            self.message = text
            self.level = level
            self.showSpinner = showSpinner
            withAnimation { self.isVisible = true }
        }
    }

    func hide() { DispatchQueue.main.async { withAnimation { self.isVisible = false }; self.showSpinner = false } }

    // Shortcut helpers matching the full MessageStore API used throughout the app.
    func info(_ text: String, details: String? = nil) { show(text, level: .info, details: details) }
    func success(_ text: String, details: String? = nil) { show(text, level: .success, details: details) }
    func warn(_ text: String, details: String? = nil) { show(text, level: .warning, details: details) }
    func error(_ text: String, details: String? = nil) { show(text, level: .error, details: details) }
    func debug(_ text: String, details: String? = nil) { show(text, level: .debug, details: details) }

}

struct MessageBar: View {
    @ObservedObject var store: MessageStore
    private func fg(_ level: MessageStore.Level) -> Color {
        switch level {
        case .info: return .blue
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        case .debug: return .gray
        }
    }
    var body: some View {
        if store.isVisible {
            HStack(spacing: 10) {
                if store.showSpinner { ProgressView().progressViewStyle(CircularProgressViewStyle()) }
                Text(store.message).foregroundColor(fg(store.level)).lineLimit(2)
                Spacer()
                Button(action: { store.hide() }) { Image(systemName: "xmark.circle.fill").foregroundColor(.secondary) }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.03)))
            .padding(.horizontal)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

struct ContentView: View {
    
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var inactivityMonitor: InactivityMonitor
    @EnvironmentObject var messageStore: MessageStore

    //  #######################################################################
    //  Login
    //  #######################################################################
    
    var server: String { UserDefaults.standard.string(forKey: "server") ?? "" }
    var username: String { UserDefaults.standard.string(forKey: "username") ?? "" }
    var password: String = ""
    
    @AppStorage("ShouldShowWelcomeScreen") private var storedShouldShowWelcome: Bool = false
    @AppStorage("ShouldShowWelcomeScreenSet") private var storedShouldShowWelcomeSet: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            NavigationView {
                // Primary column: always show the app sidebar so navigation links work
                OptionsView()

            // Detail column: show loading, welcome, or default placeholder
            if networkController.isLoading {
                VStack {
                    ProgressView()
                    Text("Loading…").foregroundColor(Color.gray)
                }
            } else {
                #if DEBUG
                let debugForceShowWelcome = true
                #else
                let debugForceShowWelcome = false
                #endif

                // Reactive preferences: use @AppStorage-backed values so changes update UI immediately
                let showWelcome: Bool = {
                    if debugForceShowWelcome { return true }
                    if !storedShouldShowWelcomeSet { return true }
                    return storedShouldShowWelcome
                }()

                // If we have cached credentials and do not need the user to authenticate,
                // prefer showing the welcome screen by default (so users land on the friendly
                // WelcomeToMan1fest0 view instead of the PoliciesView)
                let shouldShowWelcomeDueToCachedCredentials = networkController.hasCachedCredentials && !networkController.needsCredentials

                if showWelcome || shouldShowWelcomeDueToCachedCredentials {
                    WelcomeToMan1fest0()
                } else {
                    Text("Select an Item")
                        .foregroundColor(Color.gray)
                }
            }
                
            }
            // Persistent message bar reserved for user-visible messages and spinners
            MessageBar(store: messageStore)
                .padding(.vertical, 6)
        }
        .sheet(isPresented: $networkController.needsCredentials) {
            ConnectSheet(
                show: $networkController.needsCredentials
            )
        }
        .alert(isPresented: $networkController.showAlert,
               content: {
            progress.showCustomAlert(alertTitle: networkController.alertTitle, alertMessage: networkController.alertMessage )
        })
        .task {
            
            await networkController.load()
            
            Task {
                try await networkController.getAllPackages()
                try await networkController.getAllPolicies(server: server, authToken: networkController.authToken)
            }

            // Capture environment object locally for use in this async closure
            let monitor = inactivityMonitor

            // After performing initial load/connect, decide whether to show connect sheet
            // If connected, reset inactivity timer so lock screen doesn't appear immediately
            if networkController.connected {
                // Ensure any previously-set locked flag is cleared and restart inactivity timer
                // Programmatic unlock after successful connect - pass a non-nil value
                // so unlockApp does not re-show the lock when "Require password on wake"
                monitor.unlockApp(password: "startup-connect")
                monitor.resetInactivityTimer()
            } else {
                // If not connected, ask NetBrain to present the connect sheet
                networkController.needsCredentials = true
            }
        }
        #if os(macOS)
        // Attach a window accessor so we can apply the saved frame after SwiftUI has created the window.
        .background(WindowAccessor())
        #endif
    }
    
    #if os(macOS)
    /// A small NSViewRepresentable that captures the NSWindow for the SwiftUI view hierarchy
    /// and applies a saved frame from UserDefaults (key: "MainWindowFrame"). This runs once
    /// when the view appears and ensures the restored size/position is applied after SwiftUI
    /// has created and configured the window (fixes small-default-size when launching from Xcode).
    fileprivate struct WindowAccessor: NSViewRepresentable {
        func makeNSView(context: Context) -> NSView {
            let v = NSView()
            DispatchQueue.main.async {
                if let window = v.window {
                    applySavedFrame(to: window)
                } else {
                    // If window is not yet available, observe the view's window change
                    NotificationCenter.default.addObserver(forName: NSView.frameDidChangeNotification, object: v, queue: .main) { _ in
                        if let window = v.window {
                            applySavedFrame(to: window)
                        }
                    }
                }
            }
            return v
        }
        
        func updateNSView(_ nsView: NSView, context: Context) {}
        
        private func applySavedFrame(to window: NSWindow) {
            let defaultsKey = "MainWindowFrame"
            guard let frameString = UserDefaults.standard.string(forKey: defaultsKey) else { return }
            print("[WindowAccessor] Found saved frame: \(frameString)")
            var rect = NSRectFromString(frameString)
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
            print("[WindowAccessor] Applied saved frame to window: \(rect)")
        }
    }
    #endif

}
