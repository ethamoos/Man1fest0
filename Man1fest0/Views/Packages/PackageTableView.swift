//
//  PackageTableView.swift
//  Man1fest0
//
//  Created by Amos Deane on 23/01/2025.
//




import SwiftUI

struct PackageTableView: View {
    
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var scopingController: ScopingBrain
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var layout: Layout
    
    var server: String

    //  ########################################################################################
    //  BOOLS
    //  ########################################################################################

    @State var status: Bool = true
    @State private var showingWarning = false
    @State var enableDisable: Bool = true
    
    //    @State var ldapUserGroupName = ""
    //    @State var ldapUserGroupId = ""
    
    //  ########################################################################################
    //    Category SELECTION
    //  ########################################################################################
    
    @State var categories: [Category] = []
    @State  var categorySelection: Category = Category(jamfId: 0, name: "")
    //  ########################################################################################
    //    POLICY SELECTION
    //  ########################################################################################
    
    @State private var selectedPolicyIDs = Set<General.ID>()
    @State private var selectedPolicyjamfIDs = Set<General>()
    @State private var selectedIDs = []
    @State private var sortOrder = [KeyPathComparator(\General.name, order: .reverse)]
    @State private var policiesSelection = Set<Policy>()
    @State var searchText = ""
    
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
    
    //  ########################################################################################
    //  SELECTIONS
    //  ########################################################################################
    
    @State var computerGroupSelection = ComputerGroup(id: 0, name: "", isSmart: false)
    
    var body: some View {
        
        
        Table(searchResults, selection: $selectedPolicyIDs, sortOrder: $sortOrder) {
            
            TableColumn("Name", value: \.name!) {
                policy in
                Text(String(policy.name ?? ""))
            }
            
            TableColumn("Category", value: \.category!.name)
            
            TableColumn("Enabled") {
                policy in
                Text(String(policy.enabled ?? false))
            }
            
            TableColumn("ID", value: \.jamfId!) {
                policy in
                Text(String(policy.jamfId ?? 0))
            }
            TableColumn("Trigger", value: \.triggerOther!) {
                policy in
                Text(String(policy.triggerOther ?? ""))
            }
        }
        
        
        
        
            
//        Table(searchResults, selection: $selectedPolicyIDs, sortOrder: $sortOrder) {
//            
//            TableColumn("Name", value: \.name!) {
//                policy in
//                Text(String(policy.name ?? ""))
//            }
//            
//            TableColumn("Category", value: \.category!.name)
//            
//            TableColumn("Enabled") {
//                policy in
//                Text(String(policy.enabled ?? false))
//            }
//            
//            TableColumn("ID", value: \.jamfId!) {
//                policy in
//                Text(String(policy.jamfId ?? 0))
//            }
//            TableColumn("Trigger", value: \.triggerOther!) {
//                policy in
//                Text(String(policy.triggerOther ?? ""))
//            }
//        }
//        .searchable(text: $searchText)
//        .onChange(of: sortOrder) { newOrder in
//            networkController.allPoliciesDetailedGeneral.sort(using: newOrder)
//        }
//        .toolbar {
//            
//            VStack(alignment: .leading, spacing: 5) {
//                
//                HStack {
//                    Button(action: {
//                        
//                        print("convertToallPoliciesDetailedGeneral")
//                        Task {
//                            await refreshDetailedPolicySelections(selectedPolicies: selectedPoliciesInt, authToken: networkController.authToken, server: server)
//                        }
//                        progress.showProgress()
//                        progress.waitForABit()
//                    }) {
//                        Image(systemName: "arrow.clockwise")
//                        Text("Refresh")
//                    }
//                    .buttonStyle(.borderedProminent)
//                 
//                    Button(action: {
//                        progress.showProgress()
//                        progress.waitForABit()
//                        print("Clearing allPoliciesDetailed")
//                        networkController.allPoliciesDetailed.removeAll()
//                        print("Fetching allPoliciesDetailed")
//                        networkController.getAllPoliciesDetailed(server: server, authToken: networkController.authToken, policies: networkController.allPoliciesConverted)
//                        convertToallPoliciesDetailedGeneral()
//                    }) {
//                        Image(systemName: "arrow.clockwise")
//                        Text("Reset")
//                    }
//                }
//            }
//        }
        
    
    
    
    
        //              ################################################################################
        //              DELETE
        //              ################################################################################
        
    VStack(alignment: .leading) {
            Divider()
            HStack(spacing: 20) {
                Button(action: {
                    showingWarning = true
                    progress.showProgressView = true
                    print("Set showProgressView to true")
                    print(progress.showProgressView)
                    progress.waitForABit()
                    print("Check processingComplete")
                    print(String(describing: networkController.processingComplete))
//                    networkController.processDeletePoliciesGeneral(selection: selectedPoliciesInt, server: server,  authToken: networkController.authToken, resourceType: ResourceType.policies)
                }) {
                    Text("Delete")
                }
                .alert(isPresented: $showingWarning) {
                    Alert(title: Text("Caution!"), message: Text("This action will delete data.\n Always ensure that you have a backup!"), dismissButton: .default(Text("I understand!")))
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .shadow(color: .gray, radius: 2, x: 0, y: 2)
                
                //              ################################################################################
                //              Update Category
                //              ################################################################################
                
//                Button(action: {
//                    progress.showProgressView = true
//                    networkController.processingComplete = false
//                    progress.waitForABit()
//                    print("Setting category to:\(String(describing: categorySelection))")
//                    print("Policy enable/disable status is set as:\(String(describing: enableDisable))")
//                    networkController.selectedCategory = categorySelection
//                    networkController.processUpdatePoliciesCombined(selection: selectedPoliciesInt, server: server, resourceType: ResourceType.policies, enableDisable: enableDisable, authToken: networkController.authToken)
//                }) {
//                    Text("Update")
//                }
//                .buttonStyle(.borderedProminent)
//                .tint(.blue)
//                
//                //  ################################################################################
//                //  Enable or Disable Policies Toggle
//                //  ################################################################################
//                
//                Toggle("", isOn: $enableDisable)
//                    .toggleStyle(SwitchToggleStyle(tint: .red))
//                if enableDisable {
//                    Text("Enabled")
//                } else {
//                    Text("Disabled")
//                }
                
                //              ################################################################################
                //              DOWNLOAD OPTION
                //              ################################################################################
                
//                Button(action: {
//                    
//                    progress.showProgress()
//                    progress.waitForABit()
//                    
//                    for eachItem in selectedPoliciesInt {
//                        
//                        let currentPolicyID = (eachItem ?? 0)
//                        
////                        print("Download file for \(eachItem.name)")
//                        print("jamfId is \(String(describing: eachItem ?? 0))")
//                        
//                        ASyncFileDownloader.downloadFileAsyncAuth( objectID: currentPolicyID, resourceType: ResourceType.policies, server: server, authToken: networkController.authToken) { (path, error) in}
//                    }
//                    
//                }) {
//                    Image(systemName: "plus.square.fill.on.square.fill")
//                    Text("Download")
//                }
//                .buttonStyle(.borderedProminent)
//                .tint(.yellow)
                
                VStack {
                    
                    ShareLink(item:generateCSV()) {
                        Label("Export CSV", systemImage: "list.bullet.rectangle.portrait")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.yellow)
                    .shadow(color: .gray, radius: 2, x: 0, y: 2)

                }
            }
            
            //              ################################################################################
            //              Clear Scope
            //              ################################################################################
            
            Divider()
            
//            Button(action: {
//                
//                progress.showProgress()
//                progress.waitForABit()
//                
//                for eachItem in selectedPoliciesInt {
//                    
//                    let currentPolicyID = (String(describing: eachItem ?? 0))
//                    networkController.clearScope(server: server,resourceType:  ResourceType.policies, policyID: currentPolicyID, authToken: networkController.authToken)
//                    print("Clear Scope for policy:\(eachItem ?? 0)")
//                }
//                
//            }) {
//                HStack(spacing: 10) {
//                    Image(systemName: "arrow.clockwise")
//                    Text("Clear Scope")
//                }
//            }
//            .buttonStyle(.borderedProminent)
//            .tint(.red)
//            .alert(isPresented: $showingWarning) {
//                Alert(title: Text("Caution!"), message: Text("This action will clear devices from the policy scoping.\n You will need to rescope in order to deploy"), dismissButton: .default(Text("I understand!")))
//            }
//            
            //              ################################################################################
            //              Category
            //              ################################################################################
            
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 300)), GridItem(.flexible(minimum: 200))], spacing: 20) {
                
                HStack {
                    Picker(selection: $categorySelection, label: Text("Category:\t\t")) {
                        Text("").tag("") //basically added empty tag and it solve the case
                        ForEach(networkController.categories, id: \.self) { category in
                            Text(String(describing: category.name))
                        }
                    }
                    
                    Button(action: {
                        
                        progress.showProgress()
                        progress.waitForABit()
                        networkController.connect(server: server,resourceType:  ResourceType.policies, authToken: networkController.authToken)
                        //                            getDetailedPolicies(policiesSelection: policiesSelection)
                        print("Refresh")
                        
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
            }
            
            //  ################################################################################
            //  UPDATE POLICY - COMPLETE
            //  ################################################################################
            
            Divider()
//            VStack(alignment: .leading) {
//
//                Text("Selections").fontWeight(.bold)
//
//                List(Array(policiesSelection), id: \.self) { policy in
//
//                    Text(policy.name )
//
//                }
//                .frame(height: 50)
//            }
            
            //  ################################################################################
            //  Set Scoping - Group
            //  ################################################################################
            
            Group {
                
                //  ################################################################################
                //  Group picker
                //  ################################################################################

                
                LazyVGrid(columns: layout.threeColumns, spacing: 20) {
                    Picker(selection: $computerGroupSelection, label:Label("Groups", systemImage: "person.3")
                    ) {
//                        Text("").tag("")
                        ForEach(networkController.allComputerGroups.filter({computerGroupFilter == "" ? true : $0.name.contains(computerGroupFilter)}) , id: \.self) { group in
                            Text(String(describing: group.name))
                                .tag(group as ComputerGroup?)
                        }
                    }
                    
    //  ################################################################################
    //  Update groups
    //  ################################################################################
    
//                    Button(action: {
//                        progress.showProgress()
//                        progress.waitForABit()
//                        for eachItem in selectedPoliciesInt {
//                            print("Updating for \(String(describing: eachItem ?? 0))")
//                            let currentPolicyID = (eachItem ?? 0)
//                            Task {
//                                do {
//                                    let policyAsXML = try await networkController.getPolicyAsXMLaSync(server: server, policyID: currentPolicyID, authToken: networkController.authToken)
//                                    scopingController.updateScopeCompGroupSetAsyncSingle(groupSelection: computerGroupSelection,authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policyID: String(describing:currentPolicyID), policyAsXML: policyAsXML)
//                                } catch {
//                                    print("Fetching detailed policy as xml failed: \(error)")
//                                }
//                            }
//                        }
//                    }) {
//                        Image(systemName: "plus.square.fill.on.square.fill")
//                        Text("Update Groups")
//                    }
//                    .buttonStyle(.borderedProminent)
//                    .tint(.blue)
                }
            }
            
            //  ################################################################################
            //  LDAP SEARCH RESULTS - Picker 1
            //  ################################################################################
            
            Divider()
            
            VStack(alignment: .leading) {

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 300)), GridItem(.flexible(minimum: 200)), GridItem(.flexible(minimum: 200))], spacing: 20) {

                    HStack(spacing:20 ){
                        Picker(selection: $ldapSearchCustomGroupSelection, label: Text("Search Results:").bold()) {
                            //                        Text("").tag("") //basically added empty tag and it solve the case
                            ForEach(scopingController.allLdapCustomGroupsCombinedArray, id: \.self) { group in
                                Text(String(describing: group.name))
                                    .tag(ldapSearchCustomGroupSelection as LDAPCustomGroup?)
                            }
                        }
                        
                        //  ################################################################################
                        //  Limitations
                        //  ################################################################################
                        
//                        Button(action: {
//                            print("Limitations pressed")
//                            progress.showProgress()
//                            progress.waitForABit()
//                            for eachItem in selectedPoliciesInt {
//                                
//                                print("Updating for \(String(describing: eachItem))")
//                                scopingController.updatePolicyScopeLimitationsAuto(groupSelection: ldapSearchCustomGroupSelection, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policyID: String(describing: eachItem))
//                            }
//                        }) {
////                            Image(systemName: "plus.square.fill.on.square.fill")
//                            Text("Limitations")
//                        }
//                        .buttonStyle(.borderedProminent)
//                        .tint(.blue)
                        
                        //  ################################################################################
                        //  Clear Limitations
                        //  ################################################################################
                        
//                        Button(action: {
//                            progress.showProgress()
//                            progress.waitForABit()
//                            print("Pressing clear limitations")
//                            for eachItem in selectedPoliciesInt {
//                                print("Updating for \(String(describing: eachItem ?? 0))")
//                                let currentPolicyID = (eachItem ?? 0)
//                                
//                                Task {
//                                    do {
//                                        let policyAsXML = try await networkController.getPolicyAsXMLaSync(server: server, policyID: currentPolicyID, authToken: networkController.authToken)
//                                        
//                                        scopingController.updatePolicyScopeLimitAutoRemove(authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policyID: String(describing:currentPolicyID), currentPolicyAsXML: policyAsXML)
//                                        
//                                    } catch {
//                                        print("Fetching detailed policy as xml failed: \(error)")
//                                    }
//                                }
//                            }
//                        }) {
////                            Image(systemName: "plus.square.fill.on.square.fill")
//                            Text("Clear")
//                        }
//                        .buttonStyle(.borderedProminent)
//                        .tint(.red)
                    }
                }
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
//                    Text("").tag("") //basically added empty tag and it solve the case
                    ForEach(scopingController.allLdapServers, id: \.self) { group in
                        Text(String(describing: group.name))
                            .tag(ldapServerSelection as LDAPServer?)
                    }
                }
            }
        }
        
        //  ################################################################################
        //  END
        //  ################################################################################
                
        .onAppear() {
            
            print("Getting primary data")
            fetchData()
            
        }
        .padding()
        
        
        if progress.showProgressView == true {
            
            ProgressView {
                Text("Loading")
                    .font(.title)
                    .progressViewStyle(.horizontal)
            }
            .padding()
            Spacer()
        }
    }
    
    func convertToallPoliciesDetailedGeneral() {
        
        print("Reset allPoliciesDetailedGeneral and re-add")
        
        networkController.allPoliciesDetailedGeneral.removeAll()
        
        if networkController.allPoliciesDetailed.isEmpty != true {
            for eachPolicy in networkController.allPoliciesDetailed {
                if let eachPolicyGeneral = eachPolicy?.general {
                    networkController.allPoliciesDetailedGeneral.insert((eachPolicyGeneral), at: 0)
                }
            }
        }
    }
    
    func refreshDetailedPolicySelections(selectedPolicies: [Int?], authToken: String, server: String) async {
        
        if selectedPolicies.isEmpty {
            print("no selection")
            convertToallPoliciesDetailedGeneral()
        } else {
            print("refreshing detailed policy selections")
            for eachPolicy in selectedPolicies {
                Task {
                    try await networkController.getDetailedPolicy(server: server, authToken: authToken, policyID: String(describing: eachPolicy))
                }
            }
            convertToallPoliciesDetailedGeneral()
        }
    }
    
    
//  #################################################################################
//  Master Fetch function
//  #################################################################################

    
    func fetchData() {
        
        if  networkController.categories.isEmpty {
            print("No category data - fetching")
            networkController.connect(server: server,resourceType: ResourceType.category, authToken: networkController.authToken)
            
        } else {
            print("category data is available")
        }
        
        if  networkController.packages.isEmpty {
            print("No package data - fetching")
            networkController.connect(server: server,resourceType: ResourceType.packages, authToken: networkController.authToken)
            
        } else {
            print("package data is available")
        }
        
        if  networkController.policies.isEmpty {
            print("No policies data - fetching")
            networkController.connect(server: server,resourceType: ResourceType.policies, authToken: networkController.authToken)
            
        } else {
            print("policies data is available")
        }
        
        if  networkController.allComputerGroups.isEmpty {
            print("No groups data - fetching")
            Task {
                try await networkController.getAllGroups(server: server, authToken: networkController.authToken)
            }
        } else {
            print("groups data is available")
        }
        
        if networkController.fetchedDetailedPolicies == false {
            
            print("fetchedDetailedPolicies is set to false - running getAllPoliciesDetailed")
            
            if networkController.allPoliciesDetailed.count < networkController.allPoliciesConverted.count {
                
                print("fetching detailed policies")
                
                progress.showProgress()
                
                networkController.getAllPoliciesDetailed(server: server, authToken: networkController.authToken, policies: networkController.allPoliciesConverted)
                
                convertToallPoliciesDetailedGeneral()
            
                progress.waitForABit()
                
                networkController.fetchedDetailedPolicies = true
                
            } else {
                print("Download complete")
            }
        } else {
            print("fetchedDetailedPolicies has run")
        }
    }
    
    
    
    func generateCSV() -> URL {
        
        let myData: [General] =  networkController.allPoliciesDetailedGeneral

        
        var fileURL: URL!
        // heading of CSV file.
        let heading = "Name, Category, Status, ID, Trigger\n"
        
        // file rows
        let rows = myData.map { "\(String(describing: $0.name ?? "")),\($0.category!.name),\(String(describing: $0.enabled ?? false )),\($0.jamfId!),\($0.triggerOther!)" }
        
        // rows to string data
        let stringData = heading + rows.joined(separator: "\n")
        
        do {
            
            let path = try FileManager.default.url(for: .documentDirectory,
                                                   in: .allDomainsMask,
                                                   appropriateFor: nil,
                                                   create: false)
            
            fileURL = path.appendingPathComponent("Policy-Data.csv")
            
            // append string data to file
            try stringData.write(to: fileURL, atomically: true , encoding: .utf8)
            print(fileURL!)
            
        } catch {
            print("error generating csv file")
        }
        return fileURL
    }
    
 
    var searchResults: [General] {
                
        if searchText.isEmpty {
            return networkController.allPoliciesDetailedGeneral
        } else {
            return networkController.allPoliciesDetailedGeneral.filter { $0.name!.lowercased().contains(searchText.lowercased())}
        }
    }
}



//struct PolicyDetailTableView_Previews: PreviewProvider {
//    static var previews: some View {
//        PolicyDetailTableView(server: "")
//            .environmentObject (NetBrain())
//            .environmentObject (Progress())
//            .environmentObject (Layout())
//            .environmentObject (ScopingBrain())
//    }
//}
