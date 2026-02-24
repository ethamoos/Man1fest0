import SwiftUI

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
                                
                                NavigationLink(destination: GroupsView(server: server)) {
                                    Text("Computer Static Groups")
                                }
                                NavigationLink(destination: GroupsSmartView(server: server)) {
                                    Text("Computer Smart Groups")
                                }
                                
                                DisclosureGroup("Extension Attributes") {
                                    NavigationLink(destination: ComputerExtAttributeView(server: server)) {
                                        Text("Computer Extension Attributes")
                                    }
                                    NavigationLink(destination: ComputerExtAttributeActionView(server: server)) {
                                        Text("Computer Extension Attributes Actions")
                                    }
                                }
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
//                        Group {
//                            Divider()
//                            DisclosureGroup("Preferences") {
//                                NavigationLink(destination: PolicyDelayInlineView()) {
//                                    Text("Policy fetch delay")
//                                }
//                            }
//                        }
                        
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
                            
//                            Group {
//                                Divider()
//
//                                DisclosureGroup("Groups") {
//                                    //  #######################################################################
//                                    //  Static Groups
//                                    //  #######################################################################
//
//                                    NavigationLink(destination: GroupsView(server: server)) {
//                                        Text("Static Groups")
//                                    }
//                                    NavigationLink(destination: GroupsSmartView(server: server)) {
//                                        Text("Smart Groups")
//                                    }
//                                }
//                            }
//
//                            Group {
//                                Divider()
//
//                                DisclosureGroup("Extension Attributes") {
//                                    NavigationLink(destination: ComputerExtAttributeView(server: server)) {
//                                        Text("Computer Extension Attributes")
//                                    }
//                                    NavigationLink(destination: ComputerExtAttributeActionView(server: server)) {
//                                        Text("Computer Extension Attributes Actions")
//                                    }
//                                }
//                            }
//
//                            Divider()
                            
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
                 
                    ToolbarItem(id: "Status") {
                            VStack(alignment: .leading, spacing: 1) {
                            HStack {
                                Text(server)
                                    .foregroundColor(.green)
                                Label((networkController.status), systemImage: networkController.connected ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash" )
                                    .foregroundColor(.green)
                               
                            }
                        }
                    }
                    
                    
                }
                .foregroundColor(.blue)
                 .frame(minWidth: 300)
                
                HStack() {
//                    Text("man1fest0 - Jamf Pro management tool")
//                        .font(.footnote)
//                        .foregroundColor(.secondary)
                    Spacer()
                    Text("App version is \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                //  #######################################################################
                //  END OF SIDEBAR
                //  #######################################################################
                
                //  #######################################################################
                //  PROGRESS
                //  #######################################################################
                
                
            }
            .listStyle(.sidebar)
            .padding()
             .frame(minWidth: 300)
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
    @State private var delayValue: Double = 0.0
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
