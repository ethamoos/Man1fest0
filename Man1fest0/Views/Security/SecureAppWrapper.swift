import SwiftUI

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
        // Preferences sheet (macOS only)
        #if os(macOS)
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
                .frame(minWidth: 420, minHeight: 260)
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
                Spacer()
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
        VStack(alignment: .leading, spacing: 16) {
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
        .padding(.vertical, 8)
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
