import SwiftUI

// MARK: - Security Settings View
struct SecuritySettingsView: View {
    
    // MARK: - Environment Objects
    @EnvironmentObject var securitySettings: SecuritySettingsManager
    @EnvironmentObject var networkController: NetBrain
    
    // MARK: - State Properties
    @State private var showingKeychainAlert = false
    @State private var keychainAlertMessage = ""
    @State private var showingClearConfirmation = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Inactivity Timeout Section
                Section("Inactivity Lock") {
                    Picker("Lock after inactivity", selection: $securitySettings.inactivityTimeout) {
                        ForEach(SecuritySettingsManager.InactivityTimeout.allCases) { timeout in
                            Text(timeout.displayName).tag(timeout)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    if securitySettings.inactivityTimeout != .never {
                        Text("App will lock automatically after \(securitySettings.inactivityTimeout.displayName) of inactivity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // MARK: - Password Requirements Section
                Section("Password Requirements") {
                    Toggle("Require password to unlock", isOn: $securitySettings.requirePasswordOnWake)
                    
                    if securitySettings.requirePasswordOnWake {
                        Text("You must enter your password when the app is locked")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // MARK: - Keychain Section
                Section("Keychain Integration") {
                    Toggle("Save password in keychain", isOn: $securitySettings.useKeychainForPassword)
                    
                    if securitySettings.useKeychainForPassword {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Keychain Status")
                                .font(.headline)
                            
                            keychainStatusView
                            
                            HStack {
                                Button("Test Keychain") {
                                    testKeychainAccess()
                                }
                                .buttonStyle(.bordered)
                                
                                Spacer()
                                
                                Button("Clear Saved") {
                                    showingClearConfirmation = true
                                }
                                .buttonStyle(.bordered)
                                .foregroundColor(.red)
                            }
                        }
                    } else {
                        Text("Password will not be saved and must be entered each time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // MARK: - Security Information Section
                Section("Security Information") {
                    VStack(alignment: .leading, spacing: 8) {
                        InfoRow(
                            title: "Current Status",
                            value: securitySettings.isLocked() ? "Locked" : "Unlocked",
                            color: securitySettings.isLocked() ? .red : .green
                        )
                        
                        if let lastActive = securitySettings.getLastActiveTime() {
                            InfoRow(
                                title: "Last Active",
                                value: formatTime(lastActive),
                                color: .primary
                            )
                        }
                        
                        InfoRow(
                            title: "Timeout Setting",
                            value: securitySettings.inactivityTimeout.displayName,
                            color: .primary
                        )
                    }
                }
            }
            .navigationTitle("Security Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Save settings and dismiss
                        securitySettings.saveSettings()
                        // Dismiss the view (you'll need to handle this in the parent)
                    }
                }
            }
        }
        .alert("Keychain Access", isPresented: $showingKeychainAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(keychainAlertMessage)
        }
        .alert("Clear Keychain", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearKeychainPassword()
            }
        } message: {
            Text("This will remove the saved password from the keychain. You will need to enter your password manually next time.")
        }
        .onDisappear {
            securitySettings.saveSettings()
        }
    }
    
    // MARK: - Keychain Status View
    private var keychainStatusView: some View {
        HStack {
            Image(systemName: keychainStatusIcon)
                .foregroundColor(keychainStatusColor)
            
            VStack(alignment: .leading) {
                Text(keychainStatusText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if securitySettings.useKeychainForPassword {
                    Text("Password is stored securely in macOS/iOS keychain")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Computed Properties
    private var keychainStatusIcon: String {
        if !securitySettings.useKeychainForPassword {
            return "xmark.circle.fill"
        }
        
        let username = networkController.username
        if let _ = securitySettings.getPasswordFromKeychain(username: username) {
            return "checkmark.circle.fill"
        } else {
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var keychainStatusColor: Color {
        if !securitySettings.useKeychainForPassword {
            return .gray
        }
        
        let username = networkController.username
        if securitySettings.getPasswordFromKeychain(username: username) != nil {
            return .green
        } else {
            return .orange
        }
    }
    
    private var keychainStatusText: String {
        if !securitySettings.useKeychainForPassword {
            return "Keychain Disabled"
        }
        
        let username = networkController.username
        if securitySettings.getPasswordFromKeychain(username: username) != nil {
            return "Password Saved"
        } else {
            return "No Password Saved"
        }
    }
    
    // MARK: - Methods
    private func testKeychainAccess() {
        let username = networkController.username
        
        guard !username.isEmpty else {
            keychainAlertMessage = "No username available. Please log in first."
            showingKeychainAlert = true
            return
        }
        
        if let password = securitySettings.getPasswordFromKeychain(username: username) {
            // Test the password by attempting to get a token
            Task {
                do {
                    let _ = try await networkController.getToken(
                        server: networkController.server,
                        username: username,
                        password: password
                    )
                    
                    await MainActor.run {
                        keychainAlertMessage = "✅ Keychain password is valid and working correctly."
                        showingKeychainAlert = true
                    }
                } catch {
                    await MainActor.run {
                        keychainAlertMessage = "⚠️ Keychain password is stored but invalid. Consider updating or clearing it."
                        showingKeychainAlert = true
                    }
                }
            }
        } else {
            keychainAlertMessage = "No password found in keychain for current user."
            showingKeychainAlert = true
        }
    }
    
    private func clearKeychainPassword() {
        let username = networkController.username
        securitySettings.clearKeychainPassword(username: username)
        
        keychainAlertMessage = "✅ Password removed from keychain successfully."
        showingKeychainAlert = true
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Info Row Component
struct InfoRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .foregroundColor(color)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview
struct SecuritySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SecuritySettingsView()
            .environmentObject(SecuritySettingsManager())
            .environmentObject(NetBrain())
    }
}