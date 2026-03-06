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
    @State private var showingWarningClearExclusions = false
    
    
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
    
    @State var ldapSearchCustomGroupSelection2 = LDAPCustomGroup(uuid: "", ldapServerID: 0, id: "", name: "", distinguishedName: "")
    
    @State var getDetailedPolicyHasRun = false
    @State var ldapSearch = ""
    
    //  ########################################################################################
    //  SELECTIONS
    //  ########################################################################################
    
    @State var computerGroupSelection = ComputerGroup(id: 0, name: "", isSmart: false)
    
    // Flags for applying all-computers/static/smart behaviour
    @State private var allComputersStaticEnable = false
    @State private var allComputersSmartEnable = false
    
    //  ########################################################################################
    //  Filters
    //  ########################################################################################
    
    @State var computerGroupFilter = ""
    @State var allLdapServersFilter = ""
    
    
    // helper to determine if any valid policy IDs were selected
    var selectedNonZero: [Int] {
        selectedPoliciesInt.compactMap { $0 }.filter { $0 != 0 }
    }

    var hasSelection: Bool { !selectedNonZero.isEmpty }

    var body: some View {
        
        VStack(alignment: .leading) {

            // Debug header to show selection count and IDs (helps diagnose empty UI)
            HStack {
                Text("Selected policies: \(selectedNonZero.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if selectedNonZero.count > 0 {
                    Text("IDs: \(selectedNonZero.map({String($0)}).joined(separator: ","))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 6)

            if !hasSelection {
                VStack(alignment: .center, spacing: 12) {
                    Spacer()
                    Text("No policies selected")
                        .font(.headline)
                    Text("Select one or more policies from the table above to enable Scope / Limitations / Exclusions controls.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button(action: {
                        progress.showProgress()
                        progress.waitForABit()
                        // No selection — try to fetch or refresh policies to make selection possible
                        Task {
                            await networkController.ensurePoliciesLoaded(server: server, authToken: networkController.authToken)
                        }
                    }) {
                        Text("Refresh policies list")
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {

                // Batch scope buttons similar to PoliciesActionScopeTab
                LazyVGrid(columns: layout.threeColumns, spacing: 12) {
                    Button(action: {
                        progress.showProgress()
                        progress.waitForABit()
                        for eachItem in selectedPoliciesInt {
                            let pid = eachItem ?? 0
                            networkController.scopeAllComputers(server: server, authToken: networkController.authToken, policyID: String(describing: pid))
                        }
                    }) {
                        Label("Scope To All Computers", systemImage: "plus.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(!hasSelection)

                    Button(action: {
                        progress.showProgress()
                        progress.waitForABit()
                        for eachItem in selectedPoliciesInt {
                            let pid = eachItem ?? 0
                            networkController.scopeAllUsers(server: server, authToken: networkController.authToken, policyID: String(describing: pid))
                        }
                    }) {
                        Label("Scope To All Users", systemImage: "plus.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(!hasSelection)

                    Button(action: {
                        progress.showProgress()
                        progress.waitForABit()
                        for eachItem in selectedPoliciesInt {
                            let pid = eachItem ?? 0
                            networkController.scopeAllUsers(server: server, authToken: networkController.authToken, policyID: String(describing: pid))
                            networkController.scopeAllComputers(server: server, authToken: networkController.authToken, policyID: String(describing: pid))
                        }
                    }) {
                        Label("Scope To All Computers & Users", systemImage: "plus.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(!hasSelection)

                    Button(action: {
                        // Clear scope for selected policies
                        showingWarningClearScope = true
                    }) {
                        Label("Clear Scope", systemImage: "eraser")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .alert(isPresented: $showingWarningClearScope) {
                        Alert(
                            title: Text("Caution!"),
                            message: Text("This action will clear devices from the policy scoping.\n You will need to rescope in order to deploy"),
                            primaryButton: .destructive(Text("I understand!")) {
                                for eachItem in selectedPoliciesInt {
                                    let currentPolicyID = String(describing: eachItem ?? 0)
                                    networkController.clearScope(server: server, resourceType: ResourceType.policies, policyID: currentPolicyID, authToken: networkController.authToken)
                                    print("Clear Scope for policy:\(eachItem ?? 0)")
                                }
                            },
                            secondaryButton: .cancel()
                        )
                    }
                    .disabled(!hasSelection)
                }
                .padding(.bottom, 8)

                Divider()

                //  ################################################################################
                //  Set Scoping - Group
                //  ################################################################################
            
                Group {
                    //  ################################################################################
                    //  Group picker
                    //  ################################################################################

                    LazyVGrid(columns: layout.columns, spacing: 20) {
                        Picker(selection: $computerGroupSelection, label:Label("Groups", systemImage: "person.3")
                        ) {
                            ForEach(networkController.allComputerGroups.filter({computerGroupFilter == "" ? true : $0.name.contains(computerGroupFilter)})) { group in
                                Text(String(describing: group.name))
                                    .tag(group as ComputerGroup)
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
                                        xmlController.updateScopeCompGroupSetAsyncSingle(groupSelection: computerGroupSelection, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policyID: String(describing:currentPolicyID), policyAsXML: policyAsXML)
                                    } catch {
                                        print("Fetching detailed policy as xml failed: \(error)")
                                    }
                                }
                            }
                        }) {
                            Text("Scope To Group")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    }
                }

                //  ################################################################################
                //  LDAP SEARCH RESULTS - Picker 1
                //  ################################################################################

                Divider()

                LazyVGrid(columns: layout.columns, spacing: 20) {
                    Picker(selection: $ldapSearchCustomGroupSelection, label: Text("Search Results:").bold()) {
                        ForEach(scopingController.allLdapCustomGroupsCombinedArray, id: \.self) { group in
                            Text(String(describing: group.name))
                                .tag(group as LDAPCustomGroup)
                        }
                    }

                    HStack(spacing: 10) {
                        Button(action: {
                            print("Limitations pressed")
                            progress.showProgress()
                            progress.waitForABit()
                            for eachItem in selectedPoliciesInt {
                                print("Updating for \(String(describing: eachItem))")
                                let currentPolicyID = (eachItem ?? 0)
                                Task {
                                    await xmlController.updatePolicyScopeLimitationsAuto(groupSelection: ldapSearchCustomGroupSelection, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policyID: String(describing: currentPolicyID))
                            }
                        }
                    }) {
                        Text("Limit To Ldap")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)

                    Button(action: {
                        showingWarningClearLimit = true
                    }) {
                        Text("Clear Limitations")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .alert(isPresented: $showingWarningClearLimit) {
                        Alert(
                            title: Text("Caution!"),
                            message: Text("This action will clear any limitations from the policy scoping.\n You will need to re-add these if you still require them"),
                            primaryButton: .destructive(Text("I understand!")) {
                                for eachItem in selectedPoliciesInt {
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
                            },
                            secondaryButton: .cancel()
                        )
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
                            .tag(group as LDAPServer)
                    }
                }

                Button(action: {
                    progress.showProgress()
                    progress.waitForABit()
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

                Text("Clear Exclusions")

                Button(action: {
                    showingWarningClearExclusions = true
                }) {
                    Text("Clear")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .alert(isPresented: $showingWarningClearExclusions) {
                    Alert(
                        title: Text("Caution!"),
                        message: Text("This action will clear any current exclusions on the policy scoping.\n Some devices previously blocked may now receive the policy"),
                        primaryButton: .destructive(Text("I understand!")) {
                            for eachItem in selectedPoliciesInt {
                                let policyID = (eachItem ?? 0)
                                xmlController.removeExclusions(server: server, policyID: String(describing:policyID), authToken: networkController.authToken)
                            }
                        },
                        secondaryButton: .cancel()
                    )
                }
            }

            Spacer()
        }
        .padding()
    }
}

}
}
