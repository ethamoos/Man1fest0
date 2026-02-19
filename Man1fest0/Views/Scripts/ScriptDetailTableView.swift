//
//  ScriptDetailTableView.swift
//  Man1fest0
//
//  Created by Amos Deane on 24/04/2025.
//



import SwiftUI

struct ScriptDetailTableView: View {
    
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

    //  ########################################################################################
    //  Filters
    //  ########################################################################################
    
    @State var computerGroupFilter = ""
    @State var allLdapServersFilter = ""
    //  ########################################################################################
    //  SELECTIONS
    //  ########################################################################################
    
    @State var computerGroupSelection = ComputerGroup(id: 0, name: "", isSmart: false)
    @State var selectedScript = ScriptClassic(name: "", jamfId: 0)
//    @State var selection = ScriptClassic(name: "", jamfId: 0)
    // Use ID-based selection for stability
    @State var selection = Set<Int>()
//    @State private var selectedPolicyIDs = Set<General.ID>()
    @State private var selectedPolicyjamfIDs = Set<General>()
    @State private var selectedIDs = []
    @State private var sortOrder = [KeyPathComparator(\General.name, order: .reverse)]
    @State private var sortOrderScript = [KeyPathComparator(\ScriptClassic.name, order: .reverse)]
    @State var searchText = ""
    
    //  ########################################################################################
    //  ########################################################################################
    //  ########################################################################################
    
    var searchResults: [ScriptClassic] {
        let filtered: [ScriptClassic]
        if searchText.isEmpty {
            filtered = networkController.scripts
        } else {
            filtered = networkController.scripts.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
        return filtered.sorted(using: sortOrderScript)
    }
        
    var body: some View {
        
        
//        Table(networkController.scripts, sortOrder: $sortOrderScript, selection: $selection) {
        // Use Table without direct selection of model objects; selection is ID-based elsewhere if needed
        Table(searchResults, sortOrder: $sortOrderScript) {
            
            TableColumn("name", value: \.name)
            
            TableColumn("ID", value: \.jamfId) {
                script in
                Text(String(script.jamfId))
            }
        }
        .searchable(text: $searchText)
        
        
        //  ########################################################################################
        //  ########################################################################################
        //  ########################################################################################
        //  ########################################################################################
        
        
        //        Table(searchResults, selection: $selectedPolicyIDs, sortOrder: $sortOrder) {
        //
        
        //              ################################################################################
        //              DELETE
        //              ################################################################################
        
        //        VStack(alignment: .leading) {
        //            Divider()
        //            HStack(spacing: 20) {
        //                Button(action: {
        //                    showingWarning = true
        //                    progress.showProgressView = true
        //                    print("Set showProgressView to true")
        //                    print(progress.showProgressView)
        //                    progress.waitForABit()
        //                    print("Check processingComplete")
        //                    print(String(describing: networkController.processingComplete))
        //
        //                }) {
        //                    Text("Delete")
        //                }
        //                .alert(isPresented: $showingWarning) {
        //                    Alert(
        //                        title: Text("Caution!"),
        //                        message: Text("This action will delete data.\n Always ensure that you have a backup!"),
        //                        primaryButton: .destructive(Text("I understand!")) {
        //                            // Code to execute when "Yes" is tapped
        //
        //                            networkController.processDeletePoliciesGeneral(selection: selectedPoliciesInt, server: server,  authToken: networkController.authToken, resourceType: ResourceType.policies)
        //                            print("Yes tapped")
        //
        //                        },
        //                        secondaryButton: .cancel()
        //                    )
        //                }
        //                .buttonStyle(.borderedProminent)
        //                .tint(.red)
        //                .shadow(color: .gray, radius: 2, x: 0, y: 2)
        
        Button(action: {
            
            progress.showProgress()
            progress.waitForABit()
            Task {
                try? await Script.getAll(server: server, auth: networkController.auth ?? JamfAuthToken(token: "", expires: ""))
            }
            print("Refresh")
            
        }) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.clockwise")
                Text("Refresh")
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(.blue)
        
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
    
    
    //  #################################################################################
    //  Master Fetch function
    //  #################################################################################
    
    
    func fetchData() {
        
        if networkController.scripts.count == 0 {
            print("Fetching scripts")
            networkController.connect(server: server,resourceType: ResourceType.scripts, authToken: networkController.authToken)
        }
        
    }
    
    
    
    
    
    //            var searchResults: [General] {
    //
    //                if searchText.isEmpty {
    //                    return networkController.allPoliciesDetailedGeneral
    //                } else {
    //                    return networkController.allPoliciesDetailedGeneral.filter { $0.name!.lowercased().contains(searchText.lowercased())}
    //                }
    //            }
}
