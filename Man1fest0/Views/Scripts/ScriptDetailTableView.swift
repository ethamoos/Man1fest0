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
    @State private var showingDeleteConfirmation = false
    
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
        
        // Use Table without direct selection of model objects; selection is ID-based elsewhere if needed
        Table(searchResults, sortOrder: $sortOrderScript) {
            // First column: selection checkbox + name
            TableColumn("name") { script in
                HStack(spacing: 8) {
                    // Checkbox-style button to toggle selection (works on macOS & iOS)
                    Button(action: {
                        toggleSelection(for: script)
                    }) {
                        Image(systemName: selection.contains(script.jamfId) ? "checkmark.square" : "square")
                    }
                    .buttonStyle(.plain)

                    Text(script.name)
                }
            }
            
            TableColumn("ID", value: \.jamfId) {
                script in
                Text(String(script.jamfId))
            }
        }
        .searchable(text: $searchText)
        
        // Selection summary and delete action (macOS layout compatible)
        #if os(macOS)
        VStack(alignment: .leading) {
            HStack {
                Text("Selected: \(selection.count)")
                    .font(.caption)
                Spacer()
                Button(role: .destructive, action: {
                    // show confirmation alert
                    showingDeleteConfirmation = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                }
                .disabled(selection.isEmpty)
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .alert("Caution!", isPresented: $showingDeleteConfirmation) {
                    Button("I understand!", role: .destructive) {
                        performBatchDelete()
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("This action will delete the selected scripts. Always ensure that you have a backup!")
                }
            }
            .padding(.vertical, 6)

            // Show the selected scripts by matching stored Jamf IDs back to the current script list
            if !selection.isEmpty {
                List {
                    ForEach(searchResults.filter { selection.contains($0.jamfId) }) { script in
                        Text(script.name)
                    }
                }
                .frame(minHeight: 80)
            }
        }
        .padding()
        #endif
        
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
    
    // Toggle selection convenience
    private func toggleSelection(for script: ScriptClassic) {
        if selection.contains(script.jamfId) {
            selection.remove(script.jamfId)
        } else {
            selection.insert(script.jamfId)
        }
    }
    
    // Computed helper: map selected Jamf IDs back to ScriptClassic objects
    private var selectedScripts: [ScriptClassic] {
        return networkController.scripts.filter { selection.contains($0.jamfId) }
    }
    
    // Perform batch delete using network controller
    private func performBatchDelete() {
        guard !selection.isEmpty else { return }
        progress.showProgressView = true
        progress.waitForABit()
        Task {
            let selected = selectedScripts
            networkController.batchDeleteScripts(selection: Set(selected), server: server, authToken: networkController.authToken, resourceType: ResourceType.script)
            // clear selection after delete request
            selection.removeAll()
            progress.showProgressView = false
        }
    }
}
