#if os(macOS)
import AppKit
#else
import UIKit
#endif

import SwiftUI

struct ScriptsDetailView: View {
    
    var script: ScriptClassic
    var scriptID: Int
    var server: String
    
    @State private var bodyText: String = ""
    @State private var scriptName: String = ""
    @State private var isEditing: Bool = false
    @State private var showReadOnly: Bool = false
    @State private var showSavedToast: Bool = false

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
                    Text(scriptName.isEmpty ? currentScript.name : scriptName)
                        .font(.title)
                        .fontWeight(.semibold)
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
                        // Save: network update + write file to ~/Downloads (macOS) or Documents (iOS) as fallback
                        progress.showProgress()
                        Task {
                            // First attempt network update (preserve existing behavior)
                            do {
                                try await networkController.updateScript(server: server, scriptName: scriptName, scriptContent: bodyText, scriptId: String(describing: scriptID), authToken: networkController.authToken)
                            } catch {
                                print("Failed network save: \(error)")
                            }

                            // Then attempt to write to disk
                            do {
                                let filename = sanitizedFilename(from: scriptName.isEmpty ? "script_\(scriptID)" : scriptName) + ".txt"
                                let savedURL = try saveBodyTextToDownloads(text: bodyText, filename: filename)
                                print("Saved script to: \(savedURL.path)")

                                // On macOS, reveal the file in Finder
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
            }
            .padding([.top, .horizontal])

            Divider()

            // Notes / Info
            if currentScript.notes != "" {
                Section(header: Text("Notes").bold()) {
                    Text(currentScript.notes)
                }
            }

            if currentScript.info != "" {
                Section(header: Text("Info").bold()) {
                    Text(currentScript.info)
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
                    .background(Color(.textBackgroundColor))
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

            Spacer()
        }
        .padding()
        .onAppear() {
            Task {
                try await networkController.getDetailedScript(server: server, scriptID: scriptID, authToken: networkController.authToken)
                bodyText = networkController.scriptDetailed.scriptContents
                scriptName = networkController.scriptDetailed.name
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
}

//struct PackagesDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        PackagesDetailView()
//    }
//}
