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
    // Find & Replace state
    @State private var findText: String = ""
    @State private var replaceText: String = ""
    @State private var replacementResultMessage: String = ""
    
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
         Task { try? await networkController.getAllScripts() }
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
                    
                    // Find & Replace controls (operate on selected scripts)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Find & Replace").fontWeight(.semibold)
                        HStack {
                            TextField("Find", text: $findText)
                                .textFieldStyle(.roundedBorder)
                            TextField("Replace", text: $replaceText)
                                .textFieldStyle(.roundedBorder)
                        }
                        HStack(spacing: 12) {
                            Button("Replace All in Selected") {
                                Task {
                                    await replaceInSelectedScripts(replaceAll: true)
                                }
                            }
                            .disabled(selection.isEmpty || findText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .buttonStyle(.bordered)

                            Button("Replace First in Selected") {
                                Task {
                                    await replaceInSelectedScripts(replaceAll: false)
                                }
                            }
                            .disabled(selection.isEmpty || findText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .buttonStyle(.bordered)
                        }
                        if !replacementResultMessage.isEmpty {
                            Text(replacementResultMessage).font(.caption).foregroundColor(.secondary)
                        }
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
                Task { try await networkController.getAllScripts() }
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
    
    // Perform find & replace across selected scripts
    private func replaceInSelectedScripts(replaceAll: Bool) async {
        guard !selection.isEmpty else { return }
        let match = findText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !match.isEmpty else { return }

        replacementResultMessage = "Working..."
        progress.showProgressView = true
        progress.waitForABit()

        var totalReplacements = 0
        for script in selectedScripts {
            do {
                try await networkController.getDetailedScript(server: server, scriptID: script.jamfId, authToken: networkController.authToken)
                var contents = networkController.scriptDetailed.scriptContents
                if replaceAll {
                    let occurrences = contents.components(separatedBy: match).count - 1
                    if occurrences > 0 {
                        contents = contents.replacingOccurrences(of: match, with: replaceText)
                        totalReplacements += occurrences
                        // save back
                        try await networkController.updateScript(server: server, scriptName: networkController.scriptDetailed.name, scriptContent: contents, scriptId: String(script.jamfId), authToken: networkController.authToken, category: networkController.scriptDetailed.categoryName, filename: networkController.scriptDetailed.name, info: networkController.scriptDetailed.info, notes: networkController.scriptDetailed.notes)
                    }
                } else {
                    if let range = contents.range(of: match) {
                        contents.replaceSubrange(range, with: replaceText)
                        totalReplacements += 1
                        try await networkController.updateScript(server: server, scriptName: networkController.scriptDetailed.name, scriptContent: contents, scriptId: String(script.jamfId), authToken: networkController.authToken, category: networkController.scriptDetailed.categoryName, filename: networkController.scriptDetailed.name, info: networkController.scriptDetailed.info, notes: networkController.scriptDetailed.notes)
                    }
                }
            } catch {
                print("Find/Replace failed for script \(script.jamfId): \(error)")
            }
        }

        progress.showProgressView = false
        replacementResultMessage = "Replacements made: \(totalReplacements)"
        // clear message after a few seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            replacementResultMessage = ""
        }
    }
    
    // Computed helper: map selected Jamf IDs back to ScriptClassic objects
    private var selectedScripts: [ScriptClassic] {
        return networkController.scripts.filter { selection.contains($0.jamfId) }
    }
}
