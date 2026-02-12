import SwiftUI

// MARK: - Stub Implementation - Uses Existing Patterns

// Stub for SimpleSecuritySettingsView
// This stub doesn't implement security settings but matches the interface
struct SimpleSecuritySettingsView: View {
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Text("Security Settings")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    Text("Basic security settings placeholder.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .padding()
                }
            }
            .navigationTitle("Security Settings")
        }
    }
}

// Stub for SimpleLandingPagePreferencesView
struct SimpleLandingPagePreferencesView: View {
    @State private var selectedLandingPage: String = "OptionsView"
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Text("Default Landing Page")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    Text("Basic landing page selection.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 16)
                    
                    ForEach(SimpleLandingPageOptions.allCases, id: \.0) { option in
                        landingPageOption(option: option)
                    }
                }
                
                Section {
                    Button("Save Preferences") {
                        // Implementation would go here
                        print("Landing page preferences saved")
                    }
                    .foregroundColor(.blue)
                    
                    Text("Your selection will be used on your next login.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Landing Page")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Implementation would go here
                    }
                }
            }
        }
    }
    
    private func landingPageOption(_ option: SimpleLandingPageOptions) -> some View {
        HStack {
            Image(systemName: selectedLandingPage == option ? "largecircle.fill.circle" : "circle")
                .foregroundColor(selectedLandingPage == option ? .blue : .secondary)
                .font(.system(size: 16, weight: .medium))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(option.displayName)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if option == .options {
                    Text("(Recommended)")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            selectedLandingPage = option
        }
    }
}

// Stub for WelcomeScreenPreferencesView  
struct WelcomeScreenPreferencesView: View {
    @State private var showWelcomeScreen = UserDefaults.standard.bool(forKey: "ShowWelcomeScreen")
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Text("Welcome Screen")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    Text("Welcome screen control preferences.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 16)
                    
                    Toggle("Show Welcome Screen", isOn: $showWelcomeScreen)
                        .help("When enabled, the welcome screen with feature overview will appear on app launch. Disable to jump directly to your chosen landing page.")
                }
                
                if !showWelcomeScreen {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("Welcome screen is disabled. You'll go directly to your selected landing page.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                }
            }
            
            // MARK: - Preview Information
            Section {
                Text("Welcome Screen Preview")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("When enabled, the welcome screen shows:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        welcomeFeatureRow(icon: "doc.text.fill", title: "Policy Management", description: "View and manage all Jamf policies")
                        welcomeFeatureRow(icon: "desktopcomputer.fill", title: "Device Management", description: "Manage computers and groups")
                        welcomeFeatureRow(icon: "terminal.fill", title: "Script Management", description: "Handle script deployment and usage")
                        welcomeFeatureRow(icon: "gearshape.fill", title: "System Administration", description: "Access categories, icons, and settings")
                    }
                    .padding(.leading, 20)
                }
            }
            
            // MARK: - Quick Actions
            Section {
                Button("Preview Welcome Screen") {
                    // Implementation would go here
                    print("Preview welcome screen requested")
                }
                .foregroundColor(.blue)
                
                Text("Temporarily shows the welcome screen without changing your preference.")
                    .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    Button("Reset All Preferences") {
                        showWelcomeScreen = true
                        UserDefaults.standard.set("OptionsView", forKey: "DefaultLandingPage")
                    }
                    .foregroundColor(.red)
                    
                    Text("Resets all preferences to their default values.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Welcome Screen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        UserDefaults.standard.set(showWelcomeScreen, forKey: "ShowWelcomeScreen")
                    }
                }
            }
        }
    }
    
    // MARK: - Supporting Views
    private func welcomeFeatureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Simple App User Preferences
struct AppUserPreferences: ObservableObject {
    @Published var shouldShowWelcomeScreen = false
    @Published var defaultLandingPage: String = "OptionsView"
    
    private enum Keys {
        static let shouldShowWelcomeScreen = "ShowWelcomeScreen"
        static let defaultLandingPage = "DefaultLandingPage"
        static let rememberUserPreference = "RememberUserPreference"
    }
    
    init() {
        loadPreferences()
    }
    
    func loadPreferences() {
        shouldShowWelcomeScreen = UserDefaults.standard.bool(forKey: Keys.shouldShowWelcomeScreen)
        
        if let landingPageRaw = UserDefaults.standard.string(forKey: Keys.defaultLandingPage),
           let landingPage = DefaultLandingPage(rawValue: landingPageRaw) {
            defaultLandingPage = landingPage
        } else {
            defaultLandingPage = .options
        }
        
        rememberUserPreference = UserDefaults.standard.bool(forKey: Keys.rememberUserPreference)
        
        // Default to showing welcome screen on first launch if not set
        if !UserDefaults.standard.bool(forKey: Keys.shouldShowWelcomeScreen + "Set") {
            shouldShowWelcomeScreen = true
            UserDefaults.standard.set(true, forKey: Keys.shouldShowWelcomeScreen + "Set")
        }
    }
    
    func savePreferences() {
        UserDefaults.standard.set(shouldShowWelcomeScreen, forKey: Keys.shouldShowWelcomeScreen)
        UserDefaults.standard.set(defaultLandingPage.rawValue, forKey: Keys.defaultLandingPage)
        UserDefaults.standard.set(rememberUserPreference, forKey: Keys.rememberUserPreference)
    }
    
    func resetToDefaults() {
        shouldShowWelcomeScreen = true
        defaultLandingPage = .options
        rememberUserPreference = true
        savePreferences()
    }
}