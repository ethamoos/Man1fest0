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
    // Find/Replace & Inject state for single-script editor
    @State private var findText: String = ""
    @State private var replaceText: String = ""
    @State private var replacementResultMessage: String = ""
    @State private var caseInsensitive: Bool = true
    @State private var useRegex: Bool = false
    @State private var wholeWord: Bool = false
    @State private var injectMatchText: String = ""
    @State private var injectInsertText: String = ""
    @State private var injectResultMessage: String = ""

    // Environment
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var xmlController: XmlBrain
    @EnvironmentObject var layout: Layout
    
    var body: some View {
        let currentScript = networkController.scriptDetailed

        ScrollView {
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

            // When editing, show Find/Replace/Inject tools inside a DisclosureGroup
            if isEditing {
                DisclosureGroup("Find/Replace/Inject") {
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
                            Button("Replace All") {
                                Task { await replaceInThisScript(replaceAll: true) }
                            }
                            .disabled(findText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .buttonStyle(.bordered)

                            Button("Replace First") {
                                Task { await replaceInThisScript(replaceAll: false) }
                            }
                            .disabled(findText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .buttonStyle(.bordered)
                        }

                        if !replacementResultMessage.isEmpty {
                            Text(replacementResultMessage).font(.caption).foregroundColor(.secondary)
                        }
                    }

                    Divider()

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
                                Task { await injectAfterFirstInThisScript() }
                            }
                            .disabled(injectMatchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .buttonStyle(.bordered)

                            Button("Insert After All") {
                                Task { await injectAfterAllInThisScript() }
                            }
                            .disabled(injectMatchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .buttonStyle(.bordered)
                        }

                        if !injectResultMessage.isEmpty {
                            Text(injectResultMessage).font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 6)
            }

            // Notes / Info
            if currentScript.notes != "" || isEditing {
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

            if currentScript.info != "" || isEditing {
                Section(header: Text("Info").bold()) {
                    if isEditing {
                        TextEditor(text: $info)
                            .frame(minHeight: 60)
                            .border(Color.gray)
                    } else {
                        Text(currentScript.info)
                    }
                }
            }

            // Category and Filename fields
            if isEditing {
                Section(header: Text("Category").bold()) {
                    TextField(currentScript.categoryName, text: $category)
                        .padding(4)
                        .border(Color.gray)
                }

                Section(header: Text("Filename").bold()) {
                    TextField("Filename", text: $filename)
                        .padding(4)
                        .border(Color.gray)
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

            Spacer()
            }
        }

        // Fixed footer: Open in Browser stays visible below the scrollable content
        HStack {
            Spacer()
            Button(action: {
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
            .padding(.vertical, 8)
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
                // Enable read-only preview immediately when the detail view appears
                // so the user can scroll/preview the script without entering Edit mode.
                if !isEditing {
                    showReadOnly = true
                }
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

    // Replace within the currently-loaded script (bodyText) and optionally save to server
    private func replaceInThisScript(replaceAll: Bool) async {
        let match = findText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !match.isEmpty else { return }

        replacementResultMessage = "Working..."
        progress.showProgress()

        var changed = false
        var replacements = 0

        do {
            if useRegex || wholeWord {
                var pattern = match
                if !useRegex { pattern = NSRegularExpression.escapedPattern(for: match) }
                if wholeWord { pattern = "\\b" + pattern + "\\b" }
                let options: NSRegularExpression.Options = caseInsensitive ? [.caseInsensitive] : []
                let re = try NSRegularExpression(pattern: pattern, options: options)
                let range = NSRange(bodyText.startIndex..., in: bodyText)
                if replaceAll {
                    let matches = re.numberOfMatches(in: bodyText, options: [], range: range)
                    if matches > 0 {
                        bodyText = re.stringByReplacingMatches(in: bodyText, options: [], range: range, withTemplate: replaceText)
                        replacements = matches
                        changed = true
                    }
                } else {
                    if let m = re.firstMatch(in: bodyText, options: [], range: range), let r = Range(m.range, in: bodyText) {
                        bodyText.replaceSubrange(r, with: replaceText)
                        replacements = 1
                        changed = true
                    }
                }
            } else {
                if caseInsensitive {
                    if replaceAll {
                        let occurrences = bodyText.lowercased().components(separatedBy: match.lowercased()).count - 1
                        if occurrences > 0 {
                            bodyText = bodyText.replacingOccurrences(of: match, with: replaceText, options: .caseInsensitive, range: nil)
                            replacements = occurrences
                            changed = true
                        }
                    } else {
                        if let r = bodyText.range(of: match, options: .caseInsensitive) {
                            bodyText.replaceSubrange(r, with: replaceText)
                            replacements = 1
                            changed = true
                        }
                    }
                } else {
                    if replaceAll {
                        let occurrences = bodyText.components(separatedBy: match).count - 1
                        if occurrences > 0 {
                            bodyText = bodyText.replacingOccurrences(of: match, with: replaceText)
                            replacements = occurrences
                            changed = true
                        }
                    } else {
                        if let r = bodyText.range(of: match) {
                            bodyText.replaceSubrange(r, with: replaceText)
                            replacements = 1
                            changed = true
                        }
                    }
                }
            }

            if changed {
                // persist to server
                try await networkController.updateScript(server: server, scriptName: scriptName.isEmpty ? networkController.scriptDetailed.name : scriptName, scriptContent: bodyText, scriptId: String(scriptID), authToken: networkController.authToken, category: category, filename: filename, info: info, notes: notes)
            }
        } catch {
            print("Replace failed: \(error)")
        }

        progress.endProgress()
        replacementResultMessage = "Replacements made: \(replacements)"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { replacementResultMessage = "" }
    }

    // Inject helper for this single script
    private func injectAfterFirstInThisScript() async {
        let match = injectMatchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !match.isEmpty else { return }

        injectResultMessage = "Working..."
        progress.showProgress()

        var inserted = 0
        var lines = bodyText.components(separatedBy: "\n")
        if let idx = lines.firstIndex(where: { $0.lowercased().contains(match.lowercased()) }) {
            lines.insert(injectInsertText, at: idx + 1)
            inserted = 1
            bodyText = lines.joined(separator: "\n")
            do { try await networkController.updateScript(server: server, scriptName: scriptName.isEmpty ? networkController.scriptDetailed.name : scriptName, scriptContent: bodyText, scriptId: String(scriptID), authToken: networkController.authToken, category: category, filename: filename, info: info, notes: notes) } catch { print("Inject failed: \(error)") }
        }

        progress.endProgress()
        injectResultMessage = "Inserted: \(inserted)"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { injectResultMessage = "" }
    }

    private func injectAfterAllInThisScript() async {
        let match = injectMatchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !match.isEmpty else { return }

        injectResultMessage = "Working..."
        progress.showProgress()

        var lines = bodyText.components(separatedBy: "\n")
        var indices: [Int] = []
        for (i, line) in lines.enumerated() {
            if line.lowercased().contains(match.lowercased()) { indices.append(i) }
        }
        var inserted = 0
        if !indices.isEmpty {
            for idx in indices.reversed() {
                lines.insert(injectInsertText, at: idx + 1)
                inserted += 1
            }
            bodyText = lines.joined(separator: "\n")
            do { try await networkController.updateScript(server: server, scriptName: scriptName.isEmpty ? networkController.scriptDetailed.name : scriptName, scriptContent: bodyText, scriptId: String(scriptID), authToken: networkController.authToken, category: category, filename: filename, info: info, notes: notes) } catch { print("Inject failed: \(error)") }
        }

        progress.endProgress()
        injectResultMessage = "Inserted lines: \(inserted)"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { injectResultMessage = "" }
    }
}

//struct PackagesDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        PackagesDetailView()
//    }
//}
