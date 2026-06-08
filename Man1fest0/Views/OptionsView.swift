import SwiftUI
#if os(macOS)
import AppKit
#endif

@available(macOS 13.3, *)
@available(iOS 17.0, *)
struct OptionsView: View {
    
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var prestageController: PrestageBrain
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var securitySettings: SecuritySettingsManager
    @EnvironmentObject var inactivityMonitor: InactivityMonitor
    
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
 
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("man1fest0")
                                .font(.system(size: 20, weight: .black, design: .default))
                                .foregroundColor(.primary)
                            Text("manage Jamf policies and more")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image("Man1fest0Icon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(radius: 2)
                    }
                    .padding(.vertical, 6)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 10) {
                    
            //  #######################################################################
            //  OPTIONS
            //  #######################################################################
                    
                    List {

                        Group {
                            
                            DisclosureGroup("Computers") {
                                NavigationLink(destination: ComputersView( server: server )) {
                                    Text("Computers")
                                }
                                NavigationLink(destination: ComputerBasicActionView( server: server )) {
                                    Text("Computers Basic Actions")
                                }
#if os(macOS)
                                NavigationLink(destination: ComputersBasicTableView(server: server)) {
                                    Text("Computer Actions Table")
                                }
                                
                                NavigationLink(destination: ComputerSearchView(server: server)) {
                                    Text("Computer Search View")
                                }
#endif
                                
                                DisclosureGroup("Groups") {
                                    NavigationLink(destination: GroupsView(server: server)) {
                                        Text("Computer Static Groups")
                                    }
                                    NavigationLink(destination: GroupsSmartView(server: server)) {
                                        Text("Computer Smart Groups")
                                    }
                                }
                                
                                DisclosureGroup("Extension Attributes") {
                                    NavigationLink(destination: ComputerExtAttributeView(server: server)) {
                                        Text("Computer Extension Attributes")
                                    }
                                    NavigationLink(destination: ComputerExtAttributeActionView(server: server)) {
                                        Text("Computer Extension Attributes Actions")
                                    }
                                }
                                
                                DisclosureGroup("Advanced Searches") {
                                    NavigationLink(destination: ComputerSearchesView(server: server)) {
                                        Text("Computer Advanced Searches")
                                    }
                                }
                            }
#if os(macOS)
                            Divider()

                            DisclosureGroup("Packages") {
                                NavigationLink(destination: PackagesUnsortedView(server: server, selectedResourceType: ResourceType.package )) {
                                    Text("Packages")
                                }
                                NavigationLink(destination: PackagesView(server: server, selectedResourceType: ResourceType.package )) {
                                    Text("Packages (sorted - beta)")
                                }
                                NavigationLink(destination: PackagesActionView(selectedResourceType: ResourceType.package, server: server )) {
                                    Text("Package Actions")
                                }
                                NavigationLink(destination: PackageUsageView(server: server)) {
                                    Text("Package Usage")
                                }
                            }
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
                                NavigationLink(destination: ScriptDetailTableView(server: server)) {
                                    Text("Script Actions")
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
                                NavigationLink(destination: ConfigProfileViewMacOS(server: server )) {
                                    Text("Config Profiles")
                                }
                                NavigationLink(destination: ConfigProfileViewMacOSTable(server: server )) {
                                    Text("Config Profiles Action")
                                }
                            }
                        }
                        
                        Divider()
                        
                        Group {
                            DisclosureGroup("Structures") {
                                NavigationLink(destination: CategoriesView(selectedResourceType: ResourceType.category, server: server )) {
                                    Text("Categories")
                                }
                                NavigationLink(destination: BuildingsView( server: server)) {
                                    Text("Buildings")
                                }
                                NavigationLink(destination: DepartmentsView(selectedResourceType: ResourceType.department, server: server )) {
                                    Text("Departments")
                                }
                                NavigationLink(destination: IconsView( server: server )) {
                                    Text("Icons")
                                }
                                DisclosureGroup("Users") {
                                    NavigationLink(destination: UsersView(server: server )) {
                                        Text("Users")
                                    }
                                    NavigationLink(destination: UsersActionView(server: server )) {
                                        Text("User Actions")
                                    }
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
                            NavigationLink(destination: ReportsView()) {
                                Text("Reports")
                            }
#endif
                            Divider()
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(id: "Error") {
                        if networkController.hasError {
                            HStack {
                                Image(systemName:  "exclamationmark.triangle.fill")
                                    .foregroundStyle(.secondary, .yellow)
                                    .imageScale(.large)
                            }
                        }
                    }

                    ToolbarItem(id: "Connect") {
                        Button(action: { networkController.needsCredentials = true }) {
                            HStack { Text("Connect") }
                        }
                        .foregroundColor(.blue)
                    }

                    ToolbarItem(id: "Refresh") {
                        Button(action: {
                            progress.showProgress()
                            progress.waitForABit()
                            Task { try? await networkController.getToken(server: server, username: username, password: networkController.password) }
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .foregroundColor(.blue)
                    }

                    ToolbarItem(id: "Address") {
                        Text(server).foregroundColor(.green)
                    }

                    ToolbarItem(id: "Status") {
                        Label((networkController.status), systemImage: networkController.connected ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                            .foregroundColor(.green)
                    }

                    ToolbarItem(id: "ResetWindow") {
                        Button(action: { resetMainWindowToScreen() }) {
                            HStack { Image(systemName: "arrow.counterclockwise"); Text("Reset Window") }
                        }
                    }
                }
            }
            .foregroundColor(.blue)
            .frame(minWidth: 300)
            
            HStack() {
                Spacer()
                Text("App version is \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .listStyle(.sidebar)
        .padding()
        .frame(minWidth: 300)
    }

    // Reset helper - clears saved frame and recenters main window to fit screen
    private func resetMainWindowToScreen() {
        #if os(macOS)
        DispatchQueue.main.async {
            UserDefaults.standard.removeObject(forKey: "MainWindowFrame")
            guard let window = NSApp.keyWindow ?? NSApp.windows.first else { return }
            let screens = NSScreen.screens
            let targetVisible = window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? (screens.first?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800))
            let minWidth: CGFloat = 700
            let minHeight: CGFloat = 420
            let width = max(minWidth, floor(targetVisible.width * 0.85))
            let height = max(minHeight, floor(targetVisible.height * 0.75))
            let originX = targetVisible.origin.x + (targetVisible.width - width) / 2.0
            let originY = targetVisible.origin.y + (targetVisible.height - height) / 2.0
            let rect = NSRect(x: originX, y: originY, width: width, height: height)
            window.setFrame(rect, display: true, animate: true)
        }
        #endif
    }
}

