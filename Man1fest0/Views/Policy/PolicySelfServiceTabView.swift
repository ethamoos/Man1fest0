//
//  PolicySelfServiceTabView.swift
//  Man1fest0
//
//  Created by Amos Deane on 06/08/2025.
//

//
//  PolicySelfServiceTabView.swift
//  Man1fest0
//
//  Created by Amos Deane on 10/07/2024.
//

import SwiftUI
import AEXML

struct PolicySelfServiceTabView: View {
    
    var server: String
    var resourceType: ResourceType
    
    //  ########################################################################################
    //    EnvironmentObject
    //  ########################################################################################
    
    @EnvironmentObject var networkController: NetBrain
    
    @EnvironmentObject var xmlController: XmlBrain
    
    @EnvironmentObject var progress: Progress
    
    @EnvironmentObject var layout: Layout
    
    @EnvironmentObject var scopingController: ScopingBrain
    
    @State private var selectedResourceType = ResourceType.policyDetail
    
    //  ########################################################################################
    //    Filters
    //  ########################################################################################
    
    @State var computerGroupFilter = ""
    
    @State var computerFilter = ""
    
    @State var iconFilter = ""
    
    //  ########################################################################################
    //    Policy
    //  ########################################################################################
    
    @State var policyName = ""
    
    var policyID: Int
    
    //  ########################################################################################
    //    SELECTIONS
    //  ########################################################################################
    
    //@Binding var computerGroupSelection: Set<ComputerGroup>
    
    @State private var selection: Package? = Package(jamfId: 0, name: "")
    
    @State var selectionComp: Computer = Computer(id: 0, name: "", jamfId: 0)
    
    @State var selectionCompGroup: ComputerGroup = ComputerGroup(id: 0, name: "", isSmart: false)
    
    @State  var selectionDepartment: Department = Department(jamfId: 0, name: "")
    
    @State  var selectionBuilding: Building = Building(id: 0, name: "")
    
    
    @State var selectedIcon: Icon? = nil
    
    @State var selectedIconList: Icon = Icon(id: 0, url: "", name: "")
    
    @State var iconMultiSelection = Set<String>()
    
    @State var selectedIconString = ""
    
    @State var newSelfServiceName = ""
    
    //  ########################################################################################
    //  LDAP
    //  ########################################################################################
    
    @State var ldapUserGroupName = ""
    
    @State var ldapUserGroupId = ""
    
    @State var ldapServerSelection: LDAPServer? = nil
    
    @State var ldapSearchCustomGroupSelection = LDAPCustomGroup(uuid: "", ldapServerID: 0, id: "", name: "", distinguishedName: "")
    
    @State var getDetailedPolicyHasRun = false
    
    @State var ldapSearch = ""
    
    @State var allComputersButton: Bool = true
    
    @State private var showingWarningDelete = false
    
    @State private var showingWarningClearScope = false
    
    @State private var showingWarningLimitScope = false
    
    @State private var showingWarningClearLimit = false

    // Show confirmation before downloading all icons (can take time)
    @State private var showingRefreshIconsWarning = false
    //  ########################################################################################
    
    var body: some View {
        
        ScrollView {
            
            VStack(alignment: .leading) {
                
     
                
                // ##########################################################################################
                //                        Icons
                // ##########################################################################################
                
                Divider()
                
                VStack(alignment: .leading) {
                    
                    Text("Icons").bold()
                    
                    AsyncImage(url: URL(string: networkController.policyDetailed?.self_service?.selfServiceIcon?.uri ?? "")) { image in
                        image.resizable()
                    } placeholder: {
                        Color.red.opacity(0.1)
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(.rect(cornerRadius: 25))
                    
#if os(macOS)
                    List(networkController.allIconsDetailed, id: \.self, selection: $selectedIcon) { icon in
                        HStack {
                            Image(systemName: "photo.circle")
                            Text(icon.name).font(.system(size: 12.0)).foregroundColor(.black)
                            AsyncImage(url: URL(string: icon.url)) { image in
                                image.resizable().frame(width: 15, height: 15)
                            } placeholder: {
                            }
                        }
                        .foregroundColor(.gray)
                        .listRowBackground(selectedIconString == icon.name
                                           ? Color.green.opacity(0.3)
                                           : Color.clear)
                        .tag(icon)
                    }
                    .cornerRadius(8)
                    .frame(minWidth: 300, maxWidth: .infinity, maxHeight: 200, alignment: .leading)
#else
                    
                    List(networkController.allIconsDetailed, id: \.self) { icon in
                        HStack {
                            Image(systemName: "photo.circle")
                            Text(icon.name).font(.system(size: 12.0)).foregroundColor(.black)
                            AsyncImage(url: URL(string: icon.url)) { image in
                                image.resizable().frame(width: 15, height: 15)
                            } placeholder: {
                            }
                        }
                    }
#endif
                    //                                    .background(.gray)
                }
                
                // ##########################################################################################
                //                        Icons - picker
                // ##########################################################################################
                
                
                LazyVGrid(columns: layout.columns, spacing: 10) {
                    
                    HStack {
                        TextField("Filter", text: $iconFilter)
                        Picker(selection: $selectedIcon, label: Text("").bold()) {
                                
                            ForEach(networkController.allIconsDetailed.filter({iconFilter == "" ? true :   $0.name.lowercased().contains(iconFilter.lowercased())}), id: \.self) { icon in
                                HStack {
                                    Text(String(describing: icon.name))
                                    AsyncImage(url: URL(string: icon.url))  { image in
                                        image.resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(maxWidth: 30, maxHeight: 30)

                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .frame(width: 30, height: 30)
                                    .background(Color.gray)
                                    .clipShape(Circle())
                                }
                                // Tag must match the Picker selection type (Icon?) so provide the optional Icon as tag
                                .tag(icon as Icon?)
                            }
                        }
                    }
//  ################################################################################
//                        //  Update Icon Button
//                        //  ################################################################################
//                    }
                    HStack {
                        Button(action: {
                            
                            progress.showProgress()
                            progress.waitForABit()
                            
                            xmlController.updateIcon(server: server,authToken: networkController.authToken, policyID: String(describing: policyID), iconFilename: String(describing: selectedIcon?.name ?? ""), iconID: String(describing: selectedIcon?.id ?? 0), iconURI: String(describing: selectedIcon?.url ?? ""))
                        }) {
                            Text("Update Icon")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
//                    }
//                    HStack {
                        Button(action: {
                            // Show confirmation before kicking off a potentially long download
                            showingRefreshIconsWarning = true
                        }) {
                            Text("Refresh Icons")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .alert("Warning", isPresented: $showingRefreshIconsWarning) {
                            Button("Proceed") {
                                progress.showProgress()
                                progress.waitForABit()
                                networkController.getAllIconsDetailed(server: server, authToken: networkController.authToken, loopTotal: 20000)
                            }
                            Button("Cancel", role: .cancel) { }
                        } message: {
                            Text("please note downloading all the icons can take some time")
                        }
                     }
                }
                HStack {
                    Button(action: {
                        
                        progress.showProgress()
                        progress.waitForABit()
                        
                        networkController.enableSelfService(server: server, authToken: networkController.authToken, resourceType: selectedResourceType, itemID: policyID, selfServiceToggle: true)
                    }) {
                        Text("Enable Self-Service")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
//                    HStack {
                        TextField(networkController.currentDetailedPolicy?.policy.general?.name ?? policyName, text: $newSelfServiceName)
                            .textSelection(.enabled)
                        Button(action: {
                            
                            progress.showProgress()
                            progress.waitForABit()
                            networkController.updateSSName(server: server,authToken: networkController.authToken, resourceType: ResourceType.policyDetail, providedName: newSelfServiceName, policyID: String(describing: policyID))
                            
                            networkController.separationLine()
                            print("Name Self-Service to:\(newSelfServiceName)")
                        }) {
                            Text("Set Name")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                }
            }
            .frame(minHeight: 1)
            .padding()
            
            
            
        }
        .onAppear{
            if networkController.allIconsDetailed.count <= 1 {
                print("getAllIconsDetailed is:\(networkController.allIconsDetailed.count) - running")
                Task {
                    networkController.getAllIconsDetailed(server: server, authToken: networkController.authToken, loopTotal: 2000)
                }
            } else {
                print("getAllIconsDetailed has already run")
                print("getAllIconsDetailed is:\(networkController.allIconsDetailed.count) - running")
            }
        }
//        .onChange(of: networkController.allIconsDetailed) { newIcons in
//            // If no icon is currently selected, pick the first available icon so Picker has a valid selection
//            if selectedIcon == nil, let first = newIcons.first {
//                selectedIcon = first
//            }
//        }
//        .onChange(of: selectedIcon) { newSelection in
//            // Keep the string in sync for row highlighting and other uses
//            selectedIconString = newSelection?.name ?? ""
//        }
    }
}
    
    
    
    
    
    
    
    //#Preview {
    //    PolicyScopeTabView()
    //}
