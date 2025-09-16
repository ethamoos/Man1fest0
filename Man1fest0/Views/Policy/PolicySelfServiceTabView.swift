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
    
    
    @State var iconMultiSelection = Set<String>()
    
    @State var selectedIconString = ""
    
    @State var selectedIcon: Icon? = Icon(id: 0, url: "", name: "")
    
    @State var selectedIconList: Icon = Icon(id: 0, url: "", name: "")
    
    
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
#if os(macOS)
                    List(networkController.allIconsDetailed, id: \.self, selection: $selectedIcon) { icon in
                        HStack {
                            Image(systemName: "photo.circle")
                            Text(String(describing: icon.name ?? "")).font(.system(size: 12.0)).foregroundColor(.black)
                            AsyncImage(url: URL(string: icon.url ?? "" )) { image in
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
                            Text(String(describing: icon?.name ?? "")).font(.system(size: 12.0)).foregroundColor(.black)
                            AsyncImage(url: URL(string: icon.url ?? "" )) { image in
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
                
//<<<<<<< HEAD:Man1fest0/Views/Policy/PolicySelfServiceTabView.swift
//                LazyVGrid(columns: columns, spacing: 10) {
//                    Picker(selection: $selectedIcon, label: Text("Icon:")) {
//                        ForEach(networkController.allIconsDetailed, id: \.self) { icon in
//                            HStack {
//                                Text(String(describing: icon.name))
//                                AsyncImage(url: URL(string: icon.url )) { image in
////                                    image.resizable()
////                                    image.fixed().frame(width: 20, height: 20)
//                                    image.resizable()
////                                    .aspectRatio(contentMode: .fill)
////                                        .clipShape(Circle()
////                                        .aspectRatio(contentMode: .fill)
//                                } placeholder: {
//=======
           
             
                
                LazyVGrid(columns: layout.columns, spacing: 10) {
                    
                    HStack {
                        TextField("Filter", text: $iconFilter)
                        Picker(selection: $selectedIcon, label: Text("").bold()) {
                                
                            ForEach(networkController.allIconsDetailed.filter({iconFilter == "" ? true :   $0.name.lowercased().contains(iconFilter)}), id: \.self) { icon in
                                HStack {
                                    Text(String(describing: icon.name))
                                        .tag(icon as Icon?)
                                        .tag(selectedIcon as Icon?)
                                    AsyncImage(url: URL(string: icon.url ))  { image in
                                        image.resizable()
                                            .aspectRatio(contentMode: .fit)
                                                                     .frame(maxWidth: 30, maxHeight: 10)

                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .frame(width: 05, height: 05)
                                    .background(Color.gray)
                                    .clipShape(Circle())
//>>>>>>> 2fa67182152e20bfb24168352da4ea78674ed6df:Man1fest0/Views/Policy/PolicyDetailed/PolicySelfServiceTabView.swift
//                                }
//                            }
//                            Text(String(describing: icon.name)).font(.system(size: 12.0)).foregroundColor(.black).tag(icon.name)
//                        }
//                        //  ################################################################################
//                        //  Update Icon Button
//                        //  ################################################################################
//                    }
//<<<<<<< HEAD:Man1fest0/Views/Policy/PolicySelfServiceTabView.swift
//=======
//  ################################################################################
//                        //  Update Icon Button
//                        //  ################################################################################
//                    }
//>>>>>>> 2fa67182152e20bfb24168352da4ea78674ed6df:Man1fest0/Views/Policy/PolicyDetailed/PolicySelfServiceTabView.swift
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
//<<<<<<< HEAD:Man1fest0/Views/Policy/PolicySelfServiceTabView.swift
//=======
//                    }
//                    HStack {
                        Button(action: {
                            progress.showProgress()
                            progress.waitForABit()
                            networkController.getAllIconsDetailed(server: server, authToken: networkController.authToken, loopTotal: 20000)                        }) {
                            Text("Refresh Icons")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
//>>>>>>> 2fa67182152e20bfb24168352da4ea78674ed6df:Man1fest0/Views/Policy/PolicyDetailed/PolicySelfServiceTabView.swift
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
                }
            }
            .frame(minHeight: 1)
            .padding()
            
        }
    }
}
    
    
    
    
    
    
    
    //#Preview {
    //    PolicyScopeTabView()
    //}
