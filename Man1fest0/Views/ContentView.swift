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

// Inline TokenStatusView so it is always compiled with ContentView even if the
// standalone file in Views/Shared/TokenStatusView.swift has not been added to
// the Xcode target. This mirrors the fallback approach used for MessageStore
// above.
struct TokenStatusView: View {
    @EnvironmentObject var networkController: NetBrain

    private func color(for state: NetBrain.TokenState) -> Color {
        switch state {
        case .unknown: return Color.gray
        case .valid: return Color.green
        case .expiringSoon: return Color.orange
        case .expired: return Color.red
        }
    }

    private func label(for state: NetBrain.TokenState) -> String {
        switch state {
        case .unknown: return "No token"
        case .valid, .expiringSoon, .expired: return networkController.tokenTimeRemaining
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color(for: networkController.tokenState))
                .frame(width: 10, height: 10)
            Text(label(for: networkController.tokenState))
                .font(.caption)
                .foregroundColor(.primary)
            Button(action: {
                Task {
                    do {
                        try await networkController.ensureValidToken()
                        networkController.messageStore?.show("Token refreshed", level: .success)
                    } catch {
                        networkController.messageStore?.show("Token refresh failed", level: .error, details: error.localizedDescription)
                    }
                }
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .help("Refresh authentication token")
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.05)))
        .onAppear {
            Task { @MainActor in
                networkController.updateTokenState()
            }
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

    /// Destination string set when the user taps a feature card in WelcomeToMan1fest0.
    /// When non-nil the detail column shows the corresponding view (mirroring a sidebar tap).
    @State private var welcomeNavDest: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Top-right token status indicator
            HStack {
                Spacer()
                TokenStatusView()
                    .environmentObject(networkController)
                    .padding(.trailing, 12)
            }
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

                // If the user tapped a welcome card, show that destination directly in the
                // detail column (same behaviour as clicking the equivalent sidebar link).
                if let dest = welcomeNavDest {
                    VStack(spacing: 0) {
                        // Back bar — returns to WelcomeToMan1fest0
                        HStack(spacing: 8) {
                            Button {
                                welcomeNavDest = nil
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "chevron.left")
                                    Text("Home")
                                }
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.accentColor)
                            Spacer()
                            Text(dest.replacingOccurrences(of: "View", with: ""))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        Divider()
                        welcomeDestinationView(dest)
                    }
                } else if showWelcome || shouldShowWelcomeDueToCachedCredentials {
                    WelcomeToMan1fest0(onNavigate: { destination in
                        welcomeNavDest = destination
                    })
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
    
    /// Maps a destination string (from AppFeature.destination) to the corresponding view,
    /// mirroring the same destinations used by the sidebar NavigationLinks in OptionsView.
    @ViewBuilder
    private func welcomeDestinationView(_ destination: String) -> some View {
        switch destination {
        case "PolicyView":
            PolicyView(server: server, selectedResourceType: .policy)
        case "PoliciesActionView":
            PoliciesActionView(server: server, selectedResourceType: .policies)
        case "PackageView", "PackagesView":
            PackagesView(server: server, selectedResourceType: .packages)
        case "ScriptsView":
            ScriptsView(server: server)
        case "ScriptUsageView":
            ScriptUsageView(server: server)
        case "ComputerView":
            ComputersView(server: server)
        case "ComputerGroupView":
            GroupsView(server: server)
        case "PrestageView":
            PrestagesView(server: server, allPrestages: [])
        case "BuildingsView":
            BuildingsView(server: server)
        case "CategoriesView":
            CategoriesView(selectedResourceType: .category, server: server)
        case "DepartmentsView":
            DepartmentsView(selectedResourceType: .department, server: server)
        case "IconsView":
            IconsView(server: server)
        case "CreateView":
            CreateView(server: server)
        default:
            Text("Navigate to \(destination)")
                .font(.title2)
                .foregroundColor(.secondary)
        }
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
                    if let intersect = screens.first(where: { $0.visibleFrame.intersects(rect) }) {
                        // Clamp to the intersecting screen's visible frame
                        let vis = intersect.visibleFrame
                        // If the saved rect is larger than the visible area for this
                        // screen (e.g., saved on a different monitor), center a
                        // clamped rect so the window stays fully on-screen.
                        let clampedWidth = min(rect.size.width, vis.width)
                        let clampedHeight = min(rect.size.height, vis.height)
                        rect.size.width = clampedWidth
                        rect.size.height = clampedHeight
                        rect.origin.x = vis.origin.x + (vis.width - clampedWidth) / 2.0
                        rect.origin.y = vis.origin.y + (vis.height - clampedHeight) / 2.0
                    } else {
                        // Fallback to main screen
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
