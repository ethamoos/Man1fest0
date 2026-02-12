import SwiftUI
import Foundation

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
    
    // MARK: - User Preferences
    @State private var showWelcomeScreen = UserDefaults.standard.bool(forKey: "ShowWelcomeScreen")
    @State private var defaultLandingPage = UserDefaults.standard.string(forKey: "DefaultLandingPage") ?? "OptionsView"
    
    private let landingPageOptions = [
        ("OptionsView", "Options Menu"),
        ("PolicyView", "Policies"),
        ("ComputerView", "Computers"),
        ("ScriptsView", "Scripts"),
        ("PackageView", "Packages")
    ]
    
    // MARK: - Navigation Coordinator
    private func determineInitialView() -> AnyView {
        if showWelcomeScreen {
            return AnyView(WelcomeScreenView())
        }
        
        return getViewForLandingPage(defaultLandingPage)
    }
    
    @ViewBuilder
    private func getViewForLandingPage(_ landingPage: String) -> some View {
        switch landingPage {
        case "PolicyView":
            Text("Policies View - Coming Soon")
                .font(.title)
                .padding()
        case "ComputerView":
            Text("Computers View - Coming Soon")
                .font(.title)
                .padding()
        case "ScriptsView":
            Text("Scripts View - Coming Soon")
                .font(.title)
                .padding()
        case "PackageView":
            Text("Packages View - Coming Soon")
                .font(.title)
                .padding()
        default:
            if #available(macOS 13.3, *) {
                OptionsView()
            } else {
                Text("Options View")
                    .font(.title)
                    .padding()
            }
        }
    }
    
    var body: some View {
        Group {
            if networkController.isLoading {
                VStack {
                    ProgressView()
                    Text("Loading…").foregroundColor(Color.gray)
                }
            } else {
                NavigationView {
                    determineInitialView()
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

// MARK: - Simple Welcome Screen View
struct WelcomeScreenView: View {
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Welcome header
                welcomeHeaderSection
                
                // Feature categories
                featureCategoriesGrid
                
                // Quick actions
                quickActionsSection
                
                // Getting started
                gettingStartedSection
                
                Spacer()
            }
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Welcome to Man1fest0")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        UserDefaults.standard.set(false, forKey: "ShowWelcomeScreen")
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            // Set welcome screen as shown for first-time users
            if !UserDefaults.standard.bool(forKey: "WelcomeScreenShown") {
                UserDefaults.standard.set(true, forKey: "WelcomeScreenShown")
            }
        }
    }
    
    // MARK: - Welcome Screen Sections
    private var welcomeHeaderSection: some View {
        VStack(spacing: 20) {
            // App logo and title
            HStack {
                Image(systemName: "gearshape.2.fill")
                    .font(.system(size: 60, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 5, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Man1fest0")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Jamf Pro Management Tool")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Welcome message
            VStack(alignment: .leading, spacing: 12) {
                Text("Welcome back!")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Manage your Jamf Pro environment with powerful tools for policies, packages, scripts, and computer management.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(30)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    private var featureCategoriesGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(minimum: 280)),
                GridItem(.flexible(minimum: 280))
            ], spacing: 20) {
                ForEach(featureCategories, id: \.self) { category in
                    featureCategoryCard(title: category, features: getFeatures(for: category))
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 400)
    }
    
    private var quickActionsSection: some View {
        VStack(spacing: 16) {
            Text("Quick Actions")
                .font(.title2)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                quickActionCard(title: "Policies", icon: "doc.text.fill", destination: "PolicyView")
                quickActionCard(title: "Computers", icon: "desktopcomputer.fill", destination: "ComputerView")
                quickActionCard(title: "Scripts", icon: "terminal.fill", destination: "ScriptsView")
                quickActionCard(title: "Packages", icon: "box.fill", destination: "PackageView")
                quickActionCard(title: "Settings", icon: "gearshape.fill", destination: "OptionsView")
            }
        }
        .padding(.horizontal, 30)
    }
    
    private var gettingStartedSection: some View {
        VStack(spacing: 16) {
            Text("Getting Started")
                .font(.title2)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                gettingStartedStepCard(number: 1, title: "Connect to Jamf", description: "Enter your server credentials", icon: "server.rack")
                gettingStartedStepCard(number: 2, title: "Load Data", description: "Policies, computers, and scripts will be loaded", icon: "arrow.down.circle.fill")
                gettingStartedStepCard(number: 3, title: "Manage Resources", description: "Use powerful management tools", icon: "gearshape.2.fill")
            }
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 20)
    }
    
    // MARK: - Data
    private var featureCategories: [String] {
        return ["Policy Management", "Device Management", "Script Management", "System Administration"]
    }
    
    private func getFeatures(for category: String) -> [String] {
        switch category {
        case "Policy Management":
            return ["View Policies", "Policy Actions", "Package Configuration"]
        case "Device Management":
            return ["View Computers", "Computer Groups", "Manage Buildings"]
        case "Script Management":
            return ["View Scripts", "Script Usage", "Script Deployment"]
        case "System Administration":
            return ["Manage Categories", "Manage Icons", "Manage Departments"]
        default:
            return []
        }
    }
    
    // MARK: - Supporting Views
    private func featureCategoryCard(title: String, features: [String]) -> some View {
        VStack(spacing: 16) {
            // Category header
            HStack {
                Image(systemName: getIconForCategory(title))
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(features.count) features")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 12)
            
            // Feature list
            LazyVGrid(columns: [
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(features, id: \.self) { feature in
                    Text("• \(feature)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private func quickActionCard(title: String, icon: String, destination: String) -> some View {
        NavigationLink(destination: getViewForDestination(destination)) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .blue.opacity(0.3), radius: 6, x: 0, y: 3)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
        }
    }
    
    private func gettingStartedStepCard(number: Int, title: String, description: String, icon: String) -> some View {
        HStack(spacing: 16) {
            // Step number
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Text("\(number)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            // Step content
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            // Step icon
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func getIconForCategory(_ category: String) -> String {
        switch category {
        case "Policy Management": return "doc.text.fill"
        case "Device Management": return "desktopcomputer.fill"
        case "Script Management": return "terminal.fill"
        case "System Administration": return "gearshape.fill"
        default: return "square.grid.3x3"
        }
    }
    
    @ViewBuilder
    private func getViewForDestination(_ destination: String) -> some View {
        switch destination {
        case "OptionsView":
            if #available(macOS 13.3, *) {
                return AnyView(OptionsView())
            } else {
                return AnyView(Text("Options View").font(.title).padding())
            }
        case "PolicyView":
            return AnyView(Text("Policies View - Coming Soon").font(.title).padding())
        case "ComputerView":
            return AnyView(Text("Computers View - Coming Soon").font(.title).padding())
        case "ScriptsView":
            return AnyView(Text("Scripts View - Coming Soon").font(.title).padding())
        case "PackageView":
            return AnyView(Text("Packages View - Coming Soon").font(.title).padding())
        default:
            return AnyView(Text("Feature Coming Soon").font(.title).padding())
        }
    }
}