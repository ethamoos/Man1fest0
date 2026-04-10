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
    // Accept a local snapshot of the detailed policy to avoid following the shared controller directly
    var localPolicyDetailed: PolicyDetailed? = nil
    
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
    // Filter specifically for the Exclusions group picker
    @State var exclusionGroupFilter = ""
    
    @State var computerFilter = ""
    
    @State private var departmentFilter: String = ""
    
    var filteredDepartments: [Department] {
        if departmentFilter.isEmpty {
            return networkController.departments
        } else {
            return networkController.departments.filter {
                $0.name.localizedCaseInsensitiveContains(departmentFilter)
            }
        }
    }
    
    @State private var buildingFilter: String = ""
    
    var filteredBuildings: [Building] {
        if buildingFilter.isEmpty {
            return networkController.buildings
        } else {
            return networkController.buildings.filter {
                $0.name.localizedCaseInsensitiveContains(buildingFilter)
            }
        }
    }
    
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

    // New: filter text for the "Search Results:" picker
    @State private var ldapSearchPickerFilter: String = ""

    // Computed filtered results for the picker
    var filteredLdapCustomGroups: [LDAPCustomGroup] {
        if ldapSearchPickerFilter.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return scopingController.allLdapCustomGroupsCombinedArray
        } else {
            return scopingController.allLdapCustomGroupsCombinedArray.filter {
                // Use localizedCaseInsensitiveContains on the group's name (safe-string conversion)
                String(describing: $0.name).localizedCaseInsensitiveContains(ldapSearchPickerFilter)
            }
        }
    }
    
    @State var getDetailedPolicyHasRun = false
    
    @State var ldapSearch = ""
    
    @State var allComputersButton: Bool = true
    
    //  ########################################################################################
    //  Warnings
    //  ########################################################################################
    
    
    @State private var showingWarningDelete = false
    @State private var showingWarningClearScope = false
    @State private var showingWarningLimitScope = false
    @State private var showingWarningExcludeScope = false
    @State private var showingWarningExcludeScopeComp = false
    @State private var showingWarningExcludeScopeDept = false
    @State private var showingWarningExcludeScopeBuilding = false
    @State private var showingWarningClearLimit = false
        @State private var showingWarningAllUsers = false
    @State private var showingWarningDisableAllUsers = false
    @State private var showingWarningAllComputers = false
    @State private var showingWarningDisableAllComputers = false
    
    @State private var showingWarningClearComputers = false
    
    @State private var showingWarningClearComputerGroups = false
    
    @State private var showingWarningAllComputersAndUsers = false
    @State private var showingWarningDisableAllComputersAndUsers = false
    
    
    
    
    //    ########################################################################################
    //    Interval picker state and options for logFlushInterval
    //    @State private var selectedIntervalNumber = "Three"
    //    @State private var selectedIntervalUnit = "Months"
    //    private let intervalNumbers = ["Zero", "One", "Two", "Three", "Six"]
    //    private let intervalUnits = ["Days", "Weeks", "Months", "Years"]
    //    Computed property to combine number and unit
    //    private var combinedInterval: String { "\(selectedIntervalNumber)+\(selectedIntervalUnit)" }
    
    @State var computerSearchText = ""
    
    // Computed property to filter and limit computers for Picker
    var filteredComputers: [Computer] {
        if computerSearchText.isEmpty {
            return Array(networkController.computers.prefix(100))
        } else {
            return networkController.computers.filter { $0.name.localizedCaseInsensitiveContains(computerSearchText) }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                scopingOverviewView
                editScopingView
            }
            .frame(minHeight: 1)
            .padding()
            .onAppear() {
                // Fetch computers if none are cached
                if networkController.computers.count == 0 {
                    print("Fetching computers for policy scope view")
                    Task { try? await networkController.getAllComputers() }
                }
                
                // Guarded fetch for the detailed policy: only request if we don't already have one
                // (or if the currently cached detailed policy is for a different policy id)
                if networkController.policyDetailed == nil || ((networkController.policyDetailed?.general?.jamfId ?? 0) != policyID) {
                    print("Fetching detailed policy for policyID: \(policyID)")
                    Task {
                        do {
                            try await networkController.getDetailedPolicy(server: server, authToken: networkController.authToken, policyID: String(describing: policyID))
                        } catch {
                            print("Failed to fetch detailed policy on appear: \(error)")
                        }
                    }
                }
             }
         }
     }

    // Split the large body into smaller computed views to help the compiler type-check more quickly.
    private var scopingOverviewView: some View {
        VStack(alignment: .leading) {
            scopingHeaderView
            scopingListsView
            scopingActionsView
        }
    }

    private var scopingHeaderView: some View {
        Group {
            if (localPolicyDetailed ?? networkController.policyDetailed)?.scope?.allComputers == true {
                Text("Scoped To All Computers").font(.subheadline).bold()
            } else {
                Text("All Computers is not enabled").font(.subheadline)
            }

            if (localPolicyDetailed ?? networkController.policyDetailed)?.scope?.all_jss_users == true {
                Text("Scoped To All Users").font(.subheadline).bold()
            } else {
                Text("All Users is not enabled").font(.subheadline)
            }
        }
    }

    private var scopingListsView: some View {
        VStack(alignment: .leading) {
            Divider()
            if (localPolicyDetailed ?? networkController.policyDetailed)?.scope?.computers?.count ?? 0 == 0 {
                Text("Not Scoped to any individual Computers").font(.subheadline)
            } else {
                VStack(alignment:.leading){
                    Text("Computers: ").font(.headline)
                    ForEach((localPolicyDetailed ?? networkController.policyDetailed)?.scope?.computers ?? []) { computer in
                        Text(String(computer.name)).font(.subheadline)
                    }
                }
                .padding()
            }

            Divider()
            if (localPolicyDetailed ?? networkController.policyDetailed)?.scope?.departments?.count ?? 0 == 0 {
                Text("Not Scoped to any Departments").font(.subheadline)
            } else {
                VStack(alignment:.leading){
                    Text("Departments: ").font(.headline)
                    ForEach((localPolicyDetailed ?? networkController.policyDetailed)?.scope?.departments ?? []) { department in
                        Text(String(department.name)).font(.subheadline)
                    }
                }
                .padding()
            }

            Divider()
            if (localPolicyDetailed ?? networkController.policyDetailed)?.scope?.computerGroups?.count ?? 0 == 0 {
                Text("Not Scoped to any Groups").font(.subheadline)
            } else {
                VStack(alignment:.leading){
                    Text("Computer Groups: ").font(.headline)
                    ForEach((localPolicyDetailed ?? networkController.policyDetailed)?.scope?.computerGroups ?? []) { computerGroups in
                        Text(String(computerGroups.name ?? "")).font(.subheadline)
                    }
                }
                .padding()
            }

            Divider()
            if (localPolicyDetailed ?? networkController.policyDetailed)?.scope?.buildings?.count ?? 0 == 0 {
                Text("Not Scoped to any Buildings").font(.subheadline)
            } else {
                VStack(alignment:.leading){
                    Text("Buildings: ").font(.headline)
                    ForEach((localPolicyDetailed ?? networkController.policyDetailed)?.scope?.buildings ?? []) { building in
                        Text(String(building.name)).font(.subheadline)
                    }
                }
                .padding()
            }
        }
    }

    private var scopingActionsView: some View {
        VStack(alignment: .leading) {
            HStack {
                Button(action: {
                    showingWarningAllComputers = true
                    progress.showProgress()
                    progress.waitForABit()
                }) {
                    HStack(spacing: 10) { Text("Enable All Computers") }
                    .alert(isPresented: $showingWarningAllComputers) {
                        Alert(
                            title: Text("Caution!"),
                            message: Text("This action will enable the policy scoping for all computers.\n This might cause the policy to run immediately to many devices"),
                            primaryButton: .destructive(Text("I understand!")) {
                                networkController.scopeAllComputers(server: server, authToken: networkController.authToken, policyID: String(describing: policyID))
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)

                Button(action: {
                    showingWarningAllUsers = true
                    progress.showProgress()
                    progress.waitForABit()
                }) {
                    HStack(spacing: 10) { Text("Enable All Users") }
                    .alert(isPresented: $showingWarningAllUsers) {
                        Alert(
                            title: Text("Caution!"),
                            message: Text("This action will enable the policy scoping for all users.\n This might cause the policy to run immediately to many devices"),
                            primaryButton: .destructive(Text("I understand!")) {
                                networkController.scopeAllUsers(server: server, authToken: networkController.authToken, policyID: String(describing: policyID))
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)

                Button(action: {
                    showingWarningAllComputers = true
                    progress.showProgress()
                    progress.waitForABit()
                }) {
                    HStack(spacing: 10) { Text("Enable All Computers & Users") }
                    .alert(isPresented: $showingWarningAllComputers) {
                        Alert(
                            title: Text("Caution!"),
                            message: Text("This action will enable the policy scoping for all computers and all users.\n This might cause the policy to run immediately to many devices"),
                            primaryButton: .destructive(Text("I understand!")) {
                                networkController.scopeAllComputersAndUsers(server: server, authToken: networkController.authToken, policyID: String(describing: policyID))
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }

            HStack {
                Button(action: {
                    showingWarningDisableAllComputers = true
                    progress.showProgress()
                    progress.waitForABit()
                }) {
                    HStack(spacing: 10) { Image(systemName: "eraser"); Text("Disable All Computers") }
                    .alert(isPresented: $showingWarningDisableAllComputers) {
                        Alert(
                            title: Text("Caution!"),
                            message: Text("This action will disable the policy scoping for all computers.\n This might cause the policy to stop running on many devices"),
                            primaryButton: .destructive(Text("I understand!")) {
                                networkController.scopeDisableAllComputers(server: server, authToken: networkController.authToken, policyID: String(describing: policyID))
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)

                Button(action: {
                    showingWarningDisableAllUsers = true
                    progress.showProgress()
                    progress.waitForABit()
                }) {
                    HStack(spacing: 10) { Image(systemName: "eraser"); Text("Disable All Users") }
                    .alert(isPresented: $showingWarningDisableAllUsers) {
                        Alert(
                            title: Text("Caution!"),
                            message: Text("This action will disable the policy scoping for all users.\n This might cause the policy to stop running on many devices"),
                            primaryButton: .destructive(Text("I understand!")) {
                                networkController.scopeDisableAllUsers(server: server, authToken: networkController.authToken, policyID: String(describing: policyID))
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)

                Divider()

                HStack {
                    Button(action: {
                        showingWarningClearScope = true
                        progress.showProgress()
                        progress.waitForABit()
                    }) {
                        HStack(spacing: 10) { Image(systemName: "eraser"); Text("Clear Scope") }
                        .alert(isPresented: $showingWarningClearScope) {
                            Alert(
                                title: Text("Caution!"),
                                message: Text("This action will clear the policy scoping.\n You will need to rescope in order to deploy"),
                                primaryButton: .destructive(Text("I understand!")) {
                                    networkController.clearScope(server: server, resourceType: ResourceType.policyDetail, policyID: String(describing: policyID), authToken: networkController.authToken)
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
    }

    private var editScopingView: some View {
        VStack(alignment: .leading) {
            Divider()
//            DisclosureGroup("Edit Scoping") {
                VStack(alignment: .leading, spacing: 12) {
                    computersEditorView
                    departmentEditorView
                    buildingEditorView
                    groupPickerEditorView
                    limitationsEditorView
                    editLimitationsEditorView
                    exclusionsEditorView
                }
//            }
        }
    }

    // MARK: - Edit Scoping Subviews
    private var computersEditorView: some View {
        Group {
            LazyVGrid(columns: layout.columnFlex, spacing: 10) {
                Toggle("", isOn: $allComputersButton)
                    .toggleStyle(SwitchToggleStyle(tint: .red))
                    .onChange(of: allComputersButton) { value in
                        Task {
                            if value == true {
                                xmlController.enableAllComputersToScope(xmlContent: xmlController.currentPolicyAsXML, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policyId: String(describing: policyID))
                            } else {
                                xmlController.disableAllComputersToScope(xmlContent: xmlController.currentPolicyAsXML, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policyId: String(describing: policyID))
                            }
                        }
                    }
    #if os(macOS)
                if (localPolicyDetailed ?? networkController.policyDetailed)?.scope?.allComputers == true {
                    Text("All Computers")
                } else {
                    Text("Specific Computers")
                    HStack {
                        TextField("Search Computers", text: $computerSearchText)
                        Picker(selection: $selectionComp, label: Text("Computer:").bold()) {
                            ForEach(filteredComputers, id: \.id) { comp in
                                Text(comp.name).tag(comp)
                            }
                        }
                        Button(action: {
                            progress.showProgress()
                            progress.waitForABit()
                            xmlController.getPolicyAsXML(server: server, policyID: policyID, authToken: networkController.authToken)
                            xmlController.addComputerToPolicyScope(xmlContent: xmlController.currentPolicyAsXML, computerName: selectionComp.name, authToken: networkController.authToken, computerId: String(describing: selectionComp.id), resourceType: selectedResourceType, server: server, policyId: String(describing: policyID))
                            Task {
                                do { try await networkController.getDetailedPolicy(server: server, authToken: networkController.authToken, policyID: String(describing: policyID)) } catch { print("Failed to refresh detailed policy after adding computer to scope: \(error)") }
                            }
                        }) {
                            HStack(spacing: 10) { Image(systemName: "plus.square.fill.on.square.fill"); Text("Add") }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        Spacer()
                    }
                    HStack {
                        Button(action: {
                            showingWarningClearComputers = true
                            progress.showProgress()
                            progress.waitForABit()
                        }) {
                            HStack(spacing: 10) { Image(systemName: "eraser"); Text("Clear Computers") }
                            .alert(isPresented: $showingWarningClearComputers) {
                                Alert(
                                    title: Text("Caution!"),
                                    message: Text("This action will clear any individually assigned computers from this policy scoping.\n You will need to rescope in order to deploy"),
                                    primaryButton: .destructive(Text("I understand!")) {
                                        networkController.clearComputers(server: server, resourceType: ResourceType.policyDetail, policyID: String(describing: policyID), authToken: networkController.authToken)
                                    },
                                    secondaryButton: .cancel()
                                )
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)

                        Button(action: {
                            showingWarningClearComputerGroups = true
                            progress.showProgress()
                            progress.waitForABit()
                        }) {
                            HStack(spacing: 10) { Image(systemName: "eraser"); Text("Clear Computer Groups") }
                            .alert(isPresented: $showingWarningClearComputerGroups) {
                                Alert(
                                    title: Text("Caution!"),
                                    message: Text("This action will clear all static or smart computer groups from this policy scoping.\n You will need to rescope in order to deploy"),
                                    primaryButton: .destructive(Text("I understand!")) {
                                        networkController.clearComputerGroups(server: server, resourceType: ResourceType.policyDetail, policyID: String(describing: policyID), authToken: networkController.authToken)
                                    },
                                    secondaryButton: .cancel()
                                )
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                }
    #endif
            }
        }
    }

    private var departmentEditorView: some View {
        Group {
            Divider()
            LazyVGrid(columns: layout.threeColumns, spacing: 20) {
                TextField("Filter departments...", text: $departmentFilter)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 4)

                Picker(selection: $selectionDepartment, label: Text("Department:").bold()) {
                    ForEach(filteredDepartments, id: \.self) { department in
                        Text(department.name).tag(department as Department?)
                    }
                }
                .onAppear { if let first = networkController.departments.first { selectionDepartment = first } }

                Button(action: {
                    progress.showProgress(); progress.waitForABit(); xmlController.getPolicyAsXML(server: server, policyID: policyID, authToken: networkController.authToken); xmlController.addDepartmentToPolicyScope(xmlContent: xmlController.currentPolicyAsXML, departmentName: selectionDepartment.name, departmentId: String(describing: selectionDepartment.jamfId ?? 0), authToken: networkController.authToken, policyId: String(describing: policyID), resourceType: selectedResourceType, server: server)
                }) {
                    HStack(spacing: 10) { Image(systemName: "plus.square.fill.on.square.fill"); Text("Add Department") }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
        }
    }

    private var buildingEditorView: some View {
        Group {
            Divider()
            LazyVGrid(columns: layout.threeColumns, spacing: 20) {
                TextField("Filter buildings...", text: $buildingFilter)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 4)

                Picker(selection: $selectionBuilding, label: Text("Building:").bold()) {
                    Text("").tag(Building(id: 0, name: ""))
                    ForEach(filteredBuildings, id: \.self) { building in
                        Text(building.name).tag(building)
                    }
                }
                .onAppear { if let first = networkController.buildings.first { selectionBuilding = first } }

                Button(action: {
                    progress.showProgress(); progress.waitForABit(); xmlController.getPolicyAsXML(server: server, policyID: policyID, authToken: networkController.authToken); xmlController.addBuildingToPolicyScope(xmlContent: xmlController.currentPolicyAsXML, buildingName: selectionBuilding.name, buildingId: String(describing: selectionBuilding.id), policyId: String(describing: policyID), resourceType: ResourceType.policyDetail, server: server, authToken: networkController.authToken)
                }) {
                    HStack(spacing: 10) { Image(systemName: "plus.square.fill.on.square.fill"); Text("Add Building") }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
        }
    }

    private var groupPickerEditorView: some View {
        Group {
            Divider()
            LazyVGrid(columns: layout.fourColumnsFlexNarrow, spacing: 5) {
                TextField("Filter", text: $computerGroupFilter)
                Picker(selection: $selectionCompGroup, label: Text("Group:").bold()) {
                    ForEach(networkController.allComputerGroups.filter({computerGroupFilter == "" ? true : $0.name.contains(computerGroupFilter)}) , id: \.self) { group in
                        Text(String(describing: group.name)).tag(group as ComputerGroup?)
                    }
                }
                .onAppear { if networkController.allComputerGroups.count > 0 { selectionCompGroup = networkController.allComputerGroups[0] } }

                Button(action: {
                    progress.showProgress(); progress.waitForABit(); xmlController.updateScopeCompGroupSingle(groupSelection: selectionCompGroup, authToken: networkController.authToken,resourceType: ResourceType.policyDetail, server: server, policyID: String(describing: policyID), currentPolicyAsXML: xmlController.currentPolicyAsXML, currentPolicyAsAEXML: networkController.aexmlDoc)
                }) {
                    HStack(spacing: 10) { Image(systemName: "plus.square.fill.on.square.fill"); Text("Add Group ") }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
        }
    }

    private var limitationsEditorView: some View {
        Group {
            Divider()
            VStack(alignment:.leading){
                Text("Limitations").font(.system(size: 14, weight: .bold, design: .default))
                Divider()
                // Use fallback to shared detailed policy when local snapshot is absent
                if ((localPolicyDetailed ?? networkController.policyDetailed)?.scope?.limitations?.userGroups?.count ?? 0) != 0 {
                    ForEach((localPolicyDetailed ?? networkController.policyDetailed)?.scope?.limitations?.userGroups ?? []) { limitation in
                        Text(String(limitation.name ?? "")).font(.subheadline)
                    }
                    .padding()
                } else {
                    Text("No limitations configured").font(.subheadline)
                }
            }
        }
    }

    private var editLimitationsEditorView: some View {
//        DisclosureGroup("Edit Limitations") {
        VStack(alignment: .leading) {
//            LazyVGrid(columns: layout.threeColumnsFlex, spacing: 10) {
            HStack(spacing: 5) {
                //                        Picker(selection: $ldapSearchCustomGroupSelection, label: Text("Search Results:")) {
                // Provide a lightweight filter field above the picker (placed inline)
                //                        }
                // Move the filter and picker out of the Picker literal so layout is clearer
//                VStack(alignment: .leading, spacing: 6) {
                    TextField("Filter search results...", text: $ldapSearchPickerFilter)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.bottom, 4)
                    
                    Picker(selection: $ldapSearchCustomGroupSelection, label: Text("Search Results:")) {
                        ForEach(filteredLdapCustomGroups, id: \.self) { group in
                            Text(String(describing: group.name)).tag(group)
                        }
                    }
                }
//            }
            
            HStack(spacing: 5) {
                
                Button(action: {
                    showingWarningLimitScope = true
                    progress.showProgress()
                    progress.waitForABit()
                }) {
                    Image(systemName: "plus.square.fill.on.square.fill"); Text("Limit")
                }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .alert(isPresented: $showingWarningLimitScope) {
                        Alert(
                            title: Text("Caution!"),
                            message: Text("This action will limit the policy scoping.\n Some devices may not receive the policy"),
                            primaryButton: .destructive(Text("I understand!")) {
                                xmlController.getPolicyAsXML(server: server, policyID: policyID, authToken: networkController.authToken)
                                Task { await xmlController.updatePolicyScopeLimitationsAuto(groupSelection: ldapSearchCustomGroupSelection, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policyID: String(describing: policyID)) }
                            },
                            secondaryButton: .cancel()
                        )
                    }
                    
                    Button(action: {
                        progress.showProgress(); progress.waitForABit(); showingWarningClearLimit = true
                    }) { Text("Clear Limitations") }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .alert(isPresented: $showingWarningClearLimit) {
                            Alert(
                                title: Text("Caution!"),
                                message: Text("This action will clear any current limitations on the policy scoping.\n Some devices previously blocked may now receive the policy"),
                                primaryButton: .destructive(Text("I understand!")) {
                                    xmlController.updatePolicyScopeLimitAutoRemove(authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policyID: String(describing:policyID), currentPolicyAsXML: xmlController.currentPolicyAsXML)
                                },
                                secondaryButton: .cancel()
                            )
                        }
                }
//            }
            
            // LDAP server selection and search
            LazyVGrid(columns: layout.threeColumnsFlex, spacing: 20) {
                Picker(selection: $ldapServerSelection, label: Text("Ldap Servers:")) {
                    ForEach(scopingController.allLdapServers, id: \.self) { group in
                        Text(String(describing: group.name)).tag(ldapServerSelection as LDAPServer?)
                    }
                }
            }
            
            LazyVGrid(columns: layout.threeColumnsFlex, spacing: 20) {
                    HStack { Text("Search LDAP"); TextField("", text: $ldapSearch) }
                    Button(action: { progress.showProgress(); progress.waitForABit(); Task { try await scopingController.getLdapGroupsSearch(server: server, search: ldapSearch, authToken: networkController.authToken) } }) {
                        HStack(spacing:10) { Image(systemName: "magnifyingglass"); Text("Search") }
                    }
                }
            }
//        }
    }

    private var exclusionsEditorView: some View {
        Group {
            VStack(alignment: .leading) {
                Divider()
                Text("Exclusions: ").font(.headline)
                Divider()

                // Excluded computers
                if ((localPolicyDetailed ?? networkController.policyDetailed)?.scope?.exclusions?.computers?.count ?? 0) == 0 {
                    Text("No Computers Excluded").font(.subheadline).padding(.bottom,10)
                } else {
                    Text("Excluded Computers").font(.subheadline.bold()).padding(.bottom,10)
                    VStack(alignment:.leading) {
                        ForEach((localPolicyDetailed ?? networkController.policyDetailed)?.scope?.exclusions?.computers ?? []) { computer in
                            Text(computer.name ?? "")
                        }
                    }
                    .padding(.bottom,10)
                }

                // Edit Exclusions
                DisclosureGroup("Edit Exclusions") {
                    VStack(alignment: .leading) {
                        // Excluded computer groups
                        if ((localPolicyDetailed ?? networkController.policyDetailed)?.scope?.exclusions?.computerGroups?.count ?? 0) == 0 {
                            Text("No Computer Groups Excluded").font(.subheadline).padding(.bottom,10)
                        } else {
                            Text("Excluded Computer Groups").font(.headline.bold()).padding(.bottom,10)
                            ForEach((localPolicyDetailed ?? networkController.policyDetailed)?.scope?.exclusions?.computerGroups ?? []) { computerGroup in
                                Text(computerGroup.name ?? "")
                            }
                            .padding(.bottom,10)
                        }

                        // Excluded departments
                        if ((localPolicyDetailed ?? networkController.policyDetailed)?.scope?.exclusions?.departments?.count ?? 0) == 0 {
                            Text("No Departments Excluded").font(.subheadline).padding(.bottom,10)
                        } else {
                            Text("Excluded Departments").font(.headline.bold()).padding(.bottom,10)
                            ForEach((localPolicyDetailed ?? networkController.policyDetailed)?.scope?.exclusions?.departments ?? []) { department in
                                Text(department.name ?? "")
                            }
                            .padding(.bottom,10)
                        }

                        // Excluded buildings
                        if ((localPolicyDetailed ?? networkController.policyDetailed)?.scope?.exclusions?.buildings?.count ?? 0) == 0 {
                            Text("No Buildings Excluded").font(.subheadline).padding(.bottom,10)
                        } else {
                            Text("Excluded Buildings").font(.headline.bold()).padding(.bottom,10)
                            ForEach((localPolicyDetailed ?? networkController.policyDetailed)?.scope?.exclusions?.buildings ?? []) { building in
                                Text(building.name ?? "")
                            }
                            .padding(.bottom,10)
                        }

                        Divider()
                        Text("Exclude a Computer Group").font(.headline)
                        LazyVGrid(columns: layout.threeColumnsFlex, spacing: 10) {
                            TextField("Filter groups...", text: $exclusionGroupFilter)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.bottom, 4)

                            Picker(selection: $selectionCompGroup, label: Text("Group to exclude:").bold()) {
                                ForEach(networkController.allComputerGroups.filter({ exclusionGroupFilter == "" ? true : $0.name.contains(exclusionGroupFilter) }), id: \.self) { group in
                                    Text(String(describing: group.name)).tag(group as ComputerGroup?)
                                }
                                ForEach(networkController.allComputerGroups.filter({ exclusionGroupFilter.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(exclusionGroupFilter) }), id: \.self) { group in
                                    Text(group.name).tag(group as ComputerGroup?)
                                }
                            }
                            .onAppear { if networkController.allComputerGroups.count > 0 { selectionCompGroup = networkController.allComputerGroups[0] } }

                            Button(action: {
                                showingWarningExcludeScope = true
                                progress.showProgress()
                                progress.waitForABit()
                            }) {
                                HStack(spacing:10) { Image(systemName: "plus.square.fill.on.square.fill"); Text("Exclude Group") }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            .alert(isPresented: $showingWarningExcludeScope) {
                                Alert(
                                    title: Text("Caution!"),
                                    message: Text("This action will add the selected computer group to the exclusions for this policy."),
                                    primaryButton: .destructive(Text("I understand!")) {
                                        xmlController.getPolicyAsXML(server: server, policyID: policyID, authToken: networkController.authToken)
                                        let groupName = selectionCompGroup.name
                                        let groupId = String(describing: selectionCompGroup.id)
                                        let updatedXML = scopingController.updateScopeExclusions(xmlString: xmlController.currentPolicyAsXML, groupName: groupName, groupId: groupId)
                                        if let url = URL(string: "\(server)/JSSResource/policies/id/\(policyID)") {
                                            xmlController.sendRequestAsXML(url: url, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, xml: updatedXML, httpMethod: "PUT")
                                        }
                                        Task {
                                            do {
                                                try await networkController.getDetailedPolicy(server: server, authToken: networkController.authToken, policyID: String(describing: policyID))
                                            } catch {
                                                print("Failed to refresh detailed policy after adding exclusion: \(error)")
                                            }
                                        }
                                    },
                                    secondaryButton: .cancel()
                                )
                            }
                        }

                        // Specific Computers exclusion
                        Text("Specific Computers")
                        HStack {
                            TextField("Search Computers", text: $computerSearchText)
                            Picker(selection: $selectionComp, label: Text("Computer:").bold()) {
                                ForEach(filteredComputers, id: \.id) { comp in
                                    Text(comp.name).tag(comp)
                                }
                            }
                        }

                        Button(action: {
                            showingWarningExcludeScope = true
                            progress.showProgress()
                            progress.waitForABit()
                        }) {
                            HStack(spacing:10) { Image(systemName: "plus.square.fill.on.square.fill"); Text("Exclude Computer") }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .alert(isPresented: $showingWarningExcludeScope) {
                            Alert(
                                title: Text("Caution!"),
                                message: Text("This action will add the selected computer to the exclusions for this policy."),
                                primaryButton: .destructive(Text("I understand!")) {
                                    let compName = String(describing: selectionComp.name)
                                    let compId = String(describing: selectionComp.id)
                                    let updatedXML = scopingController.updateScopeExclusionsAddComputer(xmlString: xmlController.currentPolicyAsXML, computerName: compName, computerId: compId)
                                    if let url = URL(string: "\(server)/JSSResource/policies/id/\(policyID)") {
                                        xmlController.sendRequestAsXML(url: url, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, xml: updatedXML, httpMethod: "PUT")
                                    }
                                    Task {
                                        do {
                                            try await networkController.getDetailedPolicy(server: server, authToken: networkController.authToken, policyID: String(describing: policyID))
                                        } catch {
                                            print("Failed to refresh detailed policy after adding exclusion: \(error)")
                                        }
                                    }
                                },
                                secondaryButton: .cancel()
                            )
                        }

                        // Departments and Building exclusion UI
                        Divider()
                        Text("Exclude a Department").font(.headline)
                        LazyVGrid(columns: layout.threeColumnsFlex, spacing: 10) {
                            TextField("Filter departments...", text: $departmentFilter)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.bottom, 4)
                            Picker(selection: $selectionDepartment, label: Text("Department:").bold()) {
                                ForEach(filteredDepartments, id: \.self) { dept in
                                    Text(dept.name).tag(dept as Department?)
                                }
                            }
                            .onAppear { if let first = networkController.departments.first { selectionDepartment = first } }

                            Button(action: {
                                showingWarningExcludeScopeDept = true
                                progress.showProgress()
                                progress.waitForABit()
                            }) {
                                HStack(spacing:10) { Image(systemName: "plus.square.fill.on.square.fill"); Text("Exclude Department") }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            .alert(isPresented: $showingWarningExcludeScopeDept) {
                                Alert(
                                    title: Text("Caution!"),
                                    message: Text("This action will add the selected department to the exclusions for this policy."),
                                    primaryButton: .destructive(Text("I understand!")) {
                                        let deptName = String(describing: selectionDepartment.name)
                                        let deptId = String(describing: selectionDepartment.jamfId ?? 0)
                                        let updatedXML = scopingController.updateScopeExclusionsAddDepartment(xmlString: xmlController.currentPolicyAsXML, departmentName: deptName, departmentId: deptId)
                                        if let url = URL(string: "\(server)/JSSResource/policies/id/\(policyID)") {
                                            xmlController.sendRequestAsXML(url: url, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, xml: updatedXML, httpMethod: "PUT")
                                        }
                                        Task {
                                            do {
                                                try await networkController.getDetailedPolicy(server: server, authToken: networkController.authToken, policyID: String(describing: policyID))
                                            } catch {
                                                print("Failed to refresh detailed policy after adding department exclusion: \(error)")
                                            }
                                        }
                                    },
                                    secondaryButton: .cancel()
                                )
                            }
                        }

                        Divider()
                        Text("Exclude a Building").font(.headline)
                        LazyVGrid(columns: layout.threeColumnsFlex, spacing: 10) {
                            TextField("Filter buildings...", text: $buildingFilter)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.bottom, 4)
                            Picker(selection: $selectionBuilding, label: Text("Building:").bold()) {
                                ForEach(filteredBuildings, id: \.self) { bld in
                                    Text(bld.name).tag(bld)
                                }
                            }
                            .onAppear { if let first = networkController.buildings.first { selectionBuilding = first } }

                            Button(action: {
                                showingWarningExcludeScopeBuilding = true
                                progress.showProgress()
                                progress.waitForABit()
                            }) {
                                HStack(spacing:10) { Image(systemName: "plus.square.fill.on.square.fill"); Text("Exclude Building") }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            .alert(isPresented: $showingWarningExcludeScopeBuilding) {
                                Alert(
                                    title: Text("Caution!"),
                                    message: Text("This action will add the selected building to the exclusions for this policy."),
                                    primaryButton: .destructive(Text("I understand!")) {
                                        let bldName = String(describing: selectionBuilding.name)
                                        let bldId = String(describing: selectionBuilding.id)
                                        let updatedXML = scopingController.updateScopeExclusionsAddBuilding(xmlString: xmlController.currentPolicyAsXML, buildingName: bldName, buildingId: bldId)
                                        if let url = URL(string: "\(server)/JSSResource/policies/id/\(policyID)") {
                                            xmlController.sendRequestAsXML(url: url, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, xml: updatedXML, httpMethod: "PUT")
                                        }
                                        Task {
                                            do {
                                                try await networkController.getDetailedPolicy(server: server, authToken: networkController.authToken, policyID: String(describing: policyID))
                                            } catch {
                                                print("Failed to refresh detailed policy after adding building exclusion: \(error)")
                                            }
                                        }
                                    },
                                    secondaryButton: .cancel()
                                )
                            }
                        }

                        Button(action: {
                            showingWarningClearLimit = true
                            progress.showProgress()
                            progress.waitForABit()
                        }) {
                            Text("Clear Exclusions")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .alert(isPresented: $showingWarningClearLimit) {
                            Alert(
                                title: Text("Caution!"),
                                message: Text("This action will clear any current exclusions on the policy scoping.\n Some devices previously blocked may now receive the policy"),
                                primaryButton: .destructive(Text("I understand!")) {
                                    xmlController.removeExclusions(server: server, policyID: String(describing:policyID), authToken: networkController.authToken)
                                    Task {
                                        do {
                                            try await networkController.getDetailedPolicy(server: server, authToken: networkController.authToken, policyID: String(describing: policyID))
                                        } catch {
                                            print("Failed to refresh detailed policy after clearing exclusion: \(error)")
                                        }
                                    }
                                },
                                secondaryButton: .cancel()
                            )
                        }

                        .onAppear() {
                            if networkController.computers.count == 0 {
                                Task { try await networkController.getAllComputers() }
                            }
                        }
                    }
                }
            }
        }
    }
}

//#Preview {
//    PolicyScopeTabView()
//}
