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
    
    //  ########################################################################################
    //  ENVIRONMENT
    //  ########################################################################################
    
    @EnvironmentObject var progress: Progress
    
    @EnvironmentObject var layout: Layout
    
    @EnvironmentObject var networkController: NetBrain
    
    @EnvironmentObject var xmlController: XmlBrain
    
    @EnvironmentObject var scopingController: ScopingBrain
    
    
    //  ########################################################################################
    //  ENVIRONMENT - END
    //  ########################################################################################
    
    @State var categories: [Category] = []
    
    @State  var categorySelection: Category? = nil
    
    @State var enableDisable: Bool = true
    
    //    @State var ldapUserGroupName = ""
    //
    //    @State var ldapUserGroupId = ""
    
    
    //  ########################################################################################
    //    POLICY SELECTION
    //  ########################################################################################
    
    
    @State private var policiesSelection = Set<Policy>()
    
    @State var searchText = ""
    // Focus for the inline search field so it can be focused via Cmd-F
    @FocusState private var searchFieldFocused: Bool
    
    @State var status: Bool = true
    
    
    //  ########################################################################################
    //  Warnings
    //  ########################################################################################
    
    
    @State private var showingWarning = false
    
    @State private var showingWarningAllUsers = false
    
    @State private var showingWarningAllComputers = false
    
    @State private var showingWarningAllComputersAndUsers = false
    
    @State private var showingWarningClearExclusions = false
    
    @State private var showingWarningClearScope = false

    // Confirmation for Set DP action
    @State private var showingWarningSetDP = false
    
    
    //  ########################################################################################
    //  Filters
    //  ########################################################################################
    
    @State var computerGroupFilter = ""
    @State var allLdapServersFilter = ""
    
    //  ########################################################################################
    //  LDAP
    //  ########################################################################################
    
    @State var ldapUserGroupName = ""
    
    @State var ldapUserGroupId = ""
    
    @State var ldapUserGroupName2 = ""
    
    @State var ldapUserGroupId2 = ""
    
    @State var ldapServerSelection: LDAPServer? = nil
    
    @State var ldapSearchCustomGroupSelection = LDAPCustomGroup(uuid: "", ldapServerID: 0, id: "", name: "", distinguishedName: "")
    @State var ldapSearchCustomGroupSelection2 = LDAPCustomGroup(uuid: "", ldapServerID: 0, id: "", name: "", distinguishedName: "")
    
    @State var getDetailedPolicyHasRun = false
    @State var ldapSearch = ""
    
    //    ########################################################################################
    //    SELECTIONS
    //    ########################################################################################
    
    @State var computerGroupSelection: ComputerGroup? = nil
    
    @State private var allComputersSmartEnable = false
    @State private var allComputersStaticEnable = false
    
    //    ########################################################################################
    //    Xml data
    //    ########################################################################################
    
    @State var xmlData = ""
    
    var body: some View {
        
        //              ################################################################################
        //              List policies
        //              ################################################################################
        
        VStack(alignment: .leading) {

            if networkController.policies.count > 0 {

                // Inline search field (visible in the view) — useful when .searchable is disabled in the toolbar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search policies", text: $searchText)
                        .focused($searchFieldFocused)
                        .accessibilityLabel("Search policies")
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(minWidth: 200)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .help("Clear search")
                        .buttonStyle(.plain)
                    }
                }
                .padding([.leading, .trailing, .top])
                
                List(searchResults, id: \.self, selection: $policiesSelection) { policy in

                    HStack {
                        Image(systemName:"text.justify")
                        Text("\(policy.name)")
                    }
                    .foregroundColor(.blue)
                }
                // .searchable removed to avoid multiple SwiftUI search toolbar items in the same window
                 .onReceive([self.policiesSelection].publisher.first()) { (value) in
                    
                    //                    print("policiesSelection List is:\(value)")
                    print("getDetailedPolicyHasRun is:\(getDetailedPolicyHasRun)")
                    
                    if self.policiesSelection.isEmpty {
                        //                       print("policiesSelection is empty")
                    } else {
                        //                       print("policiesSelection is not empty")
                        if getDetailedPolicyHasRun == false {
                            print("Calling: getDetailedPolicies")
                            getDetailedPolicies(policiesSelection: policiesSelection)
                            getDetailedPolicyHasRun = true
                        }
                    }
                    
                    if xmlController.currentPolicyAsXML.isEmpty {
                        print("No value for: xmlController.currentPolicyAsXML")
                    } else {
                        print("xmlController.currentPolicyAsXML is populated")
                    }
                }
                
                
                .toolbar {
                    
                    Button(action: {
                        
                        progress.showProgress()
                        progress.waitForABit()
                        
                        networkController.connect(server: server,resourceType:  ResourceType.policies, authToken: networkController.authToken)
                        
                        getDetailedPolicies(policiesSelection: policiesSelection)
                        print("Refresh button clicked on PoliciesAction View")
                        
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    // Hidden shortcut to focus the inline search (Cmd-F)
                    Button(action: { searchFieldFocused = true }) {
                        EmptyView()
                    }
                    .keyboardShortcut("f", modifiers: [.command])
                    .hidden()
                    //                    .shadow(color: .gray, radius: 2, x: 0, y: 2)
                }
                
                
                //  ##############################################################################
                //              BUTTONS  -   Delete, Update, Disable & Download
                // ##############################################################################
                
                
                //  ##############################################################################
                //              DELETE
                // ##############################################################################

                VStack(alignment: .leading) {
                    
                    HStack(spacing:20) {
                        
                        Button(action: {
                            
                            showingWarning = true
                            progress.showProgressView = true
                            print("Set showProgressView to true")
                            print(progress.showProgressView)
                            progress.waitForABit()
                            print("Check processingComplete")
                            print(String(describing: networkController.processingComplete))
                            
                        }) {
                            Text("Delete")
                        }
                        
                        .alert(isPresented: $showingWarning) {
                            Alert(
                                title: Text("Caution!"),
                                message: Text("This action will delete data.\n Always ensure that you have a backup!"),
                                primaryButton: .destructive(Text("I understand!")) {
                                    // Code to execute when "Yes" is tapped
                                    networkController.processDeletePolicies(selection: policiesSelection, server: server, resourceType: ResourceType.policies, authToken: networkController.authToken)
                                    print("Yes tapped")
                                },
                                secondaryButton: .cancel()
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .shadow(color: .gray, radius: 2, x: 0, y: 2)
                        
//              ################################################################################
//              Update Category
//              ################################################################################

                        Button(action: {
                            
                            progress.showProgressView = true
                            networkController.processingComplete = false
                            progress.waitForABit()
                            if let selectedCategory = categorySelection {
                                print("Setting category to:\(String(describing: selectedCategory))")
                                networkController.selectedCategory = selectedCategory
                            } else {
                                print("No category selected")
                            }
                            print("Policy enable/disable status is set as:\(String(describing: enableDisable))")
                            networkController.processUpdatePolicies(selection: policiesSelection, server: server, resourceType: ResourceType.policies, enableDisable: enableDisable, authToken: networkController.authToken)
                            
                        }) {
                            Text("Update")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        
                        
                        // ######################################################################
                        //  Enable or Disable Policies Toggle
                        // ######################################################################

                        HStack {
                            
                            Toggle("", isOn: $enableDisable)
                                .toggleStyle(SwitchToggleStyle(tint: .red))
                            if enableDisable {
                                Text("Enabled")
                            } else {
                                Text("Disabled")
                            }
                        }
                        
                        // ######################################################################
                        //              DOWNLOAD OPTION
                        // ######################################################################

                        Button(action: {
                            
                            progress.showProgress()
                            progress.waitForABit()

                            for eachItem in policiesSelection {

                                let currentPolicyID = (eachItem.jamfId ?? 0)

                                print("Download file for \(eachItem.name)")
                                print("jamfId is \(String(describing: eachItem.jamfId ?? 0))")

                                ASyncFileDownloader.downloadFileAsyncAuth( objectID: currentPolicyID, resourceType: ResourceType.policies, server: server, authToken: networkController.authToken) { (path, error) in}
                            }

                        }) {
                            Image(systemName: "plus.circle")
                            Text("Download")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.yellow)
                        .shadow(color: .gray, radius: 2, x: 0, y: 2)
                        
                        
                        Button(action: {
                            // Ask for confirmation before executing the batch action
                            showingWarningSetDP = true
                            progress.showProgress()
                            progress.waitForABit()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "archivebox")
                                Text("Set DP to Default")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .alert(isPresented: $showingWarningSetDP) {
                            Alert(
                                title: Text("Caution!"),
                                message: Text("This action will set the distribution point to default for all selected policies."),
                                primaryButton: .destructive(Text("I understand!")) {
                                    print("Confirmed: calling xmlController.batchSetDPToDefault for selection: \(policiesSelection.map{ $0.name })")
                                    xmlController.batchSetDPToDefault(policiesSelection: policiesSelection, server: server, authToken: networkController.authToken)
                                    progress.endProgress()
                                },
                                secondaryButton: .cancel({ progress.endProgress() })
                            )
                        }
                        
                    }
                    
                    // ######################################################################
                    //              Category
                    // ######################################################################

                    Divider()
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 300)), GridItem(.flexible(minimum: 200))], spacing: 20) {
                        HStack {
                            if !networkController.categories.isEmpty {
                                Picker(selection: $categorySelection, label: Text("Category:\t\t")) {
                                    Text("No category selected").tag(nil as Category?)
                                    ForEach(networkController.categories, id: \.self) { category in
                                        Text(category.name).tag(category as Category?)
                                    }
                                }
                                .onAppear {
                                    if !networkController.categories.isEmpty {
                                        categorySelection = networkController.categories.first
                                    }
                                }
                                .onChange(of: networkController.categories) { newCategories in
                                    if !newCategories.isEmpty {
                                        categorySelection = newCategories.first
                                    }
                                }
                            } else {
                                Text("No categories available")
                            }
                        }
                    }
                    
                    // ######################################################################
                    //              UPDATE POLICY - COMPLETE
                    // ######################################################################

                    // ######################################################################
                    //              Show selections
                    // ######################################################################

                    
//                    Divider()
//                    VStack(alignment: .leading) {
//
//                        Text("Selections").fontWeight(.bold)
//
//                        List(Array(policiesSelection), id: \.self) { policy in
//
//                            Text(policy.name )
//
//                        }
//                        .frame(height: 50)
//                    }
                    
                  
                }
                .padding()
                
                if progress.showProgressView == true {
                    
                    ProgressView {
                        Text("Processing")
                            .padding()
                    }
                    .padding()
                } else {
                    Text("")
                }
                
                // Add bottom TabView with two tabs: Scope and Packages
                TabView {
                    PoliciesActionScopeTab(
                        policiesSelection: $policiesSelection,
                        server: server,
                        computerGroupSelection: $computerGroupSelection,
                        computerGroupFilter: $computerGroupFilter,
                        allComputersStaticEnable: $allComputersStaticEnable,
                        allComputersSmartEnable: $allComputersSmartEnable,
                        ldapSearchCustomGroupSelection: $ldapSearchCustomGroupSelection,
                        ldapServerSelection: $ldapServerSelection,
                        ldapSearch: $ldapSearch,
                        onUpdateScopeCompGroupSet: { group, smartStatus, allComp in
                            Task {
                                await updateScopeCompGroupSet(groupSelection: group, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policiesSelection: policiesSelection, smartStatus: smartStatus, all_computersStatus: allComp)
                            }
                        },
                        onUpdatePolicyScopeLimitationsAuto: { group, policyID in
                            Task {
                                await updatePolicyScopeLimitationsAuto(groupSelection: group, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policyID: policyID)
                            }
                        },
                        onClearLimitations: { policyID in
                            Task {
                                do {
                                    let policyAsXML = try await xmlController.getPolicyAsXMLaSync(server: server, policyID: Int(policyID) ?? 0, authToken: networkController.authToken)
                                    xmlController.updatePolicyScopeLimitAutoRemove(authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policyID: String(describing: policyID), currentPolicyAsXML: policyAsXML)
                                } catch {
                                    print("Error clearing limitations: \(error)")
                                }
                            }
                        },
                        onClearExclusions: {
                            xmlController.clearExclusionsBatch(selectedPolicies: policiesSelection, server: server, authToken: networkController.authToken)
                        }
                    )
                    .tabItem {
                        Label("Scope", systemImage: "person.3")
                    }
                    PoliciesActionPackagesTab()
                        .tabItem {
                            Label("Packages", systemImage: "shippingbox")
                        }
                }
                 .frame(maxWidth: .infinity, maxHeight: 200)
                 .padding()
            
            } else {
                
                ProgressView {
                    Text("Loading")
                }
            }
        }
        
        .onAppear {
            
            print("PolicyActionView appeared - connecting")
            
            Task {
                print("Fetching all groups")
                try await networkController.getAllGroups(server: server, authToken: networkController.authToken)
            }
            Task {
                try await scopingController.getLdapServers(server: server, authToken: networkController.authToken)
            }
            
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
        if searchText.isEmpty {
            // print("Search is empty")
            return networkController.policies
        } else {
            // print("Search is currently is currently:\(searchText)")
            return networkController.policies.filter { $0.name.lowercased().contains(searchText.lowercased())}
        }
    }
    
    func getDetailedPolicies(policiesSelection:Set<Policy>) {
        
        print("Running: getDetailedPolicies")
        
        print("policiesSelection is \(policiesSelection)")
        
        for eachItem in policiesSelection {
            layout.separationLine()
            print("Items as Dictionary is \(eachItem)")
            
            let policyID = eachItem.jamfId
            let policyName: String = String(describing:eachItem.name)
            print("Current policyID is:\(String(describing: policyID ?? 0))")
            print("Current policyName is:\(String(describing: policyName))")
            print("Run:getPolicyAsXML")
            
            xmlController.getPolicyAsXML(server: server, policyID: policyID ?? 0, authToken: networkController.authToken)
        }
    }
    
    func updateScopeCompGroupSet(groupSelection: ComputerGroup, authToken: String, resourceType: ResourceType, server: String, policiesSelection: Set<Policy>,smartStatus: String, all_computersStatus: Bool) async {
        
        let groupName = groupSelection.name
        let groupId = groupSelection.id
        layout.separationLine()
        print("Running updateScopeCompGroupSet")
        print("group name is:\(groupName)")
        print("group id is:\(groupId)")
        
        for eachPolicy in policiesSelection {
            let eachPolicyId = eachPolicy.jamfId ?? 0
            let policyName: String = String(describing:eachPolicy.name)
            layout.separationLine()
            print("Running for policyName:\(policyName)")
            print("Processing policy id:\(eachPolicyId)")
            let jamfURLQuery = server + "/JSSResource/policies/id/" + "\(eachPolicyId)"
            let url = URL(string: jamfURLQuery)!
            
//    #################################################################################
//            Get policy as xml data
//    #################################################################################
            do {
                let currentPolicy = try await xmlController.getPolicyAsXMLaSync(server: server, policyID: eachPolicyId, authToken: authToken)
//    #################################################################################
//            Read data back
//    #################################################################################
                layout.separationLine()
                print("Reading current policy and storing in: networkController.aexmlDoc")
                xmlController.readXMLDataFromString(xmlContent: currentPolicy)
                layout.separationLine()
                print("Remove old scope for all_computers")
                let scope = networkController.aexmlDoc.root["scope"]
                let currentSettingsAllComps = networkController.aexmlDoc.root["scope"]["all_computers"]
                currentSettingsAllComps.removeFromParent()
                print("Add new scope for all_computers")
                scope.addChild(name: "all_computers", value: String(describing: all_computersStatus))
                print("Add new scope for computer_groups")

                let currentComputerGroups = networkController.aexmlDoc.root["scope"]["computer_groups"].addChild(name: "computer_group")
                currentComputerGroups.addChild(name: "name", value: groupName)
                currentComputerGroups.addChild(name: "id", value: String(describing: groupId))
                currentComputerGroups.addChild(name: "isSmart", value: String(describing: smartStatus))
                print("smartStatus is set as:\(smartStatus)")
                print("all_computersStatus is set as:\(all_computersStatus)")
                layout.separationLine()
                print("Read main aeXML doc - updated for:\(eachPolicyId)")
                print(networkController.aexmlDoc.xml)
                print("Submit updated doc")
                
                Task {
                    try await networkController.sendRequestAsXMLAsyncID(url: url, authToken: authToken, resourceType: resourceType, xml: networkController.aexmlDoc.root.xml, httpMethod: "PUT", policyID: String(describing: eachPolicyId) )
                }
                
            } catch {
                print("currentPolicy failed with error \(error)")
            }
        }
    }
    
    func updatePolicyScopeLimitationsAuto(groupSelection: LDAPCustomGroup, authToken: String, resourceType: ResourceType, server: String, policyID: String) async {
        
        let jamfURLQuery = server + "/JSSResource/policies/id/" + "\(policyID)"
        let url = URL(string: jamfURLQuery)!
        let ldapUserGroupName = groupSelection.name
        let ldapUserGroupID = groupSelection.id
        layout.separationLine()
        print("Running updatePolicyScopeLimitationsAuto - Scoping Controller")
        print("policyID is:\(policyID)")
        print("ldapUserGroupName is:\(ldapUserGroupName)")
        print("ldapUserGroupID is:\(ldapUserGroupID)")

        Task {
            do {
                let policyAsXML = try await xmlController.getPolicyAsXMLaSync(server: server, policyID: Int(policyID) ?? 0, authToken: authToken)
                layout.separationLine()
                print("policyAsXML is:\(policyAsXML)")
                print("policyID is:\(policyID)")
                print("Xml data is present - reading and adding to:self.readXMLDataFromStringScopingBrain ")
//                print("policyAsXML is:\(policyAsXML)")
                xmlController.readXMLDataFromString(xmlContent: policyAsXML)
                print("Adding limit_to_users")
                let currentLdapGroups = networkController.aexmlDoc.root["scope"]["limit_to_users"]["user_groups"]
                currentLdapGroups.addChild(name: "user_group", value: ldapUserGroupName)
                let currentLdapGroupsLimitations = networkController.aexmlDoc.root["scope"]["limitations"]["user_groups"].addChild(name: "user_group")
                currentLdapGroupsLimitations.addChild(name: "id", value: String(describing: ldapUserGroupID))
                currentLdapGroupsLimitations.addChild(name: "name", value: String(describing: ldapUserGroupName))
                layout.separationLine()
                print("Read main XML doc - updated")
                print(networkController.aexmlDoc.xml)
                print("Submit updated doc")
                try await networkController.sendRequestAsXMLAsyncID(url: url, authToken: authToken,resourceType: resourceType, xml: networkController.aexmlDoc.root.xml, httpMethod: "PUT", policyID: policyID)
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

// PoliciesActionScopeTab with bindings and action closures
struct PoliciesActionScopeTab: View {
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var xmlController: XmlBrain
    @EnvironmentObject var scopingController: ScopingBrain
    @EnvironmentObject var layout: Layout
    @EnvironmentObject var progress: Progress

    @Binding var policiesSelection: Set<Policy>
    var server: String
    @Binding var computerGroupSelection: ComputerGroup?
    @Binding var computerGroupFilter: String
    @Binding var allComputersStaticEnable: Bool
    @Binding var allComputersSmartEnable: Bool
    @Binding var ldapSearchCustomGroupSelection: LDAPCustomGroup
    @Binding var ldapServerSelection: LDAPServer?
    @Binding var ldapSearch: String

    // Action closures provided by the parent view
    var onUpdateScopeCompGroupSet: (_ group: ComputerGroup, _ smartStatus: String, _ allComputersStatus: Bool) -> Void
    var onUpdatePolicyScopeLimitationsAuto: (_ group: LDAPCustomGroup, _ policyID: String) -> Void
    var onClearLimitations: (_ policyID: String) -> Void
    var onClearExclusions: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Policies Action - Scope")
                    .font(.headline)
                Text("Controls for scoping, limitations and exclusions for selected policies.")
                    .font(.subheadline)
                Divider()

                // Batch scope buttons (operate on policiesSelection)
                HStack(spacing: 12) {
                    Button(action: {
                        progress.showProgress()
                        progress.waitForABit()
                        // call networkController with current selection
                        networkController.batchScopeAllComputers(policiesSelection: policiesSelection, server: server, authToken: networkController.authToken)
                    }) {
                        Label("Scope To All Computers", systemImage: "plus.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)

                    Button(action: {
                        progress.showProgress()
                        progress.waitForABit()
                        networkController.batchScopeAllUsers(policiesSelection: policiesSelection, server: server, authToken: networkController.authToken)
                    }) {
                        Label("Scope To All Users", systemImage: "plus.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)

                    Button(action: {
                        progress.showProgress()
                        progress.waitForABit()
                        networkController.batchScopeAllUsers(policiesSelection: policiesSelection, server: server, authToken: networkController.authToken)
                        networkController.batchScopeAllComputers(policiesSelection: policiesSelection, server: server, authToken: networkController.authToken)
                    }) {
                        Label("Scope To All Computers & Users", systemImage: "plus.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)

                    Button(action: {
                        // Clear scope for selected policies via parent's closure
                        onClearExclusions()
                    }) {
                        Label("Clear Scope", systemImage: "eraser")
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                }

                Divider()

                Text("Scope to Group").fontWeight(.bold)

                // Static groups
                LazyVGrid(columns: layout.columns, spacing: 10) {
                    Picker(selection: $computerGroupSelection, label: Label("Static Groups", systemImage: "person.3")) {
                        Text("No group selected").tag(nil as ComputerGroup?)
                        ForEach(networkController.allComputerGroups.filter({computerGroupFilter == "" ? true : $0.name.contains(computerGroupFilter)}), id: \.self) { group in
                            if group.isSmart != true {
                                Text(group.name).tag(group as ComputerGroup?)
                            }
                        }
                    }

                    Button(action: {
                        progress.showProgress()
                        progress.waitForABit()
                        if let group = computerGroupSelection {
                            onUpdateScopeCompGroupSet(group, "false", allComputersStaticEnable)
                        }
                    }) {
                        Label("Update", systemImage: "plus.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }

                // Smart groups
                LazyVGrid(columns: layout.columns, spacing: 10) {
                    Picker(selection: $computerGroupSelection, label: Label("Smart Groups", systemImage: "person.3")) {
                        Text("No group selected").tag(nil as ComputerGroup?)
                        ForEach(networkController.allComputerGroups.filter({computerGroupFilter == "" ? true : $0.name.contains(computerGroupFilter)}), id: \.self) { group in
                            if group.isSmart == true {
                                Text(group.name).tag(group as ComputerGroup?)
                            }
                        }
                    }

                    Button(action: {
                        progress.showProgress()
                        progress.waitForABit()
                        if let group = computerGroupSelection {
                            onUpdateScopeCompGroupSet(group, "true", allComputersSmartEnable)
                        }
                    }) {
                        Label("Update", systemImage: "plus.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }

                // LDAP limitations
                Divider()
                Text("Limitations").fontWeight(.bold)
                Picker(selection: $ldapSearchCustomGroupSelection, label: Text("Limitations:")) {
                    ForEach(scopingController.allLdapCustomGroupsCombinedArray, id: \.self) { group in
                        Text(group.name).tag(group as LDAPCustomGroup?)
                    }
                }

                HStack(spacing: 10) {
                    Button(action: {
                        progress.showProgress()
                        progress.waitForABit()
                        for eachItem in policiesSelection {
                            let currentPolicyID = String(describing: eachItem.jamfId ?? 0)
                            onUpdatePolicyScopeLimitationsAuto(ldapSearchCustomGroupSelection, currentPolicyID)
                        }
                    }) {
                        Label("Add", systemImage: "plus.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)

                    Button(action: {
                        progress.showProgress()
                        progress.waitForABit()
                        for eachItem in policiesSelection {
                            let currentPolicyID = String(describing: eachItem.jamfId ?? 0)
                            onClearLimitations(currentPolicyID)
                        }
                    }) {
                        Label("Clear Limitations", systemImage: "minus.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }

                // LDAP search
                LazyVGrid(columns: layout.threeColumns, spacing: 20) {
                    HStack {
                        Text("Search Ldap")
                        TextField("", text: $ldapSearch)
                    }
                    Button(action: {
                        progress.showProgress()
                        progress.waitForABit()
                        Task { try await scopingController.getLdapGroupsSearch(server: server, search: ldapSearch, authToken: networkController.authToken) }
                    }) {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }

                // LDAP servers
                LazyVGrid(columns: layout.threeColumns, spacing: 20) {
                    Picker(selection: $ldapServerSelection, label: Text("Ldap Servers:").bold()) {
                        Text("No server selected").tag(nil as LDAPServer?)
                        ForEach(scopingController.allLdapServers, id: \.self) { srv in
                            Text(srv.name).tag(srv as LDAPServer?)
                        }
                    }
                }

                // Exclusions
                Divider()
                Text("Exclusions").fontWeight(.bold)
                Button(action: {
                    progress.showProgressView = true
                    onClearExclusions()
                }) {
                    Text("Clear Exclusions")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)

                Spacer()
            }
            .padding()
        }
    }
}

struct PoliciesActionPackagesTab: View {
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var layout: Layout
    @EnvironmentObject var progress: Progress
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Policies Action - Packages")
                .font(.headline)
            Text("Manage package assignments for selected policies.")
                .font(.subheadline)
            Divider()
            HStack {
                Button("Add Package") {
                    progress.showProgress()
                    progress.waitForABit()
                }
                .buttonStyle(.borderedProminent)
                Button("Remove Package") {
                    progress.showProgress()
                    progress.waitForABit()
                }
                .buttonStyle(.bordered)
            }
            Spacer()
        }
        .padding()
    }
}
