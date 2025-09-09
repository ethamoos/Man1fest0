//
//  PolicyScopeTabView.swift
//  Man1fest0
//
//  Created by Amos Deane on 10/07/2024.
//

import SwiftUI
import AEXML

struct PolicyScopeTabView: View {
    
    var server: String
    var resourceType: ResourceType
    
    //    ########################################################################################
    //    EnvironmentObject
    //    ########################################################################################
    
    @EnvironmentObject var networkController: NetBrain
    
    @EnvironmentObject var xmlController: XmlBrain
    
    @EnvironmentObject var progress: Progress
    
    @EnvironmentObject var layout: Layout
    
    @EnvironmentObject var scopingController: ScopingBrain
    
    @State private var selectedResourceType = ResourceType.policyDetail
    
    //    ########################################################################################
    //    Filters
    //    ########################################################################################
    
    @State var computerGroupFilter = ""
    
    @State var computerFilter = ""
    
    //    ########################################################################################
    //    Policy
    //    ########################################################################################
    
    @State var policyName = ""
    
    var policyID: Int
    
    //    ########################################################################################
    //    SELECTIONS
    //    ########################################################################################
    
    @Binding var computerGroupSelection: Set<ComputerGroup>
    
    @State private var selection: Package? = Package(jamfId: 0, name: "")
    
    @State var selectionComp: Computer = Computer(id: 0, name: "", jamfId: 0)
    
    @State var selectionCompGroup: ComputerGroup = ComputerGroup(id: 0, name: "", isSmart: false)
    
    @State  var selectionDepartment: Department = Department(jamfId: 0, name: "")
    
    @State  var selectionBuilding: Building = Building(id: 0, name: "")
    
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
    
    @State private var showingWarningAllUsers = false
    
    @State private var showingWarningAllComputers = false

    //  ########################################################################################
    
    var body: some View {
        
        ScrollView {
            
            VStack(alignment: .leading) {
                
                //  ################################################################################
                //  SCOPING
                //  ################################################################################
                
                //  ################################################################################
                //  SHOW CURRENT SCOPING
                //  ################################################################################
                
                Group {
                    VStack(alignment: .leading) {
                        //                        VStack(alignment:.leading){
//                        Text("Scoping").font(.system(size: 22, weight: .bold, design: .default))
//                        
//                        Divider()
//                        Text("Scoping").font(.system(size: 14, weight: .bold, design: .default))
//                        
                        //  ################################################################################
                        //  Show All Computers scoping
                        //  ################################################################################
                        
//                        Divider()
                        if networkController.currentDetailedPolicy?.policy.scope?.allComputers == true {
                            Text("Scoped To All Computers").font(.subheadline)
                        } else {
                            Text("All Computers is not enabled").font(.subheadline)
                        }
                        
                        //  ################################################################################
                        //  Show computer scoping
                        //  ################################################################################
                        
                        Divider()
                        if networkController.currentDetailedPolicy?.policy.scope?.computers?.count == 0 {
                            Text("Not Scoped to any individual Computers").font(.subheadline)
                        } else {
                            VStack(alignment:.leading){
                                Text("Computers: ").font(.headline)
                                ForEach(networkController.currentDetailedPolicy?.policy.scope?.computers ?? []) {computer in
                                    Text(String(computer.name)).font(.subheadline)}}
                            .padding()
                        }
                        
                        //  ################################################################################
                        //  Show Department scoping
                        //  ################################################################################
                        
                        Divider()
                        if networkController.currentDetailedPolicy?.policy.scope?.departments?.count == 0 {
                            Text("Not Scoped to any Departments").font(.subheadline)
                        } else {
                            VStack(alignment:.leading){
                                Text("Departments: ").font(.headline)
                                ForEach(networkController.currentDetailedPolicy?.policy.scope?.departments ?? []) {department in
                                    Text(String(department.name)).font(.subheadline)}}
                            .padding()
                        }
                        
                        //  ################################################################################
                        //  Show Group scoping
                        //  ################################################################################
                        
                        Divider()
                        if networkController.currentDetailedPolicy?.policy.scope?.computerGroups?.count == 0 {
                            Text("Not Scoped to any Groups").font(.subheadline)
                        } else {
                            VStack(alignment:.leading){
                                Text("Computer Groups: ").font(.headline)
                                ForEach(networkController.currentDetailedPolicy?.policy.scope?.computerGroups ?? []) {computerGroups in
                                    Text(String(computerGroups.name ?? "")).font(.subheadline)}}
                            .padding()
                        }
                        
                        //  ################################################################################
                        //  Show Building scoping
                        //  ################################################################################
                        
                        Divider()
                        if networkController.currentDetailedPolicy?.policy.scope?.buildings?.count == 0 {
                            Text("Not Scoped to any Buildings").font(.subheadline)
                        } else {
                            VStack(alignment:.leading){
                                Text("Buildings: ").font(.headline)
                                ForEach(networkController.currentDetailedPolicy?.policy.scope?.buildings ?? []) {building in
                                    Text(String(building.name)).font(.subheadline)}}
                            .padding()
                        }
                        
                        
                        
                        
                        //  ################################################################################
                        //              Clear Scope
                        //  ################################################################################
                        
                        Divider()
                        
                        HStack {
                            
                            Button(action: {
                                showingWarningClearScope = true
                                progress.showProgress()
                                progress.waitForABit()
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "eraser")
                                    Text("Clear Scope")
                                }
                                .alert(isPresented: $showingWarningClearScope) {
                                    Alert(
                                        title: Text("Caution!"),
                                        message: Text("This action will clear the policy scoping.\n You will need to rescope in order to deploy"),
                                        primaryButton: .destructive(Text("I understand!")) {
                                            // Code to execute when "Yes" is tapped
                                            networkController.clearScope(server: server, resourceType: ResourceType.policyDetail, policyID: String(describing: policyID), authToken: networkController.authToken)
                                            print("Yes tapped")
                                        },
                                        secondaryButton: .cancel()
                                    )
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                        
                            
                            
                            //  ################################################################################
                            //              scopeAllUsers
                            //  ################################################################################
                            
                            
                            Button(action: {
                                showingWarningAllUsers = true
                                progress.showProgress()
                                progress.waitForABit()
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "eraser")
                                    Text("Enable All Users")
                                }
                                .alert(isPresented: $showingWarningAllUsers) {
                                    Alert(
                                        title: Text("Caution!"),
                                        message: Text("This action will enable the policy scoping for all users.\n This might cause the policy to run immediately to many devices"),
                                        primaryButton: .destructive(Text("I understand!")) {
                                            // Code to execute when "Yes" is tapped
                                            networkController.scopeAllUsers(server: server, authToken: networkController.authToken, policyID: String(describing: policyID))
                                            print("Yes tapped")
                                        },
                                        secondaryButton: .cancel()
                                    )
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            
                            
                            //  ################################################################################
                            //              scopeAllComputers
                            //  ################################################################################
                            
                            
                            Button(action: {
                                showingWarningAllComputers = true
                                progress.showProgress()
                                progress.waitForABit()
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "eraser")
                                    Text("Enable All Computers")
                                }
                                .alert(isPresented: $showingWarningAllComputers) {
                                    Alert(
                                        title: Text("Caution!"),
                                        message: Text("This action will enable the policy scoping for all computers.\n This might cause the policy to run immediately to many devices"),
                                        primaryButton: .destructive(Text("I understand!")) {
                                            // Code to execute when "Yes" is tapped
                                            networkController.scopeAllComputers(server: server, authToken: networkController.authToken, policyID: String(describing: policyID))
                                            print("Yes tapped")
                                        },
                                        secondaryButton: .cancel()
                                    )
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                        }
                    }
                }
                        //
                        //  ################################################################################
                        //  EDIT SCOPING - Computer
                        //  ################################################################################
                        
                Group {
                
//
                            
                    VStack(alignment:.leading){
                                
                           
                            Divider()

                            DisclosureGroup("Edit Scoping") {
                                
                                Group {
                                    VStack(alignment: .leading) {
                                        LazyVGrid(columns: layout.columns, spacing: 10) {
                                            HStack(spacing: 10) {
                                                Toggle("", isOn: $allComputersButton)
                                                    .toggleStyle(SwitchToggleStyle(tint: .red))
                                                    .onChange(of: allComputersButton) { value in
                                                        print("allComputersButton changed - value is now:\(value) for policy:\(policyID)")
                                                        
                                                        if value == true {
                                                            xmlController.enableAllComputersToScope(xmlContent: xmlController.currentPolicyAsXML, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policyId: String(describing: policyID))
                                                        } else {
                                                            xmlController.disableAllComputersToScope(xmlContent: xmlController.currentPolicyAsXML, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policyId: String(describing: policyID))
                                                        }
                                                    }
#if os(macOS)
                                                if networkController.currentDetailedPolicy?.policy.scope?.allComputers == true {
                                                    Text("All Computers")
                                                } else {
                                                    Text("Specific Computers")
                                                }
#endif
                                            }
                                        }
                                    }
                                    
                                    if networkController.computers.count > 0 {
                                        
                                        LazyVGrid(columns: layout.threeColumns, spacing: 20) {
                                            Picker(selection: $selectionComp, label: Text("Computer:").bold()) {
                                                ForEach(networkController.computers, id: \.self) { comp in
                                                    Text(String(describing: comp.name)).tag("")
                                                        .tag(comp as Computer?)
                                                }
                                            }
                                            
                                            .onAppear {selectionComp = networkController.computers[0]}
                                            
                                            Button(action: {
                                                
                                                progress.showProgress()
                                                progress.waitForABit()
                                                
                                                networkController.separationLine()
                                                print("addComputerToPolicyScope policy:\(String(describing: policyID))")
                                                
                                                xmlController.addComputerToPolicyScope( xmlContent: xmlController.currentPolicyAsXML, computerName: selectionComp.name, authToken: networkController.authToken, computerId: String(describing: selectionComp.id), resourceType: selectedResourceType, server: server, policyId: String(describing: policyID))
                                            }) {
                                                HStack(spacing: 10) {
                                                    Image(systemName: "plus.square.fill.on.square.fill")
                                                    Text("Add Computer")
                                                }
                                            }
                                        }
                                    }
                                }
                              
                    //  ################################################################################
                    //  Set Scoping - Department
                    //  ################################################################################
                                
                                Group {
                                    
                                    Divider()
                                    
                                    LazyVGrid(columns: layout.threeColumns, spacing: 20) {
                                        
                                        Picker(selection: $selectionDepartment, label: Text("Department:").bold()) {
                                            ForEach(networkController.departments, id: \.self) { department in
                                                Text(String(describing: department.name))
                                                    .tag(department as Department?)
                                                    .tag(selectionDepartment as Department?)
                                            }
                                            .onAppear { selectionDepartment = networkController.departments[0] }
                                        }
                                        
                                        Button(action: {
                                            
                                            progress.showProgress()
                                            progress.waitForABit()
                                            
                                            layout.separationLine()
                                            print("addDepartmentToPolicyScope for policy:\(String(describing: policyID))")
                                            
                                            xmlController.addDepartmentToPolicyScope(xmlContent: xmlController.currentPolicyAsXML, departmentName: selectionDepartment.name, departmentId: String(describing:selectionDepartment.jamfId ?? 0), authToken: networkController.authToken, policyId: String(describing: policyID), resourceType: selectedResourceType, server: server)
                                        }) {
                                            HStack(spacing: 10) {
                                                Image(systemName: "plus.square.fill.on.square.fill")
                                                Text("Add Department")
                                            }
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(.blue)
                                    }
                                }
    
        //  ################################################################################
        //  Set Scoping - Building
        //  ################################################################################
    
                                Group {
                                    
                                    Divider()
                                    LazyVGrid(columns: layout.threeColumns, spacing: 20) {
                                        Picker(selection: $selectionBuilding, label: Text("Building:").bold()) {
                                            Text("").tag("") //basically added empty tag and it solve the case
                                            ForEach(networkController.buildings, id: \.self) { building in
                                                Text(String(describing: building.name)).tag("")
                                            }
                                        }
                                        
                                        Button(action: {
                                            
                                            progress.showProgress()
                                            progress.waitForABit()
                                            
                                            networkController.separationLine()
                                            print("addBuildingToPolicyScope - policy is:\(String(describing: policyID))")
                                            
                                            xmlController.addBuildingToPolicyScope(xmlContent: xmlController.currentPolicyAsXML, buildingName: selectionBuilding.name, buildingId: String(describing: selectionBuilding.id), policyId: String(describing: policyID), resourceType: ResourceType.policyDetail, server: server, authToken: networkController.authToken)
                                            
                                        }) {
                                            HStack(spacing: 10) {
                                                Image(systemName: "plus.square.fill.on.square.fill")
                                                Text("Add Building")
                                            }
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(.blue)
                                    }
                                }
                                
            //  ################################################################################
            //  Set Scoping - Group
            //  ################################################################################
                                
                               
                                
            //  ################################################################################
            //  Group picker
            //  ################################################################################
                                
                                Divider()
                                
                                Group {
                                    LazyVGrid(columns: layout.fourColumnsFlexNarrow, spacing: 5) {
                                        
                                        TextField("Filter", text: $computerGroupFilter)
                                        Picker(selection: $selectionCompGroup, label: Text("Group:").bold()) {
                                            ForEach(networkController.allComputerGroups.filter({computerGroupFilter == "" ? true : $0.name.contains(computerGroupFilter)}) , id: \.self) { group in
                                                Text(String(describing: group.name))
                                                    .tag(group as ComputerGroup?)
                                            }
                                        }
                                        .onAppear { selectionCompGroup = networkController.allComputerGroups[0] }
                                   
                                        Button(action: {
                                            
                                            progress.showProgress()
                                            progress.waitForABit()
                                            
                                            networkController.separationLine()
                                            print("updateScopeCompGroupSingle for policy:\(String(describing: policyID))")
                                            
                                            xmlController.updateScopeCompGroupSingle(groupSelection: selectionCompGroup, authToken: networkController.authToken,resourceType: ResourceType.policyDetail, server: server, policyID: String(describing: policyID), currentPolicyAsXML: xmlController.currentPolicyAsXML, currentPolicyAsAEXML: networkController.aexmlDoc)
                                            
                                        }) {
                                            HStack(spacing: 10) {
                                                Image(systemName: "plus.square.fill.on.square.fill")
                                                Text("Add Group ")
                                            }
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(.blue)
                                    }
                                }
                            }
                   
                    //  ################################################################################
                    //  SET LIMITATIONS
                    //  ################################################################################
                    
                            Group {
                                
                                Divider()
                                    
                                    Text("Limitations").font(.system(size: 14, weight: .bold, design: .default))
                                    
            //  ################################################################################
            //  Show Limitations
            //  ################################################################################
                                    
                                    Divider()
                                    
                                    if networkController.currentDetailedPolicy?.policy.scope?.limitations?.userGroups?.count != 0 {
                                            
                                            VStack(alignment:.leading){
                                                
                                                ForEach(networkController.currentDetailedPolicy?.policy.scope?.limitations?.userGroups ?? []) {limitation in
                                                    Text(String(limitation.name ?? "")).font(.subheadline)}
                                            }
                                            .padding()
                                    } else {
                                        Text("No limitations configured").font(.subheadline)
                                    }
                                }
                                
                //  ################################################################################
                //  LDAP SEARCH RESULTS - Picker 1
                //  ################################################################################
                                
                                DisclosureGroup("Edit Limitations") {
                                    
                                    VStack(alignment: .leading) {
                                        
                                        LazyVGrid(columns: layout.threeColumnsWide, spacing: 20) {
                                            
                                            HStack(spacing: 20) {
                                                
                                                Picker(selection: $ldapSearchCustomGroupSelection, label: Text("Search Results:")) {
                                                    Text("").tag("")
                                                    ForEach(scopingController.allLdapCustomGroupsCombinedArray, id: \.self) { group in
                                                        Text(String(describing: group.name))
                                                            .tag(ldapSearchCustomGroupSelection as LDAPCustomGroup?)
                                                    }
                                                }
                                                
                                                Button(action: {
                                                    showingWarningLimitScope = true
                                                    progress.showProgress()
                                                    progress.waitForABit()
                                                }) {
                                                    Image(systemName: "plus.square.fill.on.square.fill")
                                                    Text("Limit")
                                                }
                                                .buttonStyle(.borderedProminent)
                                                .tint(.red)
                                                .alert(isPresented: $showingWarningLimitScope) {
                                                    Alert(
                                                        title: Text("Caution!"),
                                                        message: Text("This action will limit the policy scoping.\n Some devices may not receive the policy"),
                                                        primaryButton: .destructive(Text("I understand!")) {
                                                            // Code to execute when "Yes" is tapped
                                                            xmlController.getPolicyAsXML(server: server, policyID: policyID, authToken: networkController.authToken)
                                                            
                                                            Task {
                                                                
                                                                await xmlController.updatePolicyScopeLimitationsAuto(groupSelection: ldapSearchCustomGroupSelection, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policyID: String(describing: policyID))
                                                            }
                                                            print("Yes tapped")
                                                        },
                                                        secondaryButton: .cancel()
                                                    )
                                                }
                                                
                                                Button(action: {
                                                    progress.showProgress()
                                                    progress.waitForABit()
                                                    showingWarningClearLimit = true
                                                }) {
                                                    Text("Clear")
                                                }
                                                .buttonStyle(.borderedProminent)
                                                .tint(.red)
                                                .alert(isPresented: $showingWarningClearLimit) {
                                                    Alert(
                                                        title: Text("Caution!"),
                                                        message: Text("This action will clear any current limitations on the policy scoping.\n Some devices previously blocked may now receive the policy"),
                                                        primaryButton: .destructive(Text("I understand!")) {
                                                            // Code to execute when "Yes" is tapped
                                                            xmlController.updatePolicyScopeLimitAutoRemove(authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policyID: String(describing:policyID), currentPolicyAsXML: xmlController.currentPolicyAsXML)
                                                            print("Yes tapped")
                                                        },
                                                        secondaryButton: .cancel()
                                                    )
                                                }
                                            }
                                        }
                                    }
                                    
                        //  ################################################################################
                        //  Select Ldap server
                        //  ################################################################################
                                    
                                    LazyVGrid(columns: layout.threeColumns, spacing: 20) {
                                        Picker(selection: $ldapServerSelection, label: Text("Ldap Servers:")) {
                                            ForEach(scopingController.allLdapServers, id: \.self) { group in
                                                Text(String(describing: group.name))
                                                    .tag(ldapServerSelection as LDAPServer?)
                                            }
                                        }
                                    }
                                        
                                        //  ################################################################################
                                        //  Select Ldap group
                                        //  ################################################################################
                                        
                                        LazyVGrid(columns: layout.threeColumns, spacing: 20) {
                                            
                                            HStack {
                                                Text("Search LDAP")
                                                TextField("", text: $ldapSearch)
                                            }
                                            
                                            Button(action: {
                                                
                                                progress.showProgress()
                                                progress.waitForABit()
                                                
                                                Task {
                                                    try await scopingController.getLdapGroupsSearch(server: server, search: ldapSearch, authToken: networkController.authToken)
                                                }
                                            }) {
                                                HStack(spacing:10) {
                                                    Image(systemName: "magnifyingglass")
                                                    withAnimation {
                                                        Text("Search")
                                                    }
                                                }
                                            }
                                        }
                                }

                //   ################################################################################
                //   Exclusions
                //   ################################################################################

                                    Group {
                                
                                Divider()
                                Text("Exclusions: ").font(.headline)
                                Divider()

                                    if networkController.currentDetailedPolicy?.policy.scope?.exclusions?.computers?.count == 0 {
                                        Text("No Computers Excluded").font(.subheadline).padding(.bottom,10)
                                    } else {
                                        VStack(alignment:.leading){
                                            ForEach(networkController.currentDetailedPolicy?.policy.scope?.exclusions?.computers ?? []) {computer in
                                                Text(computer.name ?? "")}.padding(.bottom,10)
                                        }
                                        .padding()
                                    if networkController.currentDetailedPolicy?.policy.scope?.exclusions?.computerGroups?.count == 0 {
                                        Text("No Computer Groups Excluded").font(.subheadline).padding(.bottom,10)
                                    } else {
                                        ForEach(networkController.currentDetailedPolicy?.policy.scope?.exclusions?.computerGroups ?? []) {computerGroup in
                                            Text(computerGroup.name ?? "")}.padding(.bottom,10)
                                    }
                                    if networkController.currentDetailedPolicy?.policy.scope?.exclusions?.departments?.count == 0 {
                                        Text("No Departments Excluded").font(.subheadline).padding(.bottom,10)
                                    } else {
                                        ForEach(networkController.currentDetailedPolicy?.policy.scope?.exclusions?.departments ?? []) {department in
                                            Text(department.name ?? "")}.padding(.bottom,10)
                                    }
                                    if networkController.currentDetailedPolicy?.policy.scope?.exclusions?.departments?.count == 0 {
                                        Text("No Buildings Excluded").font(.subheadline).padding(.bottom,10)
                                    } else {
                                        ForEach(networkController.currentDetailedPolicy?.policy.scope?.exclusions?.buildings ?? []) {building in
                                            Text(building.name ?? "")}.padding(.bottom,10)
                                    }
                                }
                            }
                        }
                    
                    //  ################################################################################
                    //  END
                    //  ################################################################################
                }
            }
        }
        .frame(minHeight: 1)
        .padding()
    }
}









//#Preview {
//    PolicyScopeTabView()
//}
