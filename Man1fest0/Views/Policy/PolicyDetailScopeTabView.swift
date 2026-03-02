//
//  PolicyDetailScopeTabView.swift
//  Man1fest0
//
//  Created by Amos Deane on 19/08/2025.
//


//
//  PolicyDetailClearItemsTabView.swift
//  Man1fest0
//
//  Created by Amos Deane on 19/08/2025.
//


import SwiftUI

struct PolicyDetailScopeTabView: View {
    
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var scopingController: ScopingBrain
    @EnvironmentObject var xmlController: XmlBrain
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var layout: Layout
    
    @State private var showingWarningClearScope = false
    @State private var showingWarningClearLimit = false
    
    
    var server: String
    //    private var selectedPolicyjamfIDs: Set<General>
    var selectedPoliciesInt: [Int?]
    
    //    private var policyID: String
    
    //  ########################################################################################
    //  LDAP
    //  ########################################################################################
    
    @State var ldapUserGroupName = ""
    
    @State var ldapUserGroupId = ""
    
    @State var ldapUserGroupName2 = ""
    
    @State var ldapUserGroupId2 = ""
    
    @State var ldapSearchCustomGroupSelection = LDAPCustomGroup(uuid: "", ldapServerID: 0, id: "", name: "", distinguishedName: "")

    
    @State var ldapServerSelection: LDAPServer = LDAPServer(id: 0, name: "")
    
//    @State var ldapSearchCustomGroupSelection = LDAPCustomGroup(uuid: "", ldapServerID: 0, id: "", name: "", distinguishedName: "")
    @State var ldapSearchCustomGroupSelection2 = LDAPCustomGroup(uuid: "", ldapServerID: 0, id: "", name: "", distinguishedName: "")
    
    @State var getDetailedPolicyHasRun = false
    @State var ldapSearch = ""
    
    //  ########################################################################################
    //  SELECTIONS
    //  ########################################################################################
    
    @State var computerGroupSelection = ComputerGroup(id: 0, name: "", isSmart: false)
    
    //  ########################################################################################
    //  Filters
    //  ########################################################################################
    
    @State var computerGroupFilter = ""
    @State var allLdapServersFilter = ""
    
    
    var body: some View {
        
        VStack(alignment: .leading) {

            LazyVGrid(columns: layout.threeColumns, spacing: 20) {
                
                
            }
                
                    
                   
            
            
            
            //  ################################################################################
            //  Set Scoping - Group
            //  ################################################################################
            
            Group {
                Divider()
                //  ################################################################################
                //  Group picker
                //  ################################################################################
                
                
                LazyVGrid(columns: layout.columns, spacing: 20) {
                    Picker(selection: $computerGroupSelection, label:Label("Groups", systemImage: "person.3")
                    ) {
                        //                        Text("").tag("")
                        ForEach(networkController.allComputerGroups.filter({computerGroupFilter == "" ? true : $0.name.contains(computerGroupFilter)})) { group in
                            Text(String(describing: group.name))
                                .tag(group as ComputerGroup?)
                        }
                    }
                    
                    //  ################################################################################
                    //  Update groups button
                    //  ################################################################################
                    
                    Button(action: {
                        progress.showProgress()
                        progress.waitForABit()
                        for eachItem in selectedPoliciesInt {
                            print("Updating for \(String(describing: eachItem ?? 0))")
                            let currentPolicyID = (eachItem ?? 0)
                            Task {
                                do {
                                    let policyAsXML = try await xmlController.getPolicyAsXMLaSync(server: server, policyID: currentPolicyID, authToken: networkController.authToken)
                                    xmlController.updateScopeCompGroupSetAsyncSingle(groupSelection: computerGroupSelection,authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policyID: String(describing:currentPolicyID), policyAsXML: policyAsXML)
                                } catch {
                                    print("Fetching detailed policy as xml failed: \(error)")
                                }
                            }
                        }
                    }) {
                        //                        Image(systemName: "plus.square.fill.on.square.fill")
                        Text("Scope To Group")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
            }
            
            //  ################################################################################
            //  LDAP SEARCH RESULTS - Picker 1
            //  ################################################################################
            
            //  ################################################################################
            //  Select Ldap group
            //  ################################################################################
            
            Divider()
            
            HStack(spacing:10 ){
                
                LazyVGrid(columns: layout.columns, spacing: 20) {
                    
                    Picker(selection: $ldapSearchCustomGroupSelection, label: Text("Search Results:").bold()) {
                        ForEach(scopingController.allLdapCustomGroupsCombinedArray, id: \.self) { group in
                            Text(String(describing: group.name))
                                .tag(ldapSearchCustomGroupSelection as LDAPCustomGroup?)
                        }
                    }
                    
                    
                    //  ################################################################################
                    //  Limitations
                    //  ################################################################################
                    
                    Button(action: {
                        print("Limitations pressed")
                        progress.showProgress()
                        progress.waitForABit()
                        for eachItem in selectedPoliciesInt {
                            
                            print("Updating for \(String(describing: eachItem))")
                            Task {
                                await xmlController.updatePolicyScopeLimitationsAuto(groupSelection: ldapSearchCustomGroupSelection, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policyID: String(describing: eachItem))
                            }
                        }
                    }) {
                        Text("Limit To Ldap")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
            }
            
            LazyVGrid(columns: layout.columns, spacing: 20) {
                
                HStack {
                    Text("Search Ldap")
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
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
            
            //  ################################################################################
            //                    Select Ldap server
            //  ################################################################################
            
            LazyVGrid(columns: layout.columns, spacing: 20) {
                Picker(selection: $ldapServerSelection, label: Text("Ldap Servers:").bold()) {
                    ForEach(scopingController.allLdapServers, id: \.self) { group in
                        Text(String(describing: group.name))
                            .tag(ldapServerSelection as LDAPServer?)
                    }
                }
                
                Button(action: {
                    
                    progress.showProgress()
                    progress.waitForABit()
                    
                    //            xmlController.clearMaintenanceBatch(selectedPoliciesInt: selectedPoliciesInt, server: server, authToken: networkController.authToken)
                    
                }) {
                    HStack(spacing: 10) {
                        Text("Update")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
            Divider()
            
            HStack(spacing:20 ){
                
                Text("Clear Limitations")
                
                Button(action: {
                    showingWarningClearLimit = true
                    progress.showProgress()
                    progress.waitForABit()
                    print("Pressing clear limitations")
                    for eachItem in selectedPoliciesInt {
                        print("Updating for \(String(describing: eachItem ?? 0))")
                        let currentPolicyID = (eachItem ?? 0)
                        
                        Task {
                            do {
                                let policyAsXML = try await xmlController.getPolicyAsXMLaSync(server: server, policyID: currentPolicyID, authToken: networkController.authToken)
                                
                                xmlController.updatePolicyScopeLimitAutoRemove(authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policyID: String(describing:currentPolicyID), currentPolicyAsXML: policyAsXML)
                            } catch {
                                print("Fetching detailed policy as xml failed: \(error)")
                            }
                        }
                    }
                }) {
                    Text("Clear")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .alert(isPresented: $showingWarningClearScope) {
                    Alert(title: Text("Caution!"), message: Text("This action will clear any limitations from the policy scoping.\n You will need to re-add these if you still require them"), dismissButton: .default(Text("I understand!")))
                }
            }
            //            }
            
            //  ################################################################################
            //              Clear Scope
            //  ################################################################################
            
            //            LazyVGrid(columns: layout.columnsWide, spacing: 20) {
            
            HStack(spacing:20 ){
                
                Text("Clear Scope")
                
                Button(action: {
                    showingWarningClearScope = true
                    progress.showProgress()
                    progress.waitForABit()
                    
                    for eachItem in selectedPoliciesInt {
                        
                        let currentPolicyID = (String(describing: eachItem ?? 0))
                        networkController.clearScope(server: server,resourceType:  ResourceType.policies, policyID: currentPolicyID, authToken: networkController.authToken)
                        print("Clear Scope for policy:\(eachItem ?? 0)")
                    }
                }) {
                    Text("Clear")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .alert(isPresented: $showingWarningClearScope) {
                    Alert(title: Text("Caution!"), message: Text("This action will clear devices from the policy scoping.\n You will need to rescope in order to deploy"), dismissButton: .default(Text("I understand!")))
                }
            }
            
            
            Spacer()
        }
        .padding()
    }
}
