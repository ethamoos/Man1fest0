import SwiftUI

// MARK: - Secure App Wrapper
struct SecureAppWrapper<Content: View>: View {
    
    // MARK: - Content
    let content: Content
    
    // MARK: - Environment Objects
    @StateObject private var securitySettings = SecuritySettingsManager()
    @StateObject private var inactivityMonitor: InactivityMonitor
    
    // MARK: - Initialization
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
        self._inactivityMonitor = StateObject(wrappedValue: InactivityMonitor(securitySettings: securitySettings))
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
                    .environmentObject(NetBrain()) // You'll need to pass the actual networkController
                    .transition(.opacity)
                    .zIndex(1000)
            }
        }
        .onAppear {
            // Start monitoring when app appears
            inactivityMonitor.resetInactivityTimer()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Check lock status when app comes to foreground
            inactivityMonitor.checkLockStatus()
        }
    }
}

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
        content
            .onTapGesture {
                inactivityMonitor.trackUserActivity()
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        inactivityMonitor.trackUserActivity()
                    }
            )
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)) { _ in
                inactivityMonitor.trackUserActivity()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { _ in
                inactivityMonitor.trackUserActivity()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)) { _ in
                inactivityMonitor.trackUserActivity()
            }
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