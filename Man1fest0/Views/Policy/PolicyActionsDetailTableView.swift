//
//  PolicyActionsDetailTableView.swift
//  Man1fest0
//
//  Created by Amos Deane on 30/08/2024.
//

import SwiftUI

struct PolicyActionsDetailTableView: View {
    
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var scopingController: ScopingBrain
    @EnvironmentObject var xmlController: XmlBrain
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var layout: Layout
    
    var server: String
    
    //  ########################################################################################
    //  BOOLS
    //  ########################################################################################
    
    @State var status: Bool = true
    @State private var showingWarning = false
    @State private var showingWarningDelete = false
    @State var enableDisable: Bool = true
    
    //  ########################################################################################
    //    POLICY SELECTION
    //  ########################################################################################
    
    @State private var selectedPolicyIDs = Set<General.ID>()
    @State private var selectedPolicyjamfIDs = Set<General>()
    @State private var selectedIDs = []
    @State private var policiesSelection = Set<Policy>()
    @State var searchText = ""


    
    //  ########################################################################################
    //  SELECTIONS
    //  ########################################################################################
    
    @State var computerGroupSelection = ComputerGroup(id: 0, name: "", isSmart: false)
    
    @State var iconMultiSelection = Set<String>()
    
    @State var selectedIconString = ""
    
    @State var selectedIcon: Icon? = Icon(id: 0, url: "", name: "")
    
    @State var selectedIconList: Icon = Icon(id: 0, url: "", name: "")
    
    @State private var isAscending = true
    
    @State private var sortOrder: [KeyPathComparator<General>] = [
        KeyPathComparator(\General.nameForSort, order: .forward),
        KeyPathComparator(\General.categoryNameForSort, order: .forward),
        KeyPathComparator(\General.enabledInt, order: .forward), // Use Int for sorting
        KeyPathComparator(\General.jamfIdForSort, order: .forward),
        KeyPathComparator(\General.triggerOtherForSort, order: .forward)
    ]

    
    var body: some View {
        
        //  ########################################################################################
        //  This variable is a mapping of the ID to the jamfId property in the selection so that although you select the id you actually return the jamfID - meaning that you can do stuff with this
        
        //  networkController.allPoliciesDetailedGeneral is the list of policies that is being selected from that we want to access properties
        
        //  selectedPolicyIDs is a set (as the selection can be multiplw) this by default is populated by the ID only
        
        //  selectedPoliciesInt is an array of the jamf ids from the mapping
        
        let filteredPolicies = networkController.allPoliciesDetailedGeneral.filter { selectedPolicyIDs.contains($0.id) }
        
        // Move selectedPoliciesInt logic to a computed property
        var selectedPoliciesInt: [Int?] {
            networkController.allPoliciesDetailedGeneral.filter { selectedPolicyIDs.contains($0.id) }.map { $0.jamfId }
        }
        
        LazyVGrid(columns: layout.fiveColumns, spacing: 5) {
            
            VStack(alignment: .leading, spacing: 5) {
                
                Text("Total Policies:\t\(networkController.allPoliciesConverted.count)")
                    .fontWeight(.bold)
                
                Text("Policies fetched:\t\(networkController.allPoliciesDetailed.count)")
                    .fontWeight(.bold)
            }
            .padding(.top, 8)
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .padding(Edge.Set.vertical, 20)
        }
        
        
        Table(searchResults, selection: $selectedPolicyIDs, sortOrder: $sortOrder) {
            TableColumn("Name", value: \ .nameForSort) { policy in
                let name = policy.name ?? ""
                Text(name)
                    .textSelection(.enabled)
            }
            TableColumn("Category", value: \ .categoryNameForSort) { policy in
                let category = policy.category?.name ?? ""
                Text(category)
                    .textSelection(.enabled)
            }
            TableColumn("Enabled", value: \ .enabledInt) { policy in
                let enabledText = policy.enabled == true ? "true" : "false"
                Text(enabledText)
            }
            TableColumn("ID", value: \ .jamfIdForSort) { policy in
                let idText = String(policy.jamfId ?? 0)
                Text(idText)
                    .textSelection(.enabled)
            }
            TableColumn("Trigger", value: \ .triggerOtherForSort) { policy in
                let triggerText = policy.triggerOther ?? ""
                Text(triggerText)
                    .textSelection(.enabled)
            }
        }
        .searchable(text: $searchText)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button(action: {
                    print("convertToallPoliciesDetailedGeneral")
                    progress.showProgress()
                    progress.waitForABit()
                    Task {
                        await refreshDetailedPolicySelections(selectedPolicies: selectedPoliciesInt, authToken: networkController.authToken, server: server)
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: {
                    progress.showProgress()
                    progress.waitForABit()
                    print("Clearing allPoliciesDetailed")
                    networkController.allPoliciesDetailed.removeAll()
                    print("Fetching allPoliciesDetailed")
                    Task {
                        try await networkController.getAllPoliciesDetailed(server: server, authToken: networkController.authToken, policies: networkController.allPoliciesConverted)
                    }
                    convertToallPoliciesDetailedGeneral()
                }) {
                    Image(systemName: "arrow.clockwise")
                    Text("Reset")
                }
                .buttonStyle(.bordered)
                
                Button(action: {
                    let selectedRows = networkController.allPoliciesDetailedGeneral.filter { selectedPolicyIDs.contains($0.id) }
                    let rowsString = selectedRows.map { policy in
                        let name = String(policy.name ?? "")
                        let category = policy.category?.name ?? ""
                        let enabled = String(policy.enabled ?? true)
                        let jamfId = String(policy.jamfId ?? 0)
                        let triggerOther = policy.triggerOther ?? ""
                        return [name, category, enabled, jamfId, triggerOther].joined(separator: "\t")
                    }.joined(separator: "\n")
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(rowsString, forType: .string)
                }) {
                    Image(systemName: "doc.on.doc")
                    Text("Copy Selected")
                }
                .buttonStyle(.bordered)
                .disabled(selectedPolicyIDs.isEmpty)
            }
        }
        .onChange(of: sortOrder) { newOrder in
            networkController.allPoliciesDetailedGeneral.sort(using: newOrder)
        }
        
#if os(macOS)
        
        VStack(alignment: .leading) {
            
            TabView {
                
                PolicyDetailGeneralTabView(server: server, selectedPoliciesInt: selectedPoliciesInt)
                    .tabItem {
                        Label("General", systemImage: "square.and.pencil")
                    }
                PolicyDetailClearItemsTabView(server: server, selectedPoliciesInt: selectedPoliciesInt)
                    .tabItem {
                        Label("Clear Items", systemImage: "square.and.pencil")
                    }
                PolicyDetailScopeTabView(server: server, selectedPoliciesInt: selectedPoliciesInt)
                    .tabItem {
                        Label("Scope", systemImage: "square.and.pencil")
                    }
                PolicyDetailExportTabView(server: server, selectedPoliciesInt: selectedPoliciesInt)
                    .tabItem {
                        Label("Export", systemImage: "square.and.pencil")
                    }
            }
        }
        .background(Color.blue.opacity(0.0))
        //        .border(Color.yellow)
        //        .frame(minWidth: 300, minHeight: 100, alignment: .leading)
        
        #endif
        
        //        Text("")
        Divider()
        
        
        //  ################################################################################
        //  END
        //  ################################################################################
        
            .onAppear() {
                
                print("PolicyActionsDetailTableView - getting primary data")
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
        
        
        if  networkController.policies.isEmpty {
            print("No policies data - fetching")
            networkController.connect(server: server,resourceType: ResourceType.policies, authToken: networkController.authToken)
            
        } else {
            print("policies data is available")
        }
        
        if networkController.fetchedDetailedPolicies == false {
            
            print("fetchedDetailedPolicies is set to false - running getAllPoliciesDetailed")
            
            if networkController.allPoliciesDetailed.count < networkController.allPoliciesConverted.count {
                
                print("fetching detailed policies")
                
                progress.showProgress()
                
                Task {
                    try await networkController.getAllPoliciesDetailed(server: server, authToken: networkController.authToken, policies: networkController.allPoliciesConverted)
                }
                
                convertToallPoliciesDetailedGeneral()
                
                progress.waitForABit()
                
                networkController.fetchedDetailedPolicies = true
                
            } else {
                print("Download complete")
            }
        } else {
            print("fetchedDetailedPolicies has run")
        }
        
        if  networkController.categories.isEmpty {
            print("No category data - fetching")
            networkController.connect(server: server,resourceType: ResourceType.category, authToken: networkController.authToken)
            
        } else {
            print("category data is available")
        }
        
        if networkController.allIconsDetailed.count <= 1 {
            print("getAllIconsDetailed is:\(networkController.allIconsDetailed.count) - running")
            networkController.getAllIconsDetailed(server: server, authToken: networkController.authToken, loopTotal: 1000)
        } else {
            print("getAllIconsDetailed has already run")
            print("getAllIconsDetailed is:\(networkController.allIconsDetailed.count) - running")
        }
        
        if scopingController.allLdapServers.count <= 1 {
            print("getLdapServers is:\(scopingController.allLdapServers.count) - running")
            Task {
                try await scopingController.getLdapServers(server: server, authToken: networkController.authToken)
            }
        } else {
            print("getLdapServers has already run")
            print("getLdapServers is:\(scopingController.allLdapServers.count) - running")
        }
        
        if  networkController.packages.isEmpty {
            print("No package data - fetching")
            networkController.connect(server: server,resourceType: ResourceType.packages, authToken: networkController.authToken)
            
        } else {
            print("package data is available")
        }
    
        
        if  networkController.allComputerGroups.isEmpty {
            print("No groups data - fetching")
            Task {
                try await networkController.getAllGroups(server: server, authToken: networkController.authToken)
            }
        } else {
            print("groups data is available")
        }
        
        
    }
    
    
    var searchResults: [General] {
        let filtered: [General]
        if searchText.isEmpty {
            filtered = networkController.allPoliciesDetailedGeneral
        } else {
            filtered = networkController.allPoliciesDetailedGeneral.filter { $0.name?.lowercased().contains(searchText.lowercased()) ?? false }
        }
        return filtered
    }
}



//struct PolicyActionsDetailTableView_Previews: PreviewProvider {
//    static var previews: some View {
//        PolicyActionsDetailTableView(server: "")
//            .environmentObject (NetBrain())
//            .environmentObject (Progress())
//            .environmentObject (Layout())
//            .environmentObject (ScopingBrain())
//    }
//}
