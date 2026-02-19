//
//  ScriptsActionView.swift
//  Man1fest0
//
//  Created by Amos Deane on 28/05/2025.
//


import SwiftUI


struct ScriptsActionView: View {
        
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var progress: Progress
    
    @State private var searchText = ""
    // Use a set of Jamf IDs for selection — stable across refreshes and API fetches
    @State private var selection = Set<Int>()
    @State private var showingWarning = false
    
    var server: String

    @State var scripts: [ScriptClassic] = []
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            if networkController.scripts.count > 0 {
                // Removed inner NavigationView to avoid creating duplicate NSToolbar search items.
                // Use the Jamf integer ID for the List selection binding
                List(searchResults, id: \ .jamfId, selection: $selection) { script in
                    HStack {
                        Image(systemName: "applescript")
                        Text("\(script.name)").font(.system(size: 12.0)).foregroundColor(.blue)
                    }
#if os(macOS)
                    .navigationTitle("Scripts")
#endif
                    .foregroundColor(.blue)
                }
#if os(macOS)
                .frame(minWidth: 300, maxWidth: .infinity)
#endif
                .toolbar {
                    Button(action: {
                        progress.showProgress()
                        progress.waitForABit()
                        print("Refresh")
                        networkController.connect(server: server,resourceType: ResourceType.scripts, authToken: networkController.authToken)
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh")
                        }
                    }
                }
                .searchable(text: $searchText)
                
                //  ################################################################################
                //              Toolbar - END
                //  ################################################################################
                
                #if os(macOS)
                
                VStack(alignment: .leading) {
                    Text("Selections").fontWeight(.bold)
                    
                    // Show number of selected items for quick feedback
                    Text("Selected: \(selection.count)").font(.caption)
                    
                    // Show the selected scripts by matching stored Jamf IDs back to the current script list
                    List {
                        ForEach(searchResults.filter { selection.contains($0.jamfId) }) { script in
                            Text(script.name)
                        }
                    }
                    
                    //  ################################################################################
                    //              DELETE
                    //  ################################################################################
                    
                    HStack(spacing:20) {
                        Button(action: {
                            showingWarning = true
                        }) {
                            Text("Delete")
                        }
                        .alert(isPresented: $showingWarning) {
                            Alert(
                                title: Text("Caution!"),
                                message: Text("This action will delete data.\n Always ensure that you have a backup!"),
                                primaryButton: .destructive(Text("I understand!")) {
                                    // Code to execute when "Yes" is tapped
                                    progress.showProgressView = true
                                    progress.waitForABit()
                                    Task {
                                        // Use the computed property to get the selected ScriptClassic objects
                                        let selected = selectedScripts
                                        networkController.batchDeleteScripts(selection: Set(selected), server: server, authToken: networkController.authToken, resourceType: ResourceType.script)
                                    }
                                    print("Yes tapped")
                                },
                                secondaryButton: .cancel()
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .shadow(color: .gray, radius: 2, x: 0, y: 2)
                        .frame(height: 50)
                    }
                }
                .padding()
#endif
            } else {
                ProgressView {
                    Text("Loading")
                        .font(.title)
                }
            }
        }
                
        .frame(minWidth: 300, minHeight: 100, alignment: .leading)

        .onAppear {
            networkController.separationLine()
            print("ScriptsView appeared.")
            print(networkController.scripts.count)
            if networkController.scripts.count == 0 {
                      print("Fetching scripts")
                networkController.connect(server: server,resourceType: ResourceType.scripts, authToken: networkController.authToken)
            }
        }
        
        if progress.showProgressView == true {
            ProgressView {
                Text("Processing")
                    .padding()
            }
        } else {
            Text("")
        }
    }
    
    var searchResults: [ScriptClassic] {
        if searchText.isEmpty {
            return networkController.scripts
        } else {
            return networkController.scripts.filter { $0.name.lowercased().contains(searchText.lowercased())}
        }
    }
    
    // Computed helper: map selected Jamf IDs back to ScriptClassic objects
    private var selectedScripts: [ScriptClassic] {
        return networkController.scripts.filter { selection.contains($0.jamfId) }
    }
}
