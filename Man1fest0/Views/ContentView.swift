//
//  ContentView.swift
//
//  Created by Amos Deane on 22/03/2024.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var progress: Progress

    //  #######################################################################
    //  Login
    //  #######################################################################
    
    var server: String { UserDefaults.standard.string(forKey: "server") ?? "" }
    var username: String { UserDefaults.standard.string(forKey: "username") ?? "" }
    var password: String = ""
    
    var body: some View {
        
        NavigationView {
            if networkController.isLoading {
                VStack {
                    ProgressView()
                    Text("Loading…").foregroundColor(Color.gray)
                }
            } else {
                if #available(macOS 13.3, *) {
                    OptionsView()
                } else {
                    // Fallback on earlier versions
                }
            }
            WelcomeToMan1fest0()
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
                
                try await networkController.getAllPackages(server: server)
                
                try await networkController.getAllPolicies(server: server, authToken: networkController.authToken)
                
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
