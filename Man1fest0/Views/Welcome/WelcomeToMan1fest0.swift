import SwiftUI

#if os(macOS)
import AppKit
#endif

// Inline SubFeature helper and lists (moved here because the separate file may not be part of the Xcode target)
struct SubFeature: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let detail: String?
    init(_ title: String, detail: String? = nil) {
        self.title = title
        self.detail = detail
    }
}

typealias SubFeatures = [SubFeature]

func makeSubFeatures(_ items: String...) -> SubFeatures { items.map { SubFeature($0) } }

let computerPrestageSubFeatures: SubFeatures = makeSubFeatures(
    "List all computer prestages",
    "View details of computer prestages",
    "View and manage computer prestages",
    "Assign unassigned device to computer prestages"
)

let policySubfeatures: SubFeatures = makeSubFeatures(
    "View and search policies",
    "Inspect detailed policy settings",
    "Export/Download policies",
    "Batch actions and scope changes"
)

let policyActionsSubfeatures: SubFeatures = makeSubFeatures(
    "Batch delete/enable/disable policies",
    "Scope operations: add/remove/clear",
    "Set distribution points for packages"
)

let packageSubfeatures: SubFeatures = makeSubFeatures(
    "List and inspect packages",
    "Assign packages to policies",
    "Upload and download package files"
)

let computersSubfeatures: SubFeatures = makeSubFeatures(
    "View computer inventory",
    "Edit computer group membership",
    "Run remote commands"
)

let computerGroupsSubfeatures: SubFeatures = makeSubFeatures(
    "View computer static groups",
    "View computer smart groups",
    "Edit computer static groups"
)

let createSubfeatures: SubFeatures = makeSubFeatures(
    "Create Departments, Buildings, Categories",
    "Check policies",
"Create scripts",
    "Create packages"
    )


let scriptsSubfeatures: SubFeatures = makeSubFeatures(
    "View and edit scripts",
    "Check for most recent items",
    "Edit script parameters"
)
let scriptsUsageSubfeatures: SubFeatures = makeSubFeatures(
    "View and script usage",
    "Remove unused scripts"
)

let optionsSubfeatures: SubFeatures = makeSubFeatures(
    "Manage app preferences",
    "Connect to Jamf servers",
    "Access advanced tools"
)

// MARK: - App Feature Categories
struct AppFeature: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let iconName: String
    let subFeatures: SubFeatures?
    let destination: String
    let category: String
    let accessLevel: AccessLevel
    
    enum AccessLevel {
        case basic      // Core functionality for all users
        case advanced   // Advanced features and configuration
        case admin      // Administrative functions
        case premium    // Future premium features
    }
}

// MARK: - Welcome/Onboarding View
struct WelcomeToMan1fest0: View {
    
    // MARK: - Environment Objects
    @EnvironmentObject var networkController: NetBrain
    @StateObject private var userPreferences = AppUserPreferences()
    
    // MARK: - State
    @State private var selectedFeature: AppFeature?
    @State private var animateFeatures = false
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Header section
            welcomeHeaderSection
            
            // Feature overview grid
            featureCategoriesGrid
            
            // Quick actions section
//            quickActionsSection
            Spacer()
            // Getting started section
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
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Skip") {
                    userPreferences.shouldShowWelcomeScreen = false
                }
                .foregroundColor(.white)
            }
        }
        .onAppear {
            // Animate features appearing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                animateFeatures = true
            }
        }
    }
    
    // MARK: - View Sections
    private var welcomeHeaderSection: some View {
        VStack(spacing: 20) {
            // App logo and title
            HStack {
                Image("Man1fest0Icon")
                    .resizable()
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
                
                // Small export button: print a summary of all AppFeature entries and copy to pasteboard on macOS
                Button(action: {
                    let all = featureCategories.flatMap { getFeatures(for: $0) }
                    let report = summarizeAppFeatures(all)
                    print("--- App Feature Summary ---\n\(report)")
#if os(macOS)
                    let pb = NSPasteboard.general
                    pb.clearContents()
                    pb.setString(report, forType: .string)
#endif
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .imageScale(.large)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
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
                
                if networkController.authToken.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Please log in to access all features")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(30)
        .background(Color(nsColor: .windowBackgroundColor))
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
                    FeatureCategoryCard(
                        category: category,
                        features: getFeatures(for: category),
                        animateIn: animateFeatures
                    )
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 600)
    }
    
    //    private var quickActionsSection: some View {
    //        VStack(spacing: 16) {
    //            Text("Quick Actions")
    //                .font(.title2)
    //                .fontWeight(.semibold)
    //                .frame(maxWidth: .infinity, alignment: .leading)
    //
    //            LazyVGrid(columns: [
    //                GridItem(.flexible()),
    //                GridItem(.flexible()),
    //                GridItem(.flexible())
    //            ], spacing: 16) {
    //                ForEach(quickActions, id: \.title) { action in
    //                    QuickActionCard(action: action)
    //                }
    //            }
    //        }
    //        .padding(.horizontal, 30)
    //    }
    //
    private var gettingStartedSection: some View {
        VStack(spacing: 16) {
            Text("Getting Started")
                .font(.title2)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                ForEach(gettingStartedSteps, id: \.title) { step in
                    GettingStartedStepCard(step: step)
                }
            }
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 20)
    }
    
    // MARK: - Data
    // ADD NEW FEATURES HERE AND UPDATE getFeatures() SWITCH TO RETURN THEM IN THE CORRECT CATEGORY
    private var featureCategories: [String] {
        return ["Policy Management", "Device Management",  "Script Management", "System Administration","Create Items"]
    }
    
    private func getFeatures(for category: String) -> [AppFeature] {
        switch category {
        case "Policy Management":
            return [
                AppFeature(title: "Policies", description: "View and manage all policies", iconName: "doc.text.fill", subFeatures: policySubfeatures, destination: "PolicyView", category: category, accessLevel: AppFeature.AccessLevel.basic),
                AppFeature(title: "Policy Actions", description: "Batch operations on policies", iconName: "hammer.fill", subFeatures: policyActionsSubfeatures, destination: "PoliciesActionView", category: category, accessLevel: AppFeature.AccessLevel.advanced),
                AppFeature(title: "Package Management", description: "Configure policy packages", iconName: "suitcase.fill", subFeatures: packageSubfeatures, destination: "PackageView", category: category, accessLevel: AppFeature.AccessLevel.advanced)
            ]
        case "Device Management":
            return [
                AppFeature(title: "Computers", description: "View and manage computers", iconName: "desktopcomputer", subFeatures: computersSubfeatures, destination: "ComputerView", category: category, accessLevel: AppFeature.AccessLevel.basic),
                AppFeature(title: "Computer Groups", description: "Organize computers into groups", iconName: "person.3.fill", subFeatures: computerGroupsSubfeatures, destination: "ComputerGroupView", category: category, accessLevel: AppFeature.AccessLevel.basic),
                AppFeature(title: "Computer Prestages", description: "Manage Computers Prestages", iconName: "desktopcomputer", subFeatures: computerPrestageSubFeatures, destination: "PrestageView", category: category, accessLevel: AppFeature.AccessLevel.basic)
            ]
       
//        case "Prestage Management":
//            return [
//                AppFeature(title: "Computer Prestages", description: "Manage Computers Prestages", iconName: "desktopcomputer", subFeatures: computerPrestageSubFeatures, destination: "PrestageView", category: category, accessLevel: AppFeature.AccessLevel.basic)
//            ]
            
        case "Script Management":
            return [
                AppFeature(title: "Scripts", description: "View and manage scripts", iconName: "terminal.fill", subFeatures: scriptsSubfeatures, destination: "ScriptsView", category: category, accessLevel: AppFeature.AccessLevel.basic),
                AppFeature(title: "Script Usage", description: "Track script deployment", iconName: "chart.bar.fill", subFeatures: scriptsSubfeatures, destination: "ScriptUsageView", category: category, accessLevel: AppFeature.AccessLevel.advanced)
            ]
        case "Create Items":
            return [
                AppFeature(title: "Create", description: "Create items", iconName: "hammer.fill", subFeatures: createSubfeatures, destination: "CreateView", category: category, accessLevel: AppFeature.AccessLevel.basic)
            ]
        case "System Administration":
            return [
                AppFeature(title: "Buildings", description: "Manage building locations", iconName: "building.fill", subFeatures: nil, destination: "BuildingsView", category: category, accessLevel: AppFeature.AccessLevel.basic),
                AppFeature(title: "Categories", description: "Manage item categories", iconName: "folder.fill", subFeatures: nil, destination: "CategoriesView", category: category, accessLevel: AppFeature.AccessLevel.basic),
                AppFeature(title: "Departments", description: "Organize departments", iconName: "building.2.fill", subFeatures: nil, destination: "DepartmentsView", category: category, accessLevel: AppFeature.AccessLevel.basic),
                AppFeature(title: "Icons", description: "Manage app icons", iconName: "photo.fill", subFeatures: optionsSubfeatures, destination: "IconsView", category: category, accessLevel: AppFeature.AccessLevel.basic)
            ]
        default:
            return []
        }
        
        
        
    }
    
    
}

private var quickActions: [QuickAction] {
    return [
        QuickAction(
            title: "Policies",
            description: "View all policies",
            iconName: "doc.text.fill",
            destination: "PolicyView",
            color: .blue,
            isAction: false
        ),
        QuickAction(
            title: "Computers",
            description: "Manage computers",
            iconName: "desktopcomputer.fill",
            destination: "ComputerView",
            color: .green,
            isAction: false
        ),
        QuickAction(
            title: "Scripts",
            description: "Manage scripts",
            iconName: "terminal.fill",
            destination: "ScriptsView",
            color: .orange,
            isAction: false
        ),
        QuickAction(
            title: "Packages",
            description: "View packages",
            iconName: "box.fill",
            destination: "PackageView",
            color: .purple,
            isAction: false
        ),
        QuickAction(
            title: "Settings",
            description: "App preferences",
            iconName: "gearshape.fill",
            destination: "OptionsView",
            color: .gray,
            isAction: false
        ),
        QuickAction(
            title: "Refresh Data",
            description: "Update all data",
            iconName: "arrow.clockwise",
            destination: "",
            color: .red,
            isAction: true
        )
    ]
}

private var gettingStartedSteps: [GettingStartedStep] {
    return [
        GettingStartedStep(
            number: 1,
            title: "Connect to Jamf",
            description: "Enter your server credentials",
            iconName: "server.rack"
        ),
        GettingStartedStep(
            number: 2,
            title: "Load Data",
            description: "Policies, computers, and scripts will be loaded",
            iconName: "arrow.down.circle.fill"
        ),
        GettingStartedStep(
            number: 3,
            title: "Manage Resources",
            description: "Use powerful management tools",
            iconName: "gearshape.2.fill"
        )
    ]
}

// MARK: - Feature Category Card
struct FeatureCategoryCard: View {
    let category: String
    let features: [AppFeature]
    let animateIn: Bool
    
    @EnvironmentObject var networkController: NetBrain
    
    var body: some View {
        VStack(spacing: 16) {
            // Category header
            HStack {
                Image(systemName: getIconForCategory(category))
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text(category)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(features.count) features")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 12)
            
            // Feature cards
            LazyVGrid(columns: [
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(features, id: \.id) { feature in
                    NavigationLink(destination: getViewForDestination(feature.destination)) {
                        FeatureCard(feature: feature, animateIn: animateIn)
                            .onTapGesture {
                                prefetchIfNeeded(destination: feature.destination)
                            }
                    }
                }
            }
        }
        .padding(20)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private func getIconForCategory(_ category: String) -> String {
        switch category {
        case "Policy Management": return "doc.text.fill"
        case "Device Management": return "desktopcomputer"
        case "Prestage Management": return "desktopcomputer"
        case "Script Management": return "terminal.fill"
        case "System Administration": return "gearshape.fill"
        case "Create Items": return "hammer.fill"
        default: return "square.grid.3x3"
        }
    }
    
    @ViewBuilder
    private func getViewForDestination(_ destination: String) -> some View {
        // Map known destination strings to actual views in the app
        switch destination {
        case "PolicyView":
            PolicyView(server: networkController.server, selectedResourceType: .policy)
        case "PoliciesActionView":
            PoliciesActionView(server: networkController.server, selectedResourceType: .policies)
        case "PackageView", "PackagesView":
            PackagesView(server: networkController.server, selectedResourceType: .packages)
        case "ScriptsView":
            ScriptsView(server: networkController.server)
        case "ScriptUsageView":
            // Fallback to ScriptsView if a dedicated ScriptUsageView isn't available
            ScriptsView(server: networkController.server)
        default:
            // Generic fallback: show a simple destination placeholder
            Text("Navigate to \(destination)").font(.title2)
        }
    }
    
    // Prefetch network data for known destinations so destination views are not empty on arrival
    private func prefetchIfNeeded(destination: String) {
        switch destination {
        case "PolicyView", "PoliciesActionView":
            Task {
                print("Prefetching policies data for destination: \(destination)")
                // capture the environment object into a local constant for use inside the Task
                let nc = networkController
                try? await nc.getAllPolicies(server: nc.server, authToken: nc.authToken)
                try? await Task.sleep(nanoseconds: 200_000_000) // small delay to let UI update
            }
        case "PackageView", "PackagesView":
            Task {
                print("Prefetching packages data")
                let nc = networkController
                try? await nc.getAllPackages(server: nc.server)
            }
        case "ScriptsView", "ScriptUsageView":
            Task {
                print("Prefetching scripts data")
                let nc = networkController
                try? await nc.getAllScripts(server: nc.server, authToken: nc.authToken)
            }
        default:
            break
        }
    }
}

// MARK: - Feature Card
struct FeatureCard: View {
    let feature: AppFeature
    let animateIn: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon and title
            HStack(spacing: 12) {
                Image(systemName: feature.iconName)
                    .font(.title2)
                    .foregroundColor(colorForAccessLevel(feature.accessLevel))
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(feature.title)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text(feature.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                    
                    // Render sub-features as bullet list when present
                    if let subs = feature.subFeatures, !subs.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(subs) { s in
                                HStack(alignment: .top, spacing: 6) {
                                    Text("•")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(s.title)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                
                Spacer()
            }
            
            // Access level indicator
            HStack {
                Spacer()
                accessLevelIndicator(feature.accessLevel)
            }
        }
    }
}

private func colorForAccessLevel(_ level: AppFeature.AccessLevel) -> Color {
    switch level {
    case .basic: return .blue
    case .advanced: return .orange
    case .admin: return .red
    case .premium: return .purple
    }
}

private func accessLevelIndicator(_ level: AppFeature.AccessLevel) -> some View {
    let levelText: String
    switch level {
    case .basic: levelText = "Basic"
    case .advanced: levelText = "Advanced"
    case .admin: levelText = "Admin"
    case .premium: levelText = "Premium"
    }
    
    return HStack(spacing: 4) {
        Text("Level:")
            .font(.caption2)
            .foregroundColor(.secondary)
        
        Text(levelText)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(colorForAccessLevel(level))
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(colorForAccessLevel(level).opacity(0.1))
    .clipShape(Capsule())
}
// MARK: - Quick Action Card
struct QuickActionCard: View {
    let action: QuickAction
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: action.iconName)
                .font(.title)
                .foregroundColor(.white)
                .scaleEffect(isPressed ? 1.2 : 1.0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(action.color)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: action.color.opacity(0.3), radius: 6, x: 0, y: 3)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
            
            // Handle the action
            handleQuickAction()
        }
    }
    
    private func handleQuickAction() {
        if action.isAction {
            // Handle special actions like refresh
            print("Executing quick action: \(action.title)")
            // This would trigger a refresh or other action
        }
        // Navigation is handled by NavigationLink in parent
    }
}

// MARK: - Getting Started Step Card
struct GettingStartedStepCard: View {
    let step: GettingStartedStep
    @State private var animateIn = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Step number
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Text("\(step.number)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            // Step content
            VStack(alignment: .leading, spacing: 8) {
                Text(step.title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(step.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            // Step icon
            Image(systemName: step.iconName)
                .font(.title2)
                .foregroundColor(.blue)
                .scaleEffect(animateIn ? 1.2 : 1.0)
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .animation(.easeInOut(duration: 0.5).delay(Double(step.number) * 0.1), value: animateIn)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(step.number) * 0.2) {
                animateIn = true
            }
        }
    }
}

// MARK: - Data Models
struct QuickAction {
    let title: String
    let description: String
    let iconName: String
    let destination: String
    let color: Color
    let isAction: Bool
}

struct GettingStartedStep {
    let number: Int
    let title: String
    let description: String
    let iconName: String
}

// MARK: - User Preferences Manager
@MainActor
class AppUserPreferences: ObservableObject {
    @Published var shouldShowWelcomeScreen: Bool = false
    @Published var defaultLandingPage: DefaultLandingPage = .options
    @Published var rememberUserPreference: Bool = true
    
    enum DefaultLandingPage: String, CaseIterable, Identifiable {
        case options = "OptionsView"
        case policies = "PolicyView"
        case computers = "ComputerView"
        case scripts = "ScriptsView"
        case packages = "PackageView"
        
        var id: String { self.rawValue }
        
        var displayName: String {
            switch self {
            case .options: return "Options Menu"
            case .policies: return "Policies"
            case .computers: return "Computers"
            case .scripts: return "Scripts"
            case .packages: return "Packages"
            }
        }
        
        var description: String {
            switch self {
            case .options: return "Show the options menu with all available features"
            case .policies: return "Jump directly to the policies list"
            case .computers: return "Jump directly to the computers list"
            case .scripts: return "Jump directly to the scripts list"
            case .packages: return "Jump directly to the packages list"
            }
        }
    }
    
    // MARK: - UserDefaults Keys
    private enum Keys {
        static let shouldShowWelcomeScreen = "ShouldShowWelcomeScreen"
        static let defaultLandingPage = "DefaultLandingPage"
        static let rememberUserPreference = "RememberUserPreference"
    }
    
    // MARK: - Initialization
    init() {
        loadPreferences()
    }
    
    // MARK: - Preference Management
    func loadPreferences() {
        shouldShowWelcomeScreen = UserDefaults.standard.bool(forKey: Keys.shouldShowWelcomeScreen)
        
        if let landingPageRaw = UserDefaults.standard.string(forKey: Keys.defaultLandingPage),
           let landingPage = DefaultLandingPage(rawValue: landingPageRaw) {
            defaultLandingPage = landingPage
        }
        
        rememberUserPreference = UserDefaults.standard.bool(forKey: Keys.rememberUserPreference)
        
        // Default to showing welcome screen on first launch
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

// Summarize helper moved into this file so we can reference AppFeature without circular imports
func summarizeAppFeatures(_ features: [AppFeature]) -> String {
    var lines: [String] = []
    for f in features {
        lines.append("- \(f.title): \(f.description)")
        if let subs = f.subFeatures, !subs.isEmpty {
            for s in subs {
                lines.append("    • \(s.title)")
            }
        }
    }
    return lines.joined(separator: "\n")
}
