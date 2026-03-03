import Foundation
import SwiftUI
import Combine

// MARK: - Inactivity Monitor
@MainActor
class InactivityMonitor: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLocked = false
    @Published var showLockScreen = false
    
    // MARK: - Private Properties
    private var inactivityTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let securitySettings: SecuritySettingsManager
    
    // MARK: - Initialization
    init(securitySettings: SecuritySettingsManager) {
        self.securitySettings = securitySettings
        
        // Monitor app state changes
        #if canImport(UIKit)
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.appDidBecomeActive()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.appWillResignActive()
            }
            .store(in: &cancellables)
        #endif
        
        #if os(macOS)
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didWakeNotification)
            .sink { [weak self] _ in
                self?.systemDidWake()
            }
            .store(in: &cancellables)
        
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.willSleepNotification)
            .sink { [weak self] _ in
                self?.systemWillSleep()
            }
            .store(in: &cancellables)
        #endif
        
        // Check lock status on initialization
        checkLockStatus()
    }
    
    // MARK: - Public Methods
    func resetInactivityTimer() {
        // Cancel existing timer
        inactivityTimer?.invalidate()
        
        // Update last active time
        securitySettings.updateLastActiveTime()
        
        // Set new timer if timeout is not "never"
        if securitySettings.inactivityTimeout != .never {
            inactivityTimer = Timer.scheduledTimer(withTimeInterval: securitySettings.inactivityTimeout.timeInterval, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    self?.lockApp()
                }
            }
        }
    }
    
    func lockApp() {
        isLocked = true
        showLockScreen = true
        securitySettings.setLocked(true)
        inactivityTimer?.invalidate()
        
        print("🔒 App locked due to inactivity")
    }
    
    func unlockApp(password: String? = nil) {
        // If password is required and not provided, show lock screen
        if securitySettings.requirePasswordOnWake && password == nil {
            showLockScreen = true
            return
        }
        
        // Unlock the app
        isLocked = false
        showLockScreen = false
        securitySettings.setLocked(false)
        securitySettings.updateLastActiveTime()
        
        // Restart inactivity timer
        resetInactivityTimer()
        
        print("🔓 App unlocked")
    }
    
    // MARK: - Internal Methods
    // Made internal (default) so other parts of the app can trigger a manual check
    func checkLockStatus() {
        if securitySettings.shouldLock() {
            lockApp()
        } else {
            resetInactivityTimer()
        }
    }
    
    private func appDidBecomeActive() {
        print("📱 App became active")
        checkLockStatus()
    }
    
    private func appWillResignActive() {
        print("📱 App will resign active")
        inactivityTimer?.invalidate()
    }
    
    #if os(macOS)
    private func systemDidWake() {
        print("💻 System did wake from sleep")
        checkLockStatus()
    }
    
    private func systemWillSleep() {
        print("💻 System will sleep")
        inactivityTimer?.invalidate()
    }
    #endif
    
    // MARK: - User Activity Tracking
    func trackUserActivity() {
        if !isLocked {
            resetInactivityTimer()
        }
    }
    
    // MARK: - Cleanup
    deinit {
        inactivityTimer?.invalidate()
        cancellables.removeAll()
    }
}

// MARK: - User Activity Extension
extension View {
    func trackUserActivity(inactivityMonitor: InactivityMonitor) -> some View {
        var v = self
        #if canImport(UIKit)
        v = v.onReceive(NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)) { _ in
            inactivityMonitor.trackUserActivity()
        }
        #endif
        return v
            .onTapGesture {
                inactivityMonitor.trackUserActivity()
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        inactivityMonitor.trackUserActivity()
                    }
            )
    }
}
