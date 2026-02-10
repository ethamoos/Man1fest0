import SwiftUI

// MARK: - Lock Screen View
struct LockScreenView: View {
    
    // MARK: - Environment Objects
    @EnvironmentObject var securitySettings: SecuritySettingsManager
    @EnvironmentObject var inactivityMonitor: InactivityMonitor
    @EnvironmentObject var networkController: NetBrain
    
    // MARK: - State Properties
    @State private var password: String = ""
    @State private var isUnlocked = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var useKeychainPassword = false
    
    // MARK: - Computed Properties
    private var storedUsername: String {
        networkController.username
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Blurred background
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Lock Icon
                Image(systemName: "lock.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                // Title
                Text("Man1fest0 Locked")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // Message
                Text("The app has been locked due to inactivity")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                // Password Input Section
                if securitySettings.requirePasswordOnWake {
                    passwordInputSection
                } else {
                    unlockButtonSection
                }
                
                // Keychain Option
                if securitySettings.useKeychainForPassword && securitySettings.requirePasswordOnWake {
                    keychainOptionSection
                }
                
                Spacer()
            }
            .padding(40)
        }
        .onAppear {
            setupInitialState()
        }
        .alert("Unlock Failed", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Password Input Section
    private var passwordInputSection: some View {
        VStack(spacing: 20) {
            // Username display
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(.gray)
                Text(storedUsername)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
            
            // Password field
            HStack {
                Image(systemName: "key.fill")
                    .foregroundColor(.gray)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                
                if !password.isEmpty {
                    Button(action: { password = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
            
            // Unlock button
            Button(action: attemptUnlock) {
                HStack {
                    if isUnlocked {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text("Unlock")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(password.isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(password.isEmpty || isUnlocked)
        }
    }
    
    // MARK: - Unlock Button Section (No Password Required)
    private var unlockButtonSection: some View {
        Button(action: attemptUnlock) {
            HStack {
                if isUnlocked {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                Text("Unlock App")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(isUnlocked)
    }
    
    // MARK: - Keychain Option Section
    private var keychainOptionSection: some View {
        VStack(spacing: 10) {
            if useKeychainPassword {
                Button(action: attemptUnlockWithKeychain) {
                    HStack {
                        Image(systemName: "key.fill")
                        Text("Use Saved Password")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isUnlocked)
            }
            
            Button(action: { useKeychainPassword.toggle() }) {
                HStack {
                    Image(systemName: useKeychainPassword ? "checkmark.square.fill" : "square")
                        .foregroundColor(useKeychainPassword ? .blue : .gray)
                    Text("Use keychain password")
                        .foregroundColor(.white)
                }
                .font(.caption)
            }
        }
    }
    
    // MARK: - Methods
    private func setupInitialState() {
        password = ""
        isUnlocked = false
        useKeychainPassword = false
        
        // Check if keychain password is available
        if securitySettings.useKeychainForPassword {
            useKeychainPassword = securitySettings.getPasswordFromKeychain(username: storedUsername) != nil
        }
    }
    
    private func attemptUnlock() {
        isUnlocked = true
        
        Task {
            do {
                if securitySettings.requirePasswordOnWake {
                    // Verify password by attempting to get a new token
                    let _ = try await networkController.getToken(
                        server: networkController.server,
                        username: storedUsername,
                        password: password
                    )
                    
                    // Save password to keychain if enabled
                    if securitySettings.useKeychainForPassword {
                        securitySettings.savePasswordToKeychain(password, username: storedUsername)
                    }
                }
                
                // Unlock successful
                await MainActor.run {
                    inactivityMonitor.unlockApp()
                }
                
            } catch {
                // Unlock failed
                await MainActor.run {
                    isUnlocked = false
                    errorMessage = "Invalid password. Please try again."
                    showingError = true
                    password = ""
                }
            }
        }
    }
    
    private func attemptUnlockWithKeychain() {
        guard let keychainPassword = securitySettings.getPasswordFromKeychain(username: storedUsername) else {
            errorMessage = "No saved password found in keychain."
            showingError = true
            return
        }
        
        isUnlocked = true
        
        Task {
            do {
                // Verify keychain password
                let _ = try await networkController.getToken(
                    server: networkController.server,
                    username: storedUsername,
                    password: keychainPassword
                )
                
                // Unlock successful
                await MainActor.run {
                    inactivityMonitor.unlockApp()
                }
                
            } catch {
                // Keychain password is invalid
                await MainActor.run {
                    isUnlocked = false
                    errorMessage = "Saved password is invalid. Please enter your password manually."
                    showingError = true
                    useKeychainPassword = false
                }
            }
        }
    }
}

// MARK: - Preview
struct LockScreenView_Previews: PreviewProvider {
    static var previews: some View {
        LockScreenView()
            .environmentObject(SecuritySettingsManager())
            .environmentObject(InactivityMonitor(securitySettings: SecuritySettingsManager()))
            .environmentObject(NetBrain())
            .preferredColorScheme(.dark)
    }
}