import SwiftUI

//
//  ContentView.swift
//
//  Created by Amos Deane on 22/03/2024.
//

struct ContentView: View {
    
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var progress: Progress
    
    // #######################################################################
    //  Login
    // #######################################################################
    
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
                    EnhancedOptionsView()
                } else {
                    // Fallback on earlier versions
                    Text("Options")
                        .font(.title)
                }
            }
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
}

// MARK: - Enhanced Options View with Welcome/Landing Preferences
struct EnhancedOptionsView: View {
    
    @State private var showWelcomeScreen = UserDefaults.standard.bool(forKey: "ShowWelcomeScreen")
    @State private var defaultLandingPage = UserDefaults.standard.string(forKey: "DefaultLandingPage") ?? "OptionsView"
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Original Options
                Section {
                    Text("Man1fest0 Options")
                        .font(.headline)
                    
                    Text("Select an item to manage your Jamf Pro environment.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // MARK: - Security Settings (existing)
                Section {
                    NavigationLink(destination: PolicyDelayInlineView()) {
                        Text("Policy Fetch Delay")
                    }
                    
                    NavigationLink(destination: SimpleSecuritySettingsView()) {
                        Text("Simple Security Settings")
                    }
                }
                
                // MARK: - New Preferences
                Section {
                    NavigationLink(destination: SimpleLandingPagePreferencesView()) {
                        HStack {
                            Image(systemName: "house.fill")
                            Text("Default Landing Page")
                        }
                    }
                    
                    NavigationLink(destination: SimpleWelcomeScreenPreferencesView()) {
                        HStack {
                            Image(systemName: "sparkles.star.fill")
                            Text("Welcome Screen")
                        }
                    }
                }
            }
            .navigationTitle("Enhanced Options")
        }
    }
}