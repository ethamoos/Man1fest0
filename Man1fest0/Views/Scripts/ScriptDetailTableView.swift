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
    // Find & Replace state
    @State private var findText: String = ""
    @State private var replaceText: String = ""
    @State private var replacementResultMessage: String = ""
    @State private var caseInsensitive: Bool = true
    @State private var useRegex: Bool = false
    @State private var wholeWord: Bool = false
    @State private var showReplaceConfirmation: Bool = false
    @State private var pendingReplaceAll: Bool = true
    // Inject state (insert lines after a matched line)
    @State private var injectMatchText: String = ""
    @State private var injectInsertText: String = ""
    @State private var injectResultMessage: String = ""
    @State private var showInjectConfirmation: Bool = false
    @State private var pendingInjectAll: Bool = true
    
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

            DisclosureGroup("Find/Replace/Inject") {
                // Find & Replace
                VStack(alignment: .leading, spacing: 8) {
                    Text("Find & Replace").fontWeight(.semibold)
                    HStack {
                        TextField("Find", text: $findText)
                            .textFieldStyle(.roundedBorder)
                        TextField("Replace", text: $replaceText)
                            .textFieldStyle(.roundedBorder)
                    }

                    HStack(spacing: 12) {
                        Toggle("Case-insensitive", isOn: $caseInsensitive)
                        Toggle("Use Regex", isOn: $useRegex)
                        Toggle("Whole word", isOn: $wholeWord)
                    }

                    HStack(spacing: 12) {
                        Button("Replace All in Selected") {
                            if selection.count > 1 {
                                pendingReplaceAll = true
                                showReplaceConfirmation = true
                            } else {
                                Task { await replaceInSelectedScripts(replaceAll: true) }
                            }
                        }
                        .disabled(selection.isEmpty || findText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .buttonStyle(.bordered)

                        Button("Replace First in Selected") {
                            if selection.count > 1 {
                                pendingReplaceAll = false
                                showReplaceConfirmation = true
                            } else {
                                Task { await replaceInSelectedScripts(replaceAll: false) }
                            }
                        }
                        .disabled(selection.isEmpty || findText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .buttonStyle(.bordered)
                    }

                    if !replacementResultMessage.isEmpty {
                        Text(replacementResultMessage).font(.caption).foregroundColor(.secondary)
                    }
                }

                Divider()

                // Inject controls
                VStack(alignment: .leading, spacing: 8) {
                    Text("Inject").fontWeight(.semibold)
                    HStack {
                        TextField("Find line (match)", text: $injectMatchText)
                            .textFieldStyle(.roundedBorder)
                        TextField("Line to insert", text: $injectInsertText)
                            .textFieldStyle(.roundedBorder)
                    }

                    HStack(spacing: 12) {
                        Button("Insert After First") {
                            if selection.count > 1 {
                                pendingInjectAll = false
                                showInjectConfirmation = true
                            } else {
                                Task { await injectAfterFirstAcrossSelected() }
                            }
                        }
                        .disabled(selection.isEmpty || injectMatchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .buttonStyle(.bordered)

                        Button("Insert After All") {
                            if selection.count > 1 {
                                pendingInjectAll = true
                                showInjectConfirmation = true
                            } else {
                                Task { await injectAfterAllAcrossSelected() }
                            }
                        }
                        .disabled(selection.isEmpty || injectMatchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .buttonStyle(.bordered)
                    }

                    if !injectResultMessage.isEmpty {
                        Text(injectResultMessage).font(.caption).foregroundColor(.secondary)
                    }
                }
            }
            // confirmation for multi-script replace
            .alert("Confirm Replace", isPresented: $showReplaceConfirmation) {
                Button("Proceed", role: .destructive) {
                    Task { await replaceInSelectedScripts(replaceAll: pendingReplaceAll) }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You're about to perform replacements across multiple scripts. This action cannot be undone. Proceed?")
            }
            // confirmation for multi-script inject
            .alert("Confirm Inject", isPresented: $showInjectConfirmation) {
                Button("Proceed", role: .destructive) {
                    if pendingInjectAll {
                        Task { await injectAfterAllAcrossSelected() }
                    } else {
                        Task { await injectAfterFirstAcrossSelected() }
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You're about to perform injections across multiple scripts. This action cannot be undone. Proceed?")
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
            Task { try await networkController.getAllScripts() }
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

                var changed = false

                if useRegex || wholeWord {
                    // Build regex pattern
                    var pattern = match
                    if !useRegex {
                        pattern = NSRegularExpression.escapedPattern(for: match)
                    }
                    if wholeWord {
                        pattern = "\\b" + pattern + "\\b"
                    }
                    let options: NSRegularExpression.Options = caseInsensitive ? [.caseInsensitive] : []
                    let re = try NSRegularExpression(pattern: pattern, options: options)

                    if replaceAll {
                        let range = NSRange(contents.startIndex..., in: contents)
                        let matches = re.numberOfMatches(in: contents, options: [], range: range)
                        if matches > 0 {
                            let new = re.stringByReplacingMatches(in: contents, options: [], range: range, withTemplate: replaceText)
                            contents = new
                            totalReplacements += matches
                            changed = true
                        }
                    } else {
                        if let m = re.firstMatch(in: contents, options: [], range: NSRange(contents.startIndex..., in: contents)) {
                            if let swiftRange = Range(m.range, in: contents) {
                                contents.replaceSubrange(swiftRange, with: replaceText)
                                totalReplacements += 1
                                changed = true
                            }
                        }
                    }
                } else {
                    // Simple string replacement with optional case-insensitive behavior
                    if caseInsensitive {
                        let lowerContents = contents.lowercased()
                        let lowerMatch = match.lowercased()
                        if replaceAll {
                            let occurrences = lowerContents.components(separatedBy: lowerMatch).count - 1
                            if occurrences > 0 {
                                contents = contents.replacingOccurrences(of: match, with: replaceText, options: .caseInsensitive, range: nil)
                                totalReplacements += occurrences
                                changed = true
                            }
                        } else {
                            if let range = lowerContents.range(of: lowerMatch) {
                                let start = lowerContents.distance(from: lowerContents.startIndex, to: range.lowerBound)
                                let length = lowerContents.distance(from: range.lowerBound, to: range.upperBound)
                                let nsStart = contents.index(contents.startIndex, offsetBy: start)
                                let nsEnd = contents.index(nsStart, offsetBy: length)
                                let nsRange = nsStart..<nsEnd
                                contents.replaceSubrange(nsRange, with: replaceText)
                                totalReplacements += 1
                                changed = true
                            }
                        }
                    } else {
                        if replaceAll {
                            let occurrences = contents.components(separatedBy: match).count - 1
                            if occurrences > 0 {
                                contents = contents.replacingOccurrences(of: match, with: replaceText)
                                totalReplacements += occurrences
                                changed = true
                            }
                        } else {
                            if let range = contents.range(of: match) {
                                contents.replaceSubrange(range, with: replaceText)
                                totalReplacements += 1
                                changed = true
                            }
                        }
                    }
                }

                if changed {
                    // Save updated script back to server
                    try await networkController.updateScript(server: server, scriptName: networkController.scriptDetailed.name, scriptContent: contents, scriptId: String(script.jamfId), authToken: networkController.authToken, category: networkController.scriptDetailed.categoryName, filename: networkController.scriptDetailed.name, info: networkController.scriptDetailed.info, notes: networkController.scriptDetailed.notes)
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

    // Inject: insert a line after the first matching line in each selected script
    private func injectAfterFirstAcrossSelected() async {
        guard !selection.isEmpty else { return }
        let match = injectMatchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !match.isEmpty else { return }

        injectResultMessage = "Working..."
        progress.showProgressView = true
        progress.waitForABit()

        var totalInserts = 0

        for script in selectedScripts {
            do {
                try await networkController.getDetailedScript(server: server, scriptID: script.jamfId, authToken: networkController.authToken)
                var contents = networkController.scriptDetailed.scriptContents

                let matchLower = match.lowercased()
                var lines = contents.components(separatedBy: "\n")
                if let idx = lines.firstIndex(where: { $0.lowercased().contains(matchLower) }) {
                    // insert after idx
                    let insertion = injectInsertText
                    lines.insert(insertion, at: idx + 1)
                    let newContents = lines.joined(separator: "\n")
                    try await networkController.updateScript(server: server, scriptName: networkController.scriptDetailed.name, scriptContent: newContents, scriptId: String(script.jamfId), authToken: networkController.authToken, category: networkController.scriptDetailed.categoryName, filename: networkController.scriptDetailed.name, info: networkController.scriptDetailed.info, notes: networkController.scriptDetailed.notes)
                    totalInserts += 1
                }
            } catch {
                print("Inject failed for script \(script.jamfId): \(error)")
            }
        }

        progress.showProgressView = false
        injectResultMessage = "Inserted in: \(totalInserts) scripts"
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { injectResultMessage = "" }
    }

    // Inject: insert a line after all matching lines in each selected script
    private func injectAfterAllAcrossSelected() async {
        guard !selection.isEmpty else { return }
        let match = injectMatchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !match.isEmpty else { return }

        injectResultMessage = "Working..."
        progress.showProgressView = true
        progress.waitForABit()

        var totalInserts = 0

        for script in selectedScripts {
            do {
                try await networkController.getDetailedScript(server: server, scriptID: script.jamfId, authToken: networkController.authToken)
                var contents = networkController.scriptDetailed.scriptContents

                let matchLower = match.lowercased()
                var lines = contents.components(separatedBy: "\n")
                // find all indices where line contains match
                var indices: [Int] = []
                for (i, line) in lines.enumerated() {
                    if line.lowercased().contains(matchLower) {
                        indices.append(i)
                    }
                }
                if !indices.isEmpty {
                    // insert after each index, iterate from end to preserve indexes
                    for idx in indices.reversed() {
                        lines.insert(injectInsertText, at: idx + 1)
                        totalInserts += 1
                    }
                    let newContents = lines.joined(separator: "\n")
                    try await networkController.updateScript(server: server, scriptName: networkController.scriptDetailed.name, scriptContent: newContents, scriptId: String(script.jamfId), authToken: networkController.authToken, category: networkController.scriptDetailed.categoryName, filename: networkController.scriptDetailed.name, info: networkController.scriptDetailed.info, notes: networkController.scriptDetailed.notes)
                }
            } catch {
                print("Inject failed for script \(script.jamfId): \(error)")
            }
        }

        progress.showProgressView = false
        injectResultMessage = "Inserted lines: \(totalInserts)"
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { injectResultMessage = "" }
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
