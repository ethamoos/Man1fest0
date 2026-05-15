import SwiftUI
#if os(macOS)
import AppKit
#endif

struct ScriptsDetailView: View {
    
    var script: ScriptClassic
    var scriptID: Int
    var server: String
    
    @State private var bodyText: String = ""
    @State private var scriptName: String = ""
    @State private var category: String = ""
    @State private var filename: String = ""
    @State private var info: String = ""
    @State private var notes: String = ""
    @State private var isEditing: Bool = false
    @State private var showReadOnly: Bool = false
    @State private var showSavedToast: Bool = false
    @State private var showingDeleteConfirmation = false
    @State private var showDeletedToast: Bool = false
    @State private var findText: String = ""
    @State private var replaceText: String = ""
    @State private var matchRanges: [Range<String.Index>] = []
    @State private var currentMatchIndex: Int? = nil
    @State private var injectMatchText: String = ""
    @State private var injectInsertText: String = ""

    // Environment
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var xmlController: XmlBrain
    @EnvironmentObject var layout: Layout
    
    var body: some View {
        let currentScript = networkController.scriptDetailed

        VStack(alignment: .leading, spacing: 12) {
            // Header / Top bar
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    if isEditing {
                        TextField(scriptName.isEmpty ? currentScript.name : scriptName, text: $scriptName)
                            .padding(4)
                            .border(Color.gray)
                    } else {
                        Text(scriptName.isEmpty ? currentScript.name : scriptName)
                            .font(.title)
                            .fontWeight(.semibold)
                    }
                    HStack(spacing: 10) {
                        Text("ID: \(currentScript.id)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Category: \(currentScript.categoryName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()

                // Primary actions
                HStack(spacing: 8) {
//                    Button(action: {
//                        // Run placeholder
//                        progress.showProgress()
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { progress.endProgress() }
//                        print("Run script id:\(scriptID)")
//                    }) {
//                        Label("Run", systemImage: "play.fill")
//                    }

                    Button(action: {
                        isEditing.toggle()
                        if isEditing { showReadOnly = false }
                    }) {
                        Label(isEditing ? "Editing" : "Edit", systemImage: "pencil")
                    }

                    Button(action: {
                        // Save: only network update (upload changes to server)
                        progress.showProgress()
                        Task {
                            print("Updating script")
                            do {
                                try await networkController.updateScript(server: server, scriptName: scriptName, scriptContent: bodyText, scriptId: String(describing: scriptID), authToken: networkController.authToken, category: category, filename: filename, info: info, notes: notes)
                                // indicate saved
                                showSavedToast = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { showSavedToast = false }
                            } catch {
                                print("Failed network save: \(error)")
                                // still show toast as a simple feedback; consider showing error alert in future
                                showSavedToast = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { showSavedToast = false }
                            }
                            progress.endProgress()
                        }
                    }) {
                        Label("Save", systemImage: "square.and.arrow.up")
                    }

                    // Separate Download button: export to local file system
                    Button(action: {
                        progress.showProgress()
                        Task {
                            do {
                                let filename = sanitizedFilename(from: scriptName.isEmpty ? "script_\(scriptID)" : scriptName) + ".txt"
                                let savedURL = try saveBodyTextToDownloads(text: bodyText, filename: filename)
                                print("Saved script to: \(savedURL.path)")
#if os(macOS)
                                NSWorkspace.shared.activateFileViewerSelecting([savedURL])
#endif
                                showSavedToast = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { showSavedToast = false }
                            } catch {
                                print("Failed to save file locally: \(error)")
                                showSavedToast = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { showSavedToast = false }
                            }
                            progress.endProgress()
                        }
                    }) {
                        Label("Download", systemImage: "square.and.arrow.down")
                    }

                    Button(action: {
#if os(macOS)
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.setString(bodyText, forType: .string)
#else
                        UIPasteboard.general.string = bodyText
#endif
                    }) {
                        Label("Copy", systemImage: "doc.on.doc")
                    }

                    Menu {
                        Button("Toggle read-only view") { showReadOnly.toggle(); isEditing = false }
                        Button("Refresh from server") {
                            Task {
                                try? await networkController.getDetailedScript(server: server, scriptID: scriptID, authToken: networkController.authToken)
                                bodyText = networkController.scriptDetailed.scriptContents
                                scriptName = networkController.scriptDetailed.name
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .imageScale(.large)
                    }
                 }
                 .buttonStyle(.bordered)
                // Delete button (destructive)
                Button(role: .destructive) {
                    // Show confirmation dialog
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(showDeletedToast)
                .alert("Delete Script?", isPresented: $showingDeleteConfirmation) {
                    Button("Delete", role: .destructive) {
                        // Perform delete
                        progress.showProgress()
                        Task {
                            do {
                                try await networkController.deleteScript(server: server, resourceType: ResourceType.script, itemID: String(scriptID), authToken: networkController.authToken)
                                // refresh script list
                                try? await networkController.getAllScripts()
                                showDeletedToast = true
                                // Optionally clear local fields
                                bodyText = ""
                                scriptName = ""
                                category = ""
                                filename = ""
                                info = ""
                                notes = ""
                                // Dismiss editing mode
                                isEditing = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                                    showDeletedToast = false
                                }
                            } catch {
                                print("Failed to delete script: \(error)")
                            }
                            progress.endProgress()
                        }
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("This will permanently delete the script from the Jamf server. Are you sure?")
                }
             }
            .padding([.top, .horizontal])

            Divider()

            // Notes / Info
            if currentScript.notes != "" || isEditing {
                DisclosureGroup("Groups") {
                    Section(header: Text("Notes").bold()) {
                        if isEditing {
                            TextEditor(text: $notes)
                                .frame(minHeight: 60)
                                .border(Color.gray)
                        } else {
                            Text(currentScript.notes)
                        }
                    }
                }
            }

            if currentScript.info != "" || isEditing {
                DisclosureGroup("Info") {
//                    Section(header: Text("Info").bold()) {
                        if isEditing {
                            TextEditor(text: $info)
                                .frame(minHeight: 60)
                                .border(Color.gray)
                        } else {
                            Text(currentScript.info)
                        }
//                    }
                }
            }

            // Category and Filename fields
            if isEditing {
                DisclosureGroup("Category") {
//                    Section(header: Text("Category").bold()) {
                        TextField(currentScript.categoryName, text: $category)
                            .padding(4)
                            .border(Color.gray)
//                    }
                }
                DisclosureGroup("Filename") {
                    
//                    Section(header: Text("Filename").bold()) {
                        TextField("Filename", text: $filename)
                            .padding(4)
                            .border(Color.gray)
//                    }
                }
                }

            Divider()

            // Script content area
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Script:")
                        .bold()
                    Spacer()
                    Toggle("Read-only", isOn: $showReadOnly)
                        .labelsHidden()
                }

                if showReadOnly {
                    ScrollView([.vertical, .horizontal]) {
                        Text(bodyText)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    #if os(macOS)
                    .background(Color(.textBackgroundColor))
                    #else
                    .background(Color(.secondarySystemBackground))
                    #endif
                    .cornerRadius(6)
                    .border(Color.gray.opacity(0.3))
                    .frame(minHeight: 240)
                } else {
                    // Find & Replace controls
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            TextField("Find", text: $findText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(minWidth: 200)

                            TextField("Replace", text: $replaceText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(minWidth: 200)

                            Button("Find Next") {
                                updateMatches()
                                goToNextMatch()
                            }
                            .buttonStyle(.bordered)

                            Button("Replace") {
                                replaceCurrent()
                            }
                            .buttonStyle(.bordered)
                            .disabled(findText.isEmpty || matchRanges.isEmpty)

                            Button("Replace All") {
                                replaceAll()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(findText.isEmpty)
                        }

                        HStack(spacing: 12) {
                            if let current = currentMatchIndex {
                                Text("Match \(current + 1) of \(matchRanges.count)")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Matches: \(matchRanges.count)")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }

                            if let current = currentMatchIndex, !matchRanges.isEmpty {
                                // show a small preview of the current match (context +/- 20 chars)
                                let range = matchRanges[current]
                                let preview = previewForRange(range)
                                Text("…\(preview)…")
                                    .font(.footnote)
                                    .lineLimit(1)
                                    .foregroundColor(.blue)
                            }
                        }
                        // Inject after controls
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                TextField("Find line (match)", text: $injectMatchText)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(minWidth: 200)

                                TextField("Line to insert", text: $injectInsertText)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(minWidth: 200)

                                Button("Inject After") {
                                    injectAfterFirst()
                                }
                                .buttonStyle(.bordered)
                                .disabled(injectMatchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                                Button("Inject After All") {
                                    injectAfterAll()
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(injectMatchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                        }
                    }
                    .padding([.horizontal, .bottom], 6)

                    TextEditor(text: $bodyText)
                        .font(.system(.body, design: .monospaced))
                        .disableAutocorrection(true)
                        .frame(minHeight: 240, maxHeight: .infinity)
                        .border(Color.gray.opacity(0.3))
                        .padding(4)
                        .disabled(!isEditing)
                }

                HStack {
                    Spacer()
                    Button(action: {
#if os(macOS)
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.setString(bodyText, forType: .string)
#else
                        UIPasteboard.general.string = bodyText
#endif
                    }) {
                        Image(systemName: "doc.on.doc")
                        Text("Copy")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .textSelection(.enabled)

            if showSavedToast {
                HStack {
                    Image(systemName: "checkmark.circle")
                    Text("Saved")
                }
                .padding(8)
                .background(Color.green.opacity(0.12))
                .cornerRadius(8)
                .padding(.horizontal)
            }
            if showDeletedToast {
                HStack {
                    Image(systemName: "trash")
                    Text("Deleted")
                }
                .padding(8)
                .background(Color.red.opacity(0.12))
                .cornerRadius(8)
                .padding(.horizontal)
            }

            // Open in Browser button (mirrors PolicyDetailView behavior)
            HStack {
                Spacer()
                Button(action: {
                    // Construct Jamf Pro script UI URL directly (avoids translation mismatches)
                    let trimmedServer = server.trimmingCharacters(in: .whitespacesAndNewlines)
                    var base = trimmedServer
                    if base.hasSuffix("/") { base.removeLast() }
                    let uiURL = "\(base)/view/settings/computer-management/scripts/\(scriptID)?tab=general"
                    print("Opening script UI URL: \(uiURL)")
                    layout.openURL(urlString: uiURL)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "safari")
                        Text("Open in Browser")
                    }
                }
                .help("Open this script in the Jamf web interface in your default browser.")
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .padding(.top, 6)
                Spacer()
            }
            .padding()
            .textSelection(.enabled)

            Spacer()
        }
        .padding()
        .onAppear() {
            Task {
                try await networkController.getDetailedScript(server: server, scriptID: scriptID, authToken: networkController.authToken)
                bodyText = networkController.scriptDetailed.scriptContents
                scriptName = networkController.scriptDetailed.name
                category = networkController.scriptDetailed.categoryName
                filename = networkController.scriptDetailed.name
                info = networkController.scriptDetailed.info
                notes = networkController.scriptDetailed.notes
            }
        }
    }

    // MARK: - Helpers
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

    // MARK: - Find & Replace Helpers
    private func updateMatches() {
        let query = findText
        matchRanges.removeAll()
        currentMatchIndex = nil
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var searchStart = bodyText.startIndex
        while searchStart < bodyText.endIndex,
              let range = bodyText.range(of: trimmed, options: [], range: searchStart..<bodyText.endIndex) {
            matchRanges.append(range)
            searchStart = range.upperBound
        }

        if !matchRanges.isEmpty {
            currentMatchIndex = 0
        }
    }

    private func goToNextMatch() {
        guard !matchRanges.isEmpty else { return }
        if let idx = currentMatchIndex {
            currentMatchIndex = (idx + 1) % matchRanges.count
        } else {
            currentMatchIndex = 0
        }
    }

    private func replaceCurrent() {
        guard let idx = currentMatchIndex, idx >= 0, idx < matchRanges.count else { return }
        let range = matchRanges[idx]
        bodyText.replaceSubrange(range, with: replaceText)
        // After modifying bodyText, recompute matches and attempt to set currentMatchIndex sensibly
        updateMatches()
        if !matchRanges.isEmpty {
            currentMatchIndex = min(idx, matchRanges.count - 1)
        } else {
            currentMatchIndex = nil
        }
    }

    private func replaceAll() {
        let trimmed = findText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        bodyText = bodyText.replacingOccurrences(of: trimmed, with: replaceText)
        updateMatches()
    }

    private func injectAfterFirst() {
        let match = injectMatchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !match.isEmpty else { return }

        var lines = bodyText.components(separatedBy: "\n")
        for i in 0..<lines.count {
            if lines[i].contains(match) {
                // preserve leading whitespace from the matched line
                let leading = String(lines[i].prefix { $0 == " " || $0 == "\t" })
                let insertion = leading + injectInsertText
                lines.insert(insertion, at: i + 1)
                bodyText = lines.joined(separator: "\n")
                updateMatches()
                return
            }
        }
    }

    private func injectAfterAll() {
        let match = injectMatchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !match.isEmpty else { return }

        var lines = bodyText.components(separatedBy: "\n")
        var i = 0
        while i < lines.count {
            if lines[i].contains(match) {
                let leading = String(lines[i].prefix { $0 == " " || $0 == "\t" })
                let insertion = leading + injectInsertText
                lines.insert(insertion, at: i + 1)
                i += 2 // skip over the inserted line
            } else {
                i += 1
            }
        }
        bodyText = lines.joined(separator: "\n")
        updateMatches()
    }

    private func previewForRange(_ range: Range<String.Index>) -> String {
        let beforeStart = bodyText.index(range.lowerBound, offsetBy: -20, limitedBy: bodyText.startIndex) ?? bodyText.startIndex
        let afterEnd = bodyText.index(range.upperBound, offsetBy: 20, limitedBy: bodyText.endIndex) ?? bodyText.endIndex
        return String(bodyText[beforeStart..<afterEnd]).replacingOccurrences(of: "\n", with: " ")
    }

}

//struct PackagesDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        PackagesDetailView()
//    }
//}
