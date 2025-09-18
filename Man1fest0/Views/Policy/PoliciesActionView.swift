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
    
    @State  var categorySelection: Category = Category(jamfId: 0, name: "")
    
    @State var enableDisable: Bool = true
    
    //    @State var ldapUserGroupName = ""
    //
    //    @State var ldapUserGroupId = ""
    
    
    //  ########################################################################################
    //    POLICY SELECTION
    //  ########################################################################################
    
    
    @State private var policiesSelection = Set<Policy>()
    
    @State var searchText = ""
    
    @State var status: Bool = true
    
    @State private var showingWarning = false
    
    
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
    
    @State var ldapServerSelection: LDAPServer = LDAPServer(id: 0, name: "")
    
    @State var ldapSearchCustomGroupSelection = LDAPCustomGroup(uuid: "", ldapServerID: 0, id: "", name: "", distinguishedName: "")
    @State var ldapSearchCustomGroupSelection2 = LDAPCustomGroup(uuid: "", ldapServerID: 0, id: "", name: "", distinguishedName: "")
    
    @State var getDetailedPolicyHasRun = false
    @State var ldapSearch = ""
    
    //    ########################################################################################
    //    SELECTIONS
    //    ########################################################################################
    
    @State var computerGroupSelection = ComputerGroup(id: 0, name: "", isSmart: false)
    
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
                
                List(searchResults, id: \.self, selection: $policiesSelection) { policy in
                    
                    HStack {
                        Image(systemName:"text.justify")
                        Text("\(policy.name)")
                    }
                    .foregroundColor(.blue)
                }
                .searchable(text: $searchText)
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
                    //                    .shadow(color: .gray, radius: 2, x: 0, y: 2)
                }
                
                
                //              ################################################################################
                //              BUTTONS  -   Delete, Update, Disable & Download
                //              ################################################################################
                
                
                //              ################################################################################
                //              DELETE
                //              ################################################################################
                
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
                            print("Setting category to:\(String(describing: categorySelection))")
                            print("Policy enable/disable status is set as:\(String(describing: enableDisable))")
                            
                            networkController.selectedCategory = categorySelection
                            networkController.processUpdatePolicies(selection: policiesSelection, server: server, resourceType: ResourceType.policies, enableDisable: enableDisable, authToken: networkController.authToken)
                            
                        }) {
                            Text("Update")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        
                        
                        //  ################################################################################
                        //  Enable or Disable Policies Toggle
                        //  ################################################################################
                        
                        HStack {
                            
                            Toggle("", isOn: $enableDisable)
                                .toggleStyle(SwitchToggleStyle(tint: .red))
                            if enableDisable {
                                Text("Enabled")
                            } else {
                                Text("Disabled")
                            }
                        }
                        
                        //  ################################################################################
                        //              DOWNLOAD OPTION
                        //  ################################################################################
                        
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
                            Image(systemName: "plus.square.fill.on.square.fill")
                            Text("Download")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.yellow)
                        .shadow(color: .gray, radius: 2, x: 0, y: 2)

                    }
                    
                    //  ################################################################################
                    //              Category
                    //  ################################################################################
                    
                    Divider()
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 300)), GridItem(.flexible(minimum: 200))], spacing: 20) {
                        
                        HStack {
                            Picker(selection: $categorySelection, label: Text("Category:\t\t")) {
                                Text("").tag("") //basically added empty tag and it solve the case
                                ForEach(networkController.categories, id: \.self) { category in
                                    Text(String(describing: category.name))
                                }
                            }
                            
                            
                        }
                    }
                    
                    //  ################################################################################
                    //              UPDATE POLICY - COMPLETE
                    //  ################################################################################
                    
                    Divider()
                    VStack(alignment: .leading) {
                        
                        Text("Selections").fontWeight(.bold)
                        
                        List(Array(policiesSelection), id: \.self) { policy in
                            
                            Text(policy.name )
                            
                        }
                        .frame(height: 50)
                    }
                    
                    
                    //  ################################################################################
                    //  Set Scoping - Group
                    //  ################################################################################
                    
                    Group {
                        
                        //  ################################################################################
                        //  Group picker
                        //  ################################################################################
                        
                        //                        Divider()
                        
                        //  ################################################################################
                        //  add selected groups
                        //  ################################################################################
                        
                        Divider()
                        Text("Scoping").fontWeight(.bold)
                        
                        
                        Divider()

                        //  ################################################################################
                        //            Batch Scope All users and computers
                        //  ################################################################################
                                             
                        HStack {
                            Button(action: {
                                progress.showProgress()
                                progress.waitForABit()
                                networkController.batchScopeAllComputers(policiesSelection:policiesSelection, server: server, authToken: networkController.authToken)
                            }) {
                                Image(systemName: "plus.square.fill.on.square.fill")
                                Text("Scope To All Computers")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            
                            Button(action: {
                                progress.showProgress()
                                progress.waitForABit()
                                networkController.batchScopeAllUsers(policiesSelection: policiesSelection, server: server, authToken: networkController.authToken)
                            }) {
                                Image(systemName: "plus.square.fill.on.square.fill")
                                Text("Scope To All Users")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            
                            Button(action: {
                                progress.showProgress()
                                progress.waitForABit()
                                networkController.batchScopeAllUsers(policiesSelection: policiesSelection, server: server, authToken: networkController.authToken)
                                networkController.batchScopeAllComputers(policiesSelection: policiesSelection, server: server, authToken: networkController.authToken)
                            }) {
                                Image(systemName: "plus.square.fill.on.square.fill")
                                Text("Scope To All Computers & Users")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                        }
                        
                        LazyVGrid(columns: layout.fourColumns, spacing: 10) {
                            Picker(selection: $computerGroupSelection, label:Label("Static Groups", systemImage: "person.3")
                            ) {
                                Text("").tag("")
                                ForEach(networkController.allComputerGroups.filter({computerGroupFilter == "" ? true : $0.name.contains(computerGroupFilter)}) , id: \.self) { group in
                                    if group.isSmart != true {
                                        Text(String(describing: group.name))
                                    }
                                }
                            }
                            
                            Toggle(isOn: $allComputersStaticEnable) {
                                Text("All Computers")
                            }
                            .toggleStyle(.checkbox)
                            
                            
                            Button(action: {
                                
                                progress.showProgress()
                                progress.waitForABit()

//            ################################################################################
//            GROUPS - STATIC
//            ################################################################################
                              
                                Task {
                                    await updateScopeCompGroupSet(groupSelection: computerGroupSelection, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policiesSelection: policiesSelection, smartStatus: "true", all_computersStatus: allComputersStaticEnable)
                                }
                                
                            }) {
                                Image(systemName: "plus.square.fill.on.square.fill")
                                Text("Update")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                        }
                        
                        LazyVGrid(columns: layout.fourColumns, spacing: 10) {
                            
                            Picker(selection: $computerGroupSelection, label:Label("Smart Groups", systemImage: "person.3")
                            ) {
                                Text("").tag("")
                                ForEach(networkController.allComputerGroups.filter({computerGroupFilter == "" ? true : $0.name.contains(computerGroupFilter)}) , id: \.self) { group in
                                    if group.isSmart == true {
                                        Text(String(describing: group.name))
                                    }
                                }
                            }
                            
                            Toggle(isOn: $allComputersSmartEnable) {
                                Text("All Computers")
                            }
                            .toggleStyle(.checkbox)
                            
                            Button(action: {
                                
                                progress.showProgress()
                                progress.waitForABit()
                            
//            ################################################################################
//            GROUPS - SMART
//            ################################################################################
                                
                                Task {
                                    await updateScopeCompGroupSet(groupSelection: computerGroupSelection, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policiesSelection: policiesSelection, smartStatus: "true", all_computersStatus: allComputersSmartEnable)
                                }
                                
                            }) {
                                Image(systemName: "plus.square.fill.on.square.fill")
                                Text("Update")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                            
                        }
                    }
                    
                    //  ################################################################################
                    //  LDAP SEARCH RESULTS - Picker 1
                    //  ################################################################################
                    
                    Divider()
                    LazyVGrid(columns: layout.fourColumns, spacing: 10) {
                        //                                            TextField("Filter", text: $allLdapServersFilter)
                        Picker(selection: $ldapSearchCustomGroupSelection, label: Text("Select Limitations:").bold()) {
                            //                            Text("").tag("") //basically added empty tag and it solve the case
                            ForEach(scopingController.allLdapCustomGroupsCombinedArray, id: \.self) { group in
                                Text(String(describing: group.name))
                                    .tag(group as LDAPCustomGroup?)
                            }
                        }
                        
                        //            ################################################################################
                        //            Limitations - Set
                        //            ################################################################################
                        
                        HStack(spacing:10) {
                            
                            Button(action: {
                                progress.showProgress()
                                progress.waitForABit()
                                
                                for eachItem in policiesSelection {
                                    
                                    let currentPolicyID = (eachItem.jamfId ?? 0)
                                    layout.separationLine()
                                    print("Button pressed")
                                    print("Updating for \(eachItem.name)")
                                    print("currentPolicyID is: \(currentPolicyID)")
                                    print("jamfId is \(String(describing: eachItem.jamfId ?? 0))")
                                    
                                    Task {
                                        await self.updatePolicyScopeLimitationsAuto(groupSelection: ldapSearchCustomGroupSelection, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policyID: String(describing:currentPolicyID))
                                    }
                                }
                            }) {
                                Image(systemName: "plus.circle")
                                Text("Add")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        
                        //            ################################################################################
                        //            Limitations - Clear
                        //            ################################################################################
                        
                        //                    LazyVGrid(columns: layout.threeColumns, spacing: 20) {
                        
                        Button(action: {
                            
                            progress.showProgress()
                            progress.waitForABit()
                            
                            
                            for eachItem in policiesSelection {
                                
                                let currentPolicyID = (eachItem.jamfId ?? 0)
                                
                                layout.separationLine()
                                print("Button pressed")
                                print("Updating for \(eachItem.name)")
                                print("currentPolicyID is: \(currentPolicyID)")
                                print("jamfId is \(String(describing: eachItem.jamfId ?? 0))")
                                
                                
                                Task {
                                    do {
                                        let policyAsXML = try await xmlController.getPolicyAsXMLaSync(server: server, policyID: Int(currentPolicyID), authToken: networkController.authToken)
                                        
                                        xmlController.updatePolicyScopeLimitAutoRemove(authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policyID: String(describing:currentPolicyID), currentPolicyAsXML: policyAsXML)
                                    }
                                }
                                print("Test")
                            }
                        }) {
                            Image(systemName: "minus.circle")
                            Text("Clear")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        
                    }
                           
//  ################################################################################
//  Select Ldap group
//  ################################################################################
                    
                    LazyVGrid(columns: layout.threeColumns, spacing: 20) {
                        
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
                    
                    LazyVGrid(columns: layout.threeColumns, spacing: 20) {
                        Picker(selection: $ldapServerSelection, label: Text("Ldap Servers:").bold()) {
                            Text("").tag("") //basically added empty tag and it solve the case
                            ForEach(scopingController.allLdapServers, id: \.self) { group in
                                Text(String(describing: group.name))
                            }
                        }
                    }
//  ################################################################################
//  END
//  ################################################################################
                    
                    LazyVGrid(columns: columns) {
                    }
                }
                .padding()
                
                if progress.showProgressView == true {
                    
                    ProgressView {
                        Text("Processing")
                            .padding()
                    }
                } else {
                    Text("")
                }
                
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
