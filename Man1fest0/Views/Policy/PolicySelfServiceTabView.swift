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
                
                LazyVGrid(columns: columns, spacing: 30) {
                    Picker(selection: $selectedIcon, label: Text("Icon:")) {
                        //                            Text("").tag("")
                        ForEach(networkController.allIconsDetailed, id: \.self) { icon in
                            HStack {
                                Text(String(describing: icon.name ?? ""))
                                AsyncImage(url: URL(string: icon.url ?? "" )) { image in
                                    image.resizable().clipShape(Circle()).aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    //                        Color.red
                                }
                            }
                            
                            Text(String(describing: icon.name ?? "")).font(.system(size: 12.0)).foregroundColor(.black).tag(icon.name)
                            
                            
                        }
                        
                        //  ################################################################################
                        //  Update Icon Button
                        //  ################################################################################
                    }
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
                    }
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
