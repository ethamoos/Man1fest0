//
//  PoliciesActionView.swift
//  Man1fest0
//
//  Created by Amos Deane on 23/10/2023.
//

import SwiftUI

struct PoliciesActionView: View {
    var server: String
    var selectedResourceType: ResourceType

    // ENVIRONMENT
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var layout: Layout
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var xmlController: XmlBrain
    @EnvironmentObject var scopingController: ScopingBrain

    // STATE
    @State var categories: [Category] = []
    @State var categorySelection: Category? = nil
    @State var enableDisable: Bool = true

    @State private var policiesSelection = Set<Policy>()
    @State var searchText = ""
    @State var status: Bool = true

    // Warnings/alerts
    @State private var showingWarning = false
    @State private var showingWarningAllUsers = false
    @State private var showingWarningAllComputers = false
    @State private var showingWarningAllComputersAndUsers = false
    @State private var showingWarningClearExclusions = false
    @State private var showingWarningClearScope = false
    @State private var showingWarningSetDP = false
    @State private var showingNoSelectionAlert = false
    @State private var dpActionMessage: String = ""

    // Filters / LDAP / other state
    @State var computerGroupFilter = ""
    @State var allLdapServersFilter = ""
    @State var ldapUserGroupName = ""
    @State var ldapUserGroupId = ""
    @State var ldapUserGroupName2 = ""
    @State var ldapUserGroupId2 = ""
    @State var ldapServerSelection: LDAPServer? = nil
    @State var ldapSearchCustomGroupSelection = LDAPCustomGroup(uuid: "", ldapServerID: 0, id: "", name: "", distinguishedName: "")
    @State var ldapSearchCustomGroupSelection2 = LDAPCustomGroup(uuid: "", ldapServerID: 0, id: "", name: "", distinguishedName: "")
    @State var getDetailedPolicyHasRun = false
    @State var ldapSearch = ""

    @State var computerGroupSelection: ComputerGroup? = nil
    @State private var allComputersSmartEnable = false
    @State private var allComputersStaticEnable = false
    @State var xmlData = ""

    var body: some View {
        VStack(spacing: 12) {
            // Prominent action button (always visible)
            HStack {
                Button(action: {
                    performBatchSetDP()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "archivebox")
                        Text("Set DP to Default")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
            .padding([.horizontal, .top])
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
            .padding(.horizontal)

            // Inline confirmation UI (visible and unmistakable) as a fallback if alert isn't shown
            if showingWarningSetDP {
                HStack(spacing: 12) {
                    Text("Confirm: set Distribution Point to default for \(policiesSelection.count) selected policy/policies?")
                        .font(.subheadline)
                    Spacer()
                    Button(action: {
                        print("Inline confirm: running batchSetDPToDefault for \(policiesSelection.count) policies")
                        xmlController.batchSetDPToDefault(policiesSelection: policiesSelection, server: server, authToken: networkController.authToken)
                        showingWarningSetDP = false
                        progress.endProgress()
                    }) {
                        Text("I understand")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)

                    Button(action: {
                        print("Inline confirm: cancelled")
                        showingWarningSetDP = false
                        progress.endProgress()
                    }) {
                        Text("Cancel")
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
            }

            // Immediate status banner
            if !dpActionMessage.isEmpty {
                HStack {
                    Text(dpActionMessage)
                        .font(.subheadline)
                        .padding(8)
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(6)
                    Spacer()
                }
                .padding(.horizontal)
            }

            // Main list + controls
            if networkController.policies.count > 0 {
                List(searchResults, id: \.self, selection: $policiesSelection) { policy in
                    HStack {
                        Image(systemName: "text.justify")
                        Text(policy.name)
                    }
                    .foregroundColor(.blue)
                }
                .onReceive([self.policiesSelection].publisher.first()) { _ in
                    if !self.policiesSelection.isEmpty && getDetailedPolicyHasRun == false {
                        getDetailedPolicies(policiesSelection: policiesSelection)
                        getDetailedPolicyHasRun = true
                    }
                }
                .toolbar {
                    Button(action: {
                        progress.showProgress()
                        progress.waitForABit()
                        networkController.connect(server: server, resourceType: ResourceType.policies, authToken: networkController.authToken)
                        getDetailedPolicies(policiesSelection: policiesSelection)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)

                    Button(action: {
                        performBatchSetDP()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "archivebox")
                            Text("Set DP to Default")
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                }

                // Controls block (kept compact) - preserve existing behavior
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 20) {
                        Button(action: {
                            showingWarning = true
                            progress.showProgressView = true
                            progress.waitForABit()
                        }) { Text("Delete") }
                        .alert(isPresented: $showingWarning) {
                            Alert(
                                title: Text("Caution!"),
                                message: Text("This action will delete data.\n Always ensure that you have a backup!"),
                                primaryButton: .destructive(Text("I understand!")) {
                                    networkController.processDeletePolicies(selection: policiesSelection, server: server, resourceType: ResourceType.policies, authToken: networkController.authToken)
                                },
                                secondaryButton: .cancel()
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)

                        Button(action: {
                            progress.showProgressView = true
                            networkController.processingComplete = false
                            progress.waitForABit()
                            if let selectedCategory = categorySelection {
                                networkController.selectedCategory = selectedCategory
                            }
                            networkController.processUpdatePolicies(selection: policiesSelection, server: server, resourceType: ResourceType.policies, enableDisable: enableDisable, authToken: networkController.authToken)
                        }) { Text("Update") }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)

                        HStack {
                            Toggle("", isOn: $enableDisable)
                                .toggleStyle(SwitchToggleStyle(tint: .red))
                            Text(enableDisable ? "Enabled" : "Disabled")
                        }

                        Button(action: {
                            progress.showProgress()
                            progress.waitForABit()
                            for eachItem in policiesSelection {
                                let currentPolicyID = eachItem.jamfId ?? 0
                                ASyncFileDownloader.downloadFileAsyncAuth(objectID: currentPolicyID, resourceType: ResourceType.policies, server: server, authToken: networkController.authToken) { _, _ in }
                            }
                        }) {
                            Image(systemName: "plus.circle")
                            Text("Download")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.yellow)

                    }

                    Divider()

                    // Category picker
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 300)), GridItem(.flexible(minimum: 200))], spacing: 20) {
                        if !networkController.categories.isEmpty {
                            Picker(selection: $categorySelection, label: Text("Category:")) {
                                Text("No category selected").tag(nil as Category?)
                                ForEach(networkController.categories, id: \.self) { c in
                                    Text(c.name).tag(c as Category?)
                                }
                            }
                            .onAppear { if !networkController.categories.isEmpty { categorySelection = networkController.categories.first } }
                            .onChange(of: networkController.categories) { new in if !new.isEmpty { categorySelection = new.first } }
                        } else {
                            Text("No categories available")
                        }
                    }

                    Divider()

                    VStack(alignment: .leading) {
                        Text("Selections").fontWeight(.bold)
                        List(Array(policiesSelection), id: \.self) { p in Text(p.name) }
                            .frame(height: 50)
                    }

                    // Scoping / other actions - original implementations preserved below
                    Group {
                        Divider()
                        Text("Scoping").fontWeight(.bold)
                        Divider()

                        HStack {
                            Button(action: {
                                showingWarningAllComputers = true
                                progress.showProgress()
                                progress.waitForABit()
                            }) {
                                HStack { Image(systemName: "plus.circle"); Text("Scope To All Computers") }
                            }
                            .alert(isPresented: $showingWarningAllComputers) {
                                Alert(title: Text("Caution!"), message: Text("This action will enable the policy scoping for all computers."), primaryButton: .destructive(Text("I understand!")) { networkController.batchScopeAllComputers(policiesSelection: policiesSelection, server: server, authToken: networkController.authToken) }, secondaryButton: .cancel())
                            }
                            .buttonStyle(.borderedProminent).tint(.red)

                            Button(action: {
                                showingWarningAllUsers = true
                                progress.showProgress()
                                progress.waitForABit()
                            }) {
                                HStack { Image(systemName: "plus.circle"); Text("Scope To All Users") }
                            }
                            .alert(isPresented: $showingWarningAllUsers) {
                                Alert(title: Text("Caution!"), message: Text("This action will enable the policy scoping for all users."), primaryButton: .destructive(Text("I understand!")) { networkController.batchScopeAllUsers(policiesSelection: policiesSelection, server: server, authToken: networkController.authToken) }, secondaryButton: .cancel())
                            }
                            .buttonStyle(.borderedProminent).tint(.red)

                            Button(action: {
                                showingWarningAllComputersAndUsers = true
                                progress.showProgress()
                                progress.waitForABit()
                            }) {
                                HStack { Image(systemName: "plus.circle"); Text("Scope To All Computers & Users") }
                            }
                            .alert(isPresented: $showingWarningAllComputersAndUsers) {
                                Alert(title: Text("Caution!"), message: Text("This action will enable the policy scoping for all computers and all users."), primaryButton: .destructive(Text("I understand!")) { networkController.batchScopeAllUsers(policiesSelection: policiesSelection, server: server, authToken: networkController.authToken); networkController.batchScopeAllComputers(policiesSelection: policiesSelection, server: server, authToken: networkController.authToken) }, secondaryButton: .cancel())
                            }
                            .buttonStyle(.borderedProminent).tint(.red)

                            Button(action: {
                                showingWarningClearScope = true
                                progress.showProgress()
                                progress.waitForABit()
                            }) {
                                HStack { Image(systemName: "eraser"); Text("Clear Scope") }
                            }
                            .alert(isPresented: $showingWarningClearScope) {
                                Alert(title: Text("Caution!"), message: Text("This action will clear the policy scoping for all policies selected."), primaryButton: .destructive(Text("I understand!")) { xmlController.clearScopeBatch(selectedPolicies: policiesSelection, server: server, authToken: networkController.authToken) }, secondaryButton: .cancel())
                            }
                            .buttonStyle(.borderedProminent).tint(.red)
                        }

                        Text("Scope to Group").fontWeight(.bold)

                        LazyVGrid(columns: layout.columns, spacing: 10) {
                            Picker(selection: $computerGroupSelection, label: Label("Static Groups", systemImage: "person.3")) {
                                Text("No group selected").tag(nil as ComputerGroup?)
                                ForEach(networkController.allComputerGroups.filter({ computerGroupFilter == "" ? true : $0.name.contains(computerGroupFilter) }), id: \.self) { group in
                                    if group.isSmart != true { Text(group.name).tag(group as ComputerGroup?) }
                                }
                            }

                            Button(action: {
                                progress.showProgress(); progress.waitForABit()
                                Task {
                                    if let groupSelection = computerGroupSelection {
                                        await updateScopeCompGroupSet(groupSelection: groupSelection, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policiesSelection: policiesSelection, smartStatus: "true", all_computersStatus: allComputersStaticEnable)
                                    }
                                }
                            }) {
                                Image(systemName: "plus.circle"); Text("Update")
                            }
                            .buttonStyle(.borderedProminent).tint(.blue)
                        }

                        LazyVGrid(columns: layout.columns, spacing: 10) {
                            Picker(selection: $computerGroupSelection, label: Label("Smart Groups", systemImage: "person.3")) {
                                Text("No group selected").tag(nil as ComputerGroup?)
                                ForEach(networkController.allComputerGroups.filter({ computerGroupFilter == "" ? true : $0.name.contains(computerGroupFilter) }), id: \.self) { group in
                                    if group.isSmart == true { Text(group.name).tag(group as ComputerGroup?) }
                                }
                            }

                            Button(action: {
                                progress.showProgress(); progress.waitForABit()
                                Task {
                                    if let groupSelection = computerGroupSelection {
                                        await updateScopeCompGroupSet(groupSelection: groupSelection, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policiesSelection: policiesSelection, smartStatus: "true", all_computersStatus: allComputersSmartEnable)
                                    }
                                }
                            }) {
                                Image(systemName: "plus.circle"); Text("Update")
                            }
                            .buttonStyle(.borderedProminent).tint(.blue)
                        }
                    }
                }
                .padding()

                if progress.showProgressView == true {
                    ProgressView { Text("Processing").padding() }
                }
            } else {
                ProgressView { Text("Loading") }
            }

        }
        // Alerts attached to the outer view so toolbar/footer buttons can trigger them
        .alert(isPresented: $showingWarningSetDP) {
            Alert(title: Text("Caution!"), message: Text("This action will set the distribution point to default for all selected policies."), primaryButton: .destructive(Text("I understand!")) {
                xmlController.batchSetDPToDefault(policiesSelection: policiesSelection, server: server, authToken: networkController.authToken)
                print("batchSetDPToDefault executed")
            }, secondaryButton: .cancel())
        }
        .alert(isPresented: $showingNoSelectionAlert) {
            Alert(title: Text("No selection"), message: Text("Please select one or more policies before using Set DP to Default."), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            Task { try await networkController.getAllGroups(server: server, authToken: networkController.authToken) }
            Task { try await scopingController.getLdapServers(server: server, authToken: networkController.authToken) }
            networkController.refreshPolicies()
            networkController.refreshCategories()
            networkController.refreshComputers()
            networkController.refreshDepartments()
        }
        .frame(minWidth: 200, minHeight: 100, alignment: .leading)
    }

    private func getAllPolicies() {
        print("Clicking Button")
    }

    var searchResults: [Policy] {
        if searchText.isEmpty { return networkController.policies } else { return networkController.policies.filter { $0.name.lowercased().contains(searchText.lowercased()) } }
    }

    func getDetailedPolicies(policiesSelection: Set<Policy>) {
        for eachItem in policiesSelection {
            layout.separationLine()
            let policyID = eachItem.jamfId
            xmlController.getPolicyAsXML(server: server, policyID: policyID ?? 0, authToken: networkController.authToken)
        }
    }

    // Helper to run the batch action and provide immediate feedback
    private func performBatchSetDP() {
        if policiesSelection.isEmpty {
            print("performBatchSetDP: no selection")
            showingNoSelectionAlert = true
            return
        }
        let names = policiesSelection.map { $0.name }
        print("performBatchSetDP: running for \(policiesSelection.count) policies: \(names)")
        progress.showProgress()
        dpActionMessage = "Running: setting DP to default for \(policiesSelection.count) policies..."

        // Existing XmlBrain method is synchronous in this codebase
        print("Calling xmlController.batchSetDPToDefault(...)")
        xmlController.batchSetDPToDefault(policiesSelection: policiesSelection, server: server, authToken: networkController.authToken)
        print("Returned from xmlController.batchSetDPToDefault(...)")

        progress.endProgress()
        dpActionMessage = "Completed: Set DP to Default for \(policiesSelection.count) policies"
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            dpActionMessage = ""
        }
    }

    func updateScopeCompGroupSet(groupSelection: ComputerGroup, authToken: String, resourceType: ResourceType, server: String, policiesSelection: Set<Policy>, smartStatus: String, all_computersStatus: Bool) async {
        let groupName = groupSelection.name
        let groupId = groupSelection.id
        for eachPolicy in policiesSelection {
            let eachPolicyId = eachPolicy.jamfId ?? 0
            do {
                let currentPolicy = try await xmlController.getPolicyAsXMLaSync(server: server, policyID: eachPolicyId, authToken: authToken)
                xmlController.readXMLDataFromString(xmlContent: currentPolicy)
                let scope = networkController.aexmlDoc.root["scope"]
                let currentSettingsAllComps = networkController.aexmlDoc.root["scope"]["all_computers"]
                currentSettingsAllComps.removeFromParent()
                scope.addChild(name: "all_computers", value: String(describing: all_computersStatus))
                let currentComputerGroups = networkController.aexmlDoc.root["scope"]["computer_groups"].addChild(name: "computer_group")
                currentComputerGroups.addChild(name: "name", value: groupName)
                currentComputerGroups.addChild(name: "id", value: String(describing: groupId))
                currentComputerGroups.addChild(name: "isSmart", value: String(describing: smartStatus))
                try await networkController.sendRequestAsXMLAsyncID(url: URL(string: server + "/JSSResource/policies/id/" + "\(eachPolicyId)")!, authToken: authToken, resourceType: resourceType, xml: networkController.aexmlDoc.root.xml, httpMethod: "PUT", policyID: String(describing: eachPolicyId))
            } catch {
                print("currentPolicy failed with error \(error)")
            }
        }
    }

    func updatePolicyScopeLimitationsAuto(groupSelection: LDAPCustomGroup, authToken: String, resourceType: ResourceType, server: String, policyID: String) async {
        Task {
            do {
                let policyAsXML = try await xmlController.getPolicyAsXMLaSync(server: server, policyID: Int(policyID) ?? 0, authToken: authToken)
                xmlController.readXMLDataFromString(xmlContent: policyAsXML)
                let currentLdapGroups = networkController.aexmlDoc.root["scope"]["limit_to_users"]["user_groups"]
                currentLdapGroups.addChild(name: "user_group", value: groupSelection.name)
                let currentLdapGroupsLimitations = networkController.aexmlDoc.root["scope"]["limitations"]["user_groups"].addChild(name: "user_group")
                currentLdapGroupsLimitations.addChild(name: "id", value: String(describing: groupSelection.id))
                currentLdapGroupsLimitations.addChild(name: "name", value: String(describing: groupSelection.name))
                try await networkController.sendRequestAsXMLAsyncID(url: URL(string: server + "/JSSResource/policies/id/" + "\(policyID)")!, authToken: authToken, resourceType: resourceType, xml: networkController.aexmlDoc.root.xml, httpMethod: "PUT", policyID: policyID)
            } catch {
                print("Fetching detailed policy as xml failed: \(error)")
            }
        }
    }
}


//struct PoliciesActionView_Previews: PreviewProvider {
//    static var previews: some View {
//        PoliciesActionView(server: server, username: <#String#>, password: <#String#>, selectedResourceType: ResourceType.policyDetail)
//    }
//}
