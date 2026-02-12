import SwiftUI

// MARK: - Simple Landing Page Preferences
struct SimpleLandingPagePreferencesView: View {
    
    // MARK: - State
    @State private var selectedLandingPage: String = UserDefaults.standard.string(forKey: "DefaultLandingPage") ?? "OptionsView"
    
    private let landingPageOptions = [
        ("OptionsView", "Options Menu"),
        ("PolicyView", "Policies"),
        ("ComputerView", "Computers"),
        ("ScriptsView", "Scripts"),
        ("PackageView", "Packages")
    ]
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Text("Default Landing Page")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    Text("Choose which page Man1fest0 should show after you log in.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 16)
                    
                    // Landing page selection
                    ForEach(landingPageOptions, id: \.0) { option in
                        landingPageOption(title: option.title, value: option.0, isSelected: selectedLandingPage == option.0)
                    }
                }
                
                Section {
                    Button("Reset to Default") {
                        selectedLandingPage = "OptionsView"
                        UserDefaults.standard.set("OptionsView", forKey: "DefaultLandingPage")
                    }
                    .foregroundColor(.red)
                    
                    Text("Sets Options Menu as the default landing page.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Landing Page")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        UserDefaults.standard.set(selectedLandingPage, forKey: "DefaultLandingPage")
                    }
                }
            }
        }
    }
    
    // MARK: - Landing Page Option
    private func landingPageOption(title: String, value: String, isSelected: Bool) -> some View {
        HStack {
            // Radio button
            Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                .foregroundColor(isSelected ? .blue : .secondary)
                .font(.system(size: 16, weight: .medium))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if value == "OptionsView" {
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
            selectedLandingPage = value
        }
    }
}

// MARK: - Simple Welcome Screen Preferences
struct SimpleWelcomeScreenPreferencesView: View {
    
    // MARK: - State
    @State private var showWelcomeScreen = UserDefaults.standard.bool(forKey: "ShowWelcomeScreen")
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Text("Welcome Screen")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    Text("Control whether the welcome screen appears when you launch Man1fest0.")
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
                
                Section {
                    Button("Test Welcome Screen") {
                        // This would show a preview or open the welcome screen
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
                        UserDefaults.standard.set(true, forKey: "ShowWelcomeScreen")
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
}