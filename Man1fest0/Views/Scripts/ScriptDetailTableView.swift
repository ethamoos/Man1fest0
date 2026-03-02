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
    // Use ID-based selection for stability (ScriptClassic.id is UUID)
    @State var selection = Set<ScriptClassic.ID>()
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
        #if os(macOS)
        // On macOS use native Table selection (mouse) bound to the ID set
        Table(searchResults, selection: $selection, sortOrder: $sortOrderScript) {
            TableColumn("Name", value: \.name) { script in
                Text(script.name)
            }

            TableColumn("ID", value: \.jamfId) { script in
                Text(String(script.jamfId))
            }
        }
        .searchable(text: $searchText)
        #else
        // Fallback for other platforms: keep the checkbox-style toggle
        Table(searchResults, sortOrder: $sortOrderScript) {
            // First column: selection checkbox + name
            TableColumn("name") { script in
                HStack(spacing: 8) {
                    // Checkbox-style button to toggle selection (works on iOS)
                    Button(action: {
                        toggleSelection(for: script)
                    }) {
                        Image(systemName: selection.contains(script.id) ? "checkmark.square" : "square")
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
        #endif
        
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

                // Download Selected button (batch download)
                Button(action: {
                    performBatchDownload()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.down")
                        Text("Download")
                    }
                }
                .disabled(selection.isEmpty)
                .buttonStyle(.bordered)
                .tint(.blue)
            }
            .padding(.vertical, 6)

            // Show the selected scripts by matching selection UUIDs back to the current script list
            if !selection.isEmpty {
                List {
                    ForEach(searchResults.filter { selection.contains($0.id) }) { script in
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
        if selection.contains(script.id) {
            selection.remove(script.id)
        } else {
            selection.insert(script.id)
        }
    }
    
    // Computed helper: map selected Jamf IDs back to ScriptClassic objects
    private var selectedScripts: [ScriptClassic] {
        return networkController.scripts.filter { selection.contains($0.id) }
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

    // Perform batch download: fetch each selected script details and save to Downloads
    private func performBatchDownload() {
        guard !selection.isEmpty else { return }
        progress.showProgressView = true
        progress.waitForABit()
        Task {
            var savedURLs: [URL] = []
            for script in selectedScripts {
                do {
                    // Fetch detailed script from server (this populates networkController.scriptDetailed)
                    try await networkController.getDetailedScript(server: server, scriptID: script.jamfId, authToken: networkController.authToken)

                    // Read the fetched content
                    let contents = networkController.scriptDetailed.scriptContents
                    let name = networkController.scriptDetailed.name.isEmpty ? script.name : networkController.scriptDetailed.name
                    let filename = sanitizedFilename(from: name.isEmpty ? "script_\(script.jamfId)" : name) + "_\(script.jamfId).txt"

                    // Save to Downloads
                    let saved = try saveBodyTextToDownloads(text: contents, filename: filename)
                    savedURLs.append(saved)
                    print("Saved script \(script.jamfId) to: \(saved.path)")

                } catch {
                    print("Failed to download/save script \(script.jamfId): \(error)")
                }
            }

            // If on macOS, reveal the saved files in Finder (select them)
            #if os(macOS)
            if !savedURLs.isEmpty {
                NSWorkspace.shared.activateFileViewerSelecting(savedURLs)
            }
            #endif

            // feedback
            progress.showProgressView = false
        }
    }

    // MARK: - Helpers (filename sanitization & saving) - adapted from ScriptsDetailView
    private func sanitizedFilename(from name: String) -> String {
        // Remove characters not allowed in filenames
        let illegalChars = CharacterSet(charactersIn: "\\/:*?\"<>|\n\r\t")
        var cleaned = name
        if let range = cleaned.rangeOfCharacter(from: illegalChars) {
            cleaned.removeSubrange(range)
        }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.isEmpty { cleaned = "script" }
        return cleaned.replacingOccurrences(of: " ", with: "_")
    }

    private func saveBodyTextToDownloads(text: String, filename: String) throws -> URL {
        let data = Data(text.utf8)

        // Prefer the Downloads directory on macOS, fall back to Documents on iOS
    #if os(macOS)
        if let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            let dest = downloads.appendingPathComponent(filename)
            try data.write(to: dest, options: .atomic)
            return dest
        } else {
            throw NSError(domain: "SaveError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Downloads directory not found"])
        }
    #else
        if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let dest = docs.appendingPathComponent(filename)
            try data.write(to: dest, options: .atomic)
            return dest
        } else {
            throw NSError(domain: "SaveError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Documents directory not found"])
        }
    #endif
    }
}
