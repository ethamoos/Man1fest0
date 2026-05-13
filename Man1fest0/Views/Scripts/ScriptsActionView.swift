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
    @State private var injectMatchText: String = ""
    @State private var injectInsertText: String = ""
    
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
                    // Inject after controls for selected scripts
                    VStack(alignment: .leading) {
                        Text("Inject After (applies to selected scripts)").fontWeight(.bold)
                        HStack(spacing: 8) {
                            TextField("Find line (match)", text: $injectMatchText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(minWidth: 200)

                            TextField("Line to insert", text: $injectInsertText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(minWidth: 200)

                            Button("Inject After") {
                                applyInjectAfterToSelected(firstOnly: true)
                            }
                            .buttonStyle(.bordered)
                            .disabled(selection.isEmpty || injectMatchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                            Button("Inject After All") {
                                applyInjectAfterToSelected(firstOnly: false)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(selection.isEmpty || injectMatchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
    
    // Computed helper: map selected Jamf IDs back to ScriptClassic objects
    private var selectedScripts: [ScriptClassic] {
        return networkController.scripts.filter { selection.contains($0.jamfId) }
    }

    // Apply injection to selected scripts. If firstOnly is true, insert after first matching line; otherwise insert after every matching line.
    private func applyInjectAfterToSelected(firstOnly: Bool) {
        guard !selection.isEmpty else { return }
        let match = injectMatchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let insertLine = injectInsertText
        guard !match.isEmpty else { return }

        progress.showProgressView = true
        Task {
            for script in selectedScripts {
                do {
                    try await networkController.getDetailedScript(server: server, scriptID: script.jamfId, authToken: networkController.authToken)
                    var content = networkController.scriptDetailed.scriptContents
                    var lines = content.components(separatedBy: "\n")
                    var modified = false

                    if firstOnly {
                        for i in 0..<lines.count {
                            if lines[i].contains(match) {
                                let leading = String(lines[i].prefix { $0 == " " || $0 == "\t" })
                                let insertion = leading + insertLine
                                lines.insert(insertion, at: i + 1)
                                modified = true
                                break
                            }
                        }
                    } else {
                        var i = 0
                        while i < lines.count {
                            if lines[i].contains(match) {
                                let leading = String(lines[i].prefix { $0 == " " || $0 == "\t" })
                                let insertion = leading + insertLine
                                lines.insert(insertion, at: i + 1)
                                i += 2
                                modified = true
                            } else {
                                i += 1
                            }
                        }
                    }

                    if modified {
                        let newContent = lines.joined(separator: "\n")
                        // Use details from networkController.scriptDetailed for metadata when updating
                        try await networkController.updateScript(server: server, scriptName: networkController.scriptDetailed.name, scriptContent: newContent, scriptId: String(describing: script.jamfId), authToken: networkController.authToken, category: networkController.scriptDetailed.categoryName, filename: networkController.scriptDetailed.name, info: networkController.scriptDetailed.info, notes: networkController.scriptDetailed.notes)
                    }
                } catch {
                    print("Failed to inject into script id:\(script.jamfId): \(error)")
                }
            }

            // Refresh scripts list after modifications
            try? await networkController.getAllScripts()
            progress.showProgressView = false
        }
    }
}
