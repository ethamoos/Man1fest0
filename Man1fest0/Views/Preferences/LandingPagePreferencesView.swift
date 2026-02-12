import SwiftUI

// MARK: - Landing Page Preferences View
struct LandingPagePreferencesView: View {
    
    // MARK: - Environment Objects
    @StateObject private var userPreferences = AppUserPreferences()
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Landing Page Selection
                Section {
                    Text("Default Landing Page")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    Text("Choose which page Man1fest0 should show after you log in. This setting is used each time you open the app.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 16)
                    
                    // Landing page selection
                    ForEach(AppUserPreferences.DefaultLandingPage.allCases, id: \.self) { page in
                        landingPageOption(page)
                    }
                }
                
                // MARK: - Additional Options
                Section {
                    Toggle("Remember my preference", isOn: $userPreferences.rememberUserPreference)
                        .help("When enabled, your selection will be saved and used automatically. When disabled, you'll be asked each time.")
                    
                    if userPreferences.rememberUserPreference {
                        Text("Your preference is saved and will be used on your next login.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Your preference will be forgotten after this session.")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                // MARK: - Reset Options
                Section {
                    Button("Reset to Default Settings") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            userPreferences.resetToDefaults()
                        }
                    }
                    .foregroundColor(.red)
                    
                    Text("Resets all preferences to their default values.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Landing Page")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        userPreferences.savePreferences()
                    }
                }
            }
        }
        .onDisappear {
            // Save preferences when leaving the view
            userPreferences.savePreferences()
        }
    }
    
    // MARK: - Landing Page Option
    private func landingPageOption(_ page: AppUserPreferences.DefaultLandingPage) -> some View {
        HStack {
            // Radio button
            Image(systemName: userPreferences.defaultLandingPage == page ? "largecircle.fill.circle" : "circle")
                .foregroundColor(userPreferences.defaultLandingPage == page ? .blue : .secondary)
                .font(.system(size: 16, weight: .medium))
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(page.displayName)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if page == .options {
                        Text("(Recommended)")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                    }
                }
                
                Text(page.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                userPreferences.defaultLandingPage = page
            }
        }
    }
}

// MARK: - Welcome Screen Preferences View
struct WelcomeScreenPreferencesView: View {
    
    // MARK: - Environment Objects
    @StateObject private var userPreferences = AppUserPreferences()
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Welcome Screen Toggle
                Section {
                    Text("Welcome Screen")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    Text("Control whether the welcome screen appears when you launch Man1fest0.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 16)
                    
                    Toggle("Show Welcome Screen", isOn: $userPreferences.shouldShowWelcomeScreen)
                        .help("When enabled, the welcome screen with feature overview will appear on app launch. Disable to jump directly to your chosen landing page.")
                }
                
                if !userPreferences.shouldShowWelcomeScreen {
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
                VStack(alignment: .leading, spacing: 12) {
                    Text("Welcome Screen Preview")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("When enabled, the welcome screen shows:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Feature preview list
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
                    // This would show a preview or open the welcome screen
                    print("Preview welcome screen requested")
                }
                .foregroundColor(.blue)
                
                Text("Temporarily shows the welcome screen without changing your preference.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // MARK: - Reset Options
            Section {
                Button("Reset All Preferences") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        userPreferences.resetToDefaults()
                    }
                }
                .foregroundColor(.red)
                
                Text("Resets all preferences including welcome screen and landing page settings.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Welcome Screen")
        .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        userPreferences.savePreferences()
                    }
                }
            }
        }
        .onDisappear {
            // Save preferences when leaving the view
            userPreferences.savePreferences()
        }
    }
    
    // MARK: - Feature Preview Row
    private func welcomeFeatureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Enhanced App Navigation Coordinator
@MainActor
class AppNavigationCoordinator: ObservableObject {
    @Published var shouldShowWelcomeScreen = false
    @Published var selectedLandingPage: String = ""
    
    private let userPreferences = AppUserPreferences()
    
    init() {
        loadNavigationSettings()
    }
    
    // MARK: - Navigation Control
    func determineInitialView() -> AnyView {
        userPreferences.loadPreferences()
        
        // Check if welcome screen should be shown
        if userPreferences.shouldShowWelcomeScreen {
            return AnyView(WelcomeToMan1fest0()
                .environmentObject(userPreferences)
                .environmentObject(NetBrain())
        )
        }
        
        // Navigate to the selected landing page
        return getViewForLandingPage(userPreferences.defaultLandingPage)
    }
    
    private func getViewForLandingPage(_ landingPage: AppUserPreferences.DefaultLandingPage) -> AnyView {
        switch landingPage {
        case .options:
            return AnyView(OptionsView()
                .environmentObject(userPreferences)
                .environmentObject(NetBrain())
            )
        case .policies:
            return AnyView(PolicyView()
                .environmentObject(userPreferences)
                .environmentObject(NetBrain())
            )
        case .computers:
            return AnyView(ComputerView()
                .environmentObject(userPreferences)
                .environmentObject(NetBrain())
            )
        case .scripts:
            return AnyView(ScriptsView()
                .environmentObject(userPreferences)
                .environmentObject(NetBrain())
            )
        case .packages:
            return AnyView(PackageView()
                .environmentObject(userPreferences)
                .environmentObject(NetBrain())
            )
        }
    }
    
    // MARK: - Settings Management
    private func loadNavigationSettings() {
        userPreferences.loadPreferences()
        shouldShowWelcomeScreen = userPreferences.shouldShowWelcomeScreen
        selectedLandingPage = userPreferences.defaultLandingPage.rawValue
    }
    
    func saveNavigationSettings() {
        userPreferences.savePreferences()
        shouldShowWelcomeScreen = userPreferences.shouldShowWelcomeScreen
        selectedLandingPage = userPreferences.defaultLandingPage.rawValue
    }
}