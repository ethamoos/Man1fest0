import SwiftUI
import Foundation

// MARK: - Simple Security Settings
struct SimpleSecuritySettingsView: View {
    @EnvironmentObject var networkController: NetBrain
    
    @State private var inactivityTimeoutMinutes: Int = 5
    @State private var requirePasswordOnWake: Bool = true
    @State private var useKeychain: Bool = false
    
    private let timeoutOptions = [0, 1, 5, 15, 30, 60, 120]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Inactivity Lock") {
                    Picker("Lock after", selection: $inactivityTimeoutMinutes) {
                        ForEach(timeoutOptions, id: \.self) { minutes in
                            Text(timeoutDisplayName(minutes: minutes)).tag(minutes)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    if inactivityTimeoutMinutes > 0 {
                        Text("App will lock after \(timeoutDisplayName(minutes: inactivityTimeoutMinutes)) of inactivity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Security Options") {
                    Toggle("Require password to unlock", isOn: $requirePasswordOnWake)
                    Toggle("Save password in keychain", isOn: $useKeychain)
                }
                
                Section("Status") {
                    HStack {
                        Text("Current Setting")
                        Spacer()
                        Text(timeoutDisplayName(minutes: inactivityTimeoutMinutes))
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Security Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveSettings()
                    }
                }
            }
            #endif
        }
        .onAppear {
            loadSettings()
        }
    }
    
    private func timeoutDisplayName(minutes: Int) -> String {
        switch minutes {
        case 0: return "Never"
        case 1: return "1 Minute"
        case 5: return "5 Minutes"
        case 15: return "15 Minutes"
        case 30: return "30 Minutes"
        case 60: return "1 Hour"
        case 120: return "2 Hours"
        default: return "\(minutes) Minutes"
        }
    }
    
    private func loadSettings() {
        inactivityTimeoutMinutes = UserDefaults.standard.integer(forKey: "SecurityInactivityTimeout")
        if inactivityTimeoutMinutes == 0 && !UserDefaults.standard.bool(forKey: "SecurityInactivityTimeoutSet") {
            inactivityTimeoutMinutes = 5 // Default to 5 minutes
        }
        requirePasswordOnWake = UserDefaults.standard.bool(forKey: "SecurityRequirePasswordOnWake")
        useKeychain = UserDefaults.standard.bool(forKey: "SecurityUseKeychain")
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(inactivityTimeoutMinutes, forKey: "SecurityInactivityTimeout")
        UserDefaults.standard.set(true, forKey: "SecurityInactivityTimeoutSet")
        UserDefaults.standard.set(requirePasswordOnWake, forKey: "SecurityRequirePasswordOnWake")
        UserDefaults.standard.set(useKeychain, forKey: "SecurityUseKeychain")
    }
}

@available(macOS 13.3, *)
@available(iOS 17.0, *)
struct OptionsView: View {
    
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var prestageController: PrestageBrain
    @EnvironmentObject var progress: Progress
    
    @State var prestageID = ""
    @State var serial = ""
    @State var authToken = ""
    
    //  #######################################################################
    //  Login
    //  #######################################################################
    
    var server: String { UserDefaults.standard.string(forKey: "server") ?? "" }
    var username: String { UserDefaults.standard.string(forKey: "username") ?? "" }
    var auth: JamfAuthToken?
    
    //  #######################################################################
    //  BODY
    //  #######################################################################
    
    @available(macOS 13.3, *)
    var body: some View {
        
        VStack() {
            
            VStack(alignment: .leading, spacing: 10) {
                
                Divider()
                
                VStack(alignment: .leading, spacing: 10) {
 
                    HStack {
                        Text("man1fest0")
                            .fontWeight(.black)
                            .font(.title)
                            .font(.headline)
                            .padding()
       
                        VStack {
                            
                        Image("Man1fest0Icon")
//                            .frame(width: 80, height: 80, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
//                            .clipped()
//                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .frame(width: 60, height: 60, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding()
                    }
                    
                    Divider()
                    
                    Text("manage Jamf policies and more ")
                        .fontWeight(.black)
                        .padding()
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 10) {
                    
            //  #######################################################################
            //  OPTIONS
            //  #######################################################################
                    
                    List {

                        Group {
                            
//    #################################################################################
//    Downloads
//    #################################################################################
//                            NavigationLink(destination: DownloadsView(authToken: authToken, server: server )) {
//                                Text("Downloads")
//                            }
                            
                            DisclosureGroup("Computers") {
                                
                                NavigationLink(destination: ComputerActionView(selectedResourceType: ResourceType.computerDetailed, server: server )) {
                                    Text("Computers")
                                }
                                
                                NavigationLink(destination: ComputersBasicView( server: server )) {
                                                                 Text("Computers Basic Actions")
                                                             }
#if os(macOS)

                                NavigationLink(destination: ComputersBasicTableView(server: server)) {
                                    Text("Computer Actions")
                                }
#endif
                            }
                          
#if os(macOS)

                            Divider()

                            DisclosureGroup("Packages") {
                                
                                NavigationLink(destination: PackagesView(server: server, selectedResourceType: ResourceType.package )) {
                                    Text("Packages")
                                }

                                NavigationLink(destination: PackagesActionView(selectedResourceType: ResourceType.package, server: server )) {
                                    Text("Package Actions")
                                }
                                NavigationLink(destination: PackageUsageView(server: server)) {
                                    Text("Package Usage")
                                }
                            }
                            
//                            Divider()
#endif
                            
                            
                        }
                        
                        Group {
                            
                            Divider()
                            
                            DisclosureGroup("Policies") {
                                
                                NavigationLink(destination: PolicyView(server: server, selectedResourceType: ResourceType.policy)) {
                                    Text("Policies")
                                }
#if os(macOS)
                                NavigationLink(destination: PoliciesActionView(server: server, selectedResourceType: ResourceType.policy )) {
                                    Text("Policy Actions")
                                }
                                
                                NavigationLink(destination: PolicyActionsDetailTableView(server: server)) {
                                    Text("Policy Actions - Detailed")
                                }
                                
                                NavigationLink(destination: PolicySearchView(server: server)) {
                                    Text("Policy Search View")
                                }
//                                NavigationLink(destination: NotesView()) {
//                                    Text("Notes View")
//                                }
#endif
                            }
                        }
                        
                        Divider()
                        
                        Group {
                            
                            DisclosureGroup("Scripts") {
                                
                                NavigationLink(destination: ScriptsView( server: server)) {
                                    Text("Scripts")
                                }
#if os(macOS)
                                NavigationLink(destination: ScriptUsageView(server: server)) {
                                    Text("Script Usage")
                                }
                                NavigationLink(destination: ScriptsActionView(server: server)) {
                                    Text("Script Actions")
                                }
                                NavigationLink(destination: ScriptDetailTableView(server: server)) {
                                    Text("Script Detailed List")
                                }
#endif
                            }
                        }
                      
                            
#if os(macOS)
                        Group {
                            Divider()
                            
                            DisclosureGroup("Create") {
                                
                                NavigationLink(destination: CreateView(server: server)) {
                                    Text("Create Items")
                                }
                                NavigationLink(destination: CreatePolicyView(selectedResourceType: ResourceType.package, server: server )) {
                                    Text("Create Policy")
                                }
                                NavigationLink(destination: CreateScriptView(server: server)) {
                                    Text("Create Script")
                                }
                                
                                NavigationLink(destination: BreakoutGameView(server: server)) {
                                    Text("Downtime")
                                }
                            }
                        }
#endif
                        
                        Group {

                            Divider()

                            DisclosureGroup("Profiles") {
                                
                                //  ###########################################################################
                                //    Config Profiles
                                //  ###########################################################################
                                NavigationLink(destination: ConfigProfileViewMacOS(server: server )) {
                                    Text("Config Profiles")
                                }
                                NavigationLink(destination: ConfigProfileViewMacOSTable(server: server )) {
                                    Text("Config Profiles Action")
                                }
                            }
                        }
                        
                        // Preferences
                        Group {
                            Divider()
                            DisclosureGroup("Preferences") {
                                NavigationLink(destination: PolicyDelayInlineView()) {
                                    Text("Policy fetch delay")
                                }
                                
                                NavigationLink(destination: SimpleSecuritySettingsView()) {
                                    HStack {
                                        Image(systemName: "lock.shield")
                                        Text("Security Settings")
                                    }
                                }
                            }
                        }
                        
//                            NavigationLink(destination: PrestagesView(server: server, allPrestages: prestageController.allPrestages)) {
//                                Text("Prestages")
//                            }
                        Divider()

                        
                        Group {
                            DisclosureGroup("Structures") {
                   
                    //    ###########################################################################
                    //    Categories
                    //    ###########################################################################
                                NavigationLink(destination: CategoriesView(selectedResourceType: ResourceType.category, server: server )) {
                                    Text("Categories")
                                }
                                //  ###########################################################################
                                //  Buildings
                                //  ###########################################################################
                                NavigationLink(destination: BuildingsView( server: server)) {
                                    Text("Buildings")
                                }
                                //  ###########################################################################
                                //  Departments
                                //  ###########################################################################
                                NavigationLink(destination: DepartmentsView(selectedResourceType: ResourceType.department, server: server )) {
                                    Text("Departments")
                                }
                                //  ###########################################################################
                                //  Icons
                                //  ###########################################################################
                                NavigationLink(destination: IconsView( server: server )) {
                                    Text("Icons")
                                }
                                
                                //  ###########################################################################
                                //  Users
                                //  ###########################################################################
                                
                                NavigationLink(destination: UsersView(server: server )) {
                                    Text("Users")
                                }
                            }
                        }
                        
                        Group {
                            
                            Divider()

                            DisclosureGroup("Prestage Management") {
                                
                                NavigationLink(destination: PrestagesView(server: server, allPrestages: prestageController.allPrestages)) {
                                    Text("Prestages")
                                }
                                
                                NavigationLink(destination: PrestagesAssignedView(server: server)) {
                                    Text("Devices Assigned")
                                }
                                
                                NavigationLink(destination: PrestagesEditView(initialPrestageID: "", targetPrestageID: "", serial: "", server: server, showProgressScreen: false )) {
                                    Text("Edit Device Assignment")
                                }
                            }
#if os(macOS)
                            
                            Group {
                                Divider()
                                
                                DisclosureGroup("Groups") {
                                    //  #######################################################################
                                    //  Static Groups
                                    //  #######################################################################
                                    
                                    NavigationLink(destination: GroupsView(server: server)) {
                                        Text("Static Groups")
                                    }
                                    NavigationLink(destination: GroupsSmartView(server: server)) {
                                        Text("Smart Groups")
                                    }
                                }
                            }
                            
                            Group {
                                Divider()

                                DisclosureGroup("Extension Attributes") {
                                    NavigationLink(destination: ComputerExtAttributeView(server: server)) {
                                        Text("Computer Extension Attributes")
                                    }
                                    NavigationLink(destination: ComputerExtAttributeActionView(server: server)) {
                                        Text("Computer Extension Attributes Actions")
                                    }
                                }
                            }
                                           
                            Divider()
                            
                            NavigationLink(destination: ReportsView()) {
                                Text("Reports")
                            }
//                            NavigationLink(destination: ImportView()) {
//                                Text("Import/Export")
//                            }
//                                                        Divider()
//
//                            NavigationLink(destination: ReportsExport()) {
//                                Text("Reports Export")
//                            }
//
//                            NavigationLink(destination: ReportsExportCSV()) {
//                                Text("Reports Export CSV")
//                            }
                            
#endif
//
                            Divider()
                            
//#if os(macOS)
//  NavigationLink(destination: BackupsView(server: server, username: username, password: password )) {
//                            Text("Backups")
//                           }
//#endif
                        }
                    }
                }
                .toolbar(id: "Main") {
                    
                    ToolbarItem(id: "Error") {
                        if networkController.hasError {
                            HStack {
                                Image(systemName:  "exclamationmark.triangle.fill")
                                    .foregroundStyle(.secondary, .yellow)
                                    .imageScale(.large)
                            }
                        }
                    }
                    
                    // #################################################################################
                    //  CONNECT
                    // #################################################################################
                    
                    ToolbarItem(id: "Connect") {
                        
                        Button(action: {
                            
                            networkController.needsCredentials = true
                        }) {
                            HStack {
//                                Label("Connect", systemImage: networkController.connected ? "bolt.horizontal.fill" : "bolt.horizontal")
                                Text("Connect")
                            }
                            .foregroundColor(.blue)
                        }
                        
                      
                    }
                 
                    ToolbarItem(id: "Status") {
                            VStack(alignment: .leading, spacing: 1) {
                            HStack {
                                Label((networkController.status), systemImage: networkController.connected ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash" )
                                    .foregroundColor(.green)
                                Text(server)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    ToolbarItem(id: "Refresh") {
                        Button(action: {
                            
                            progress.showProgress()
                            progress.waitForABit()
                            
                            Task {
                                try? await networkController.getToken(server: server, username: username, password: networkController.password)
                            }
                        }) {
                            HStack {
//                                Text("Refresh")
                                Image(systemName: "arrow.clockwise")

                            }
                            .foregroundColor(.blue)
                        }
//                    }
                    }
                }
                .foregroundColor(.blue)
                .frame(minWidth: 220)

                //  #######################################################################
                //  END OF SIDEBAR
                //  #######################################################################
                
                //  #######################################################################
                //  PROGRESS
                //  #######################################################################
                
                
            }
            .listStyle(.sidebar)
            .padding()
            .frame(minWidth: 220)
        }
    }
}


//  #######################################################################
//  CONNECTION - END
//  #######################################################################


//struct OptionsView_Previews: PreviewProvider {
//    static var previews: some View {
//        OptionsView()
//    }
//}

// Lightweight inline preferences view to use from OptionsView (avoid external target membership issues)
fileprivate struct PolicyDelayInlineView: View {
    @EnvironmentObject var networkController: NetBrain
    @State private var delayValue: Double = 3.0
    @State private var showSavedToast = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Policy fetch delay (seconds)")
                .font(.headline)

            HStack {
                Slider(value: $delayValue, in: 0...60, step: 0.1)
                Stepper(value: $delayValue, in: 0...600, step: 1) {
                    Text("\(Int(delayValue)) s")
                        .frame(minWidth: 60)
                }
            }

            HStack(spacing: 12) {
                Button(action: {
                    networkController.setPolicyRequestDelay(delayValue)
                    showSavedToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showSavedToast = false
                    }
                }) {
                    Text("Save")
                }

                Button(action: {
                    delayValue = networkController.getPolicyRequestDelay()
                }) {
                    Text("Reset to current")
                }

                Spacer()

                Text(networkController.policyDelayStatus)
                    .foregroundColor(.secondary)
            }

            if showSavedToast {
                Text("Saved")
                    .foregroundColor(.green)
            }

            Divider()

            Text("Human readable: \(networkController.humanReadableDuration(delayValue))")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
        .onAppear {
            delayValue = networkController.getPolicyRequestDelay()
        }
        .frame(minWidth: 400, minHeight: 160)
    }
}
