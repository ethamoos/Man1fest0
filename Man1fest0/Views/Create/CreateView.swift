//
//  CreateView.swift

struct CreateBulkTriggerPolicyTabView: View {
    private enum MatchSource: String {
        case preferredTrigger = "preferred-trigger"
        case policyName = "policy-name"
        case generated = "generated"
    }

    private struct BulkTriggerMatch: Identifiable {
        let id = UUID()
        let softwareName: String
        let matchedPolicyName: String
        let matchedPolicyID: Int?
        let selectedTrigger: String
        let source: MatchSource
    }

    var server: String { UserDefaults.standard.string(forKey: "server") ?? "" }

    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var layout: Layout

    @AppStorage("createBulkTrigger.lastScriptID") private var lastScriptID: Int = 0
    @AppStorage("createBulkTrigger.lastScriptName") private var lastScriptName: String = ""
    @AppStorage("createBulkTrigger.lastCategoryID") private var lastCategoryID: Int = -1

    @State private var isImportingFile = false
    @State private var isWorking = false

    @State private var importedFileName = ""
    @State private var importedSoftwareNames: [String] = []
    @State private var matches: [BulkTriggerMatch] = []
    @State private var generatedFromUnmatched: [String] = []

    @State private var selectedScriptID: Int? = nil
    @State private var selectedCategoryID: Int = -1
    @State private var useAutoScriptInstances = true
    @State private var manualScriptInstances = 1

    @State private var newPolicyName = ""
    @State private var createdPolicyForSheet: Policy? = nil

    @State private var showCompletionAlert = false
    @State private var completionMessage = ""
    @State private var showCreateConfirmation = false

    @State private var workflowReady = false
    @State private var workflowStatus = "Preparing policy data…"

    private let triggersPerScript = 8

    private var selectedScript: ScriptClassic? {
        networkController.scripts.first(where: { $0.jamfId == selectedScriptID })
    }

    private var selectedCategory: Category? {
        guard selectedCategoryID > 0 else { return nil }
        return networkController.categories.first(where: { $0.jamfId == selectedCategoryID })
    }

    private var uniqueTriggers: [String] {
        var seen = Set<String>()
        var ordered: [String] = []
        for trigger in matches.map({ $0.selectedTrigger }).filter({ !$0.isEmpty }) {
            if !seen.contains(trigger) {
                seen.insert(trigger)
                ordered.append(trigger)
            }
        }
        return ordered
    }

    private var requiredScriptInstances: Int {
        guard !uniqueTriggers.isEmpty else { return 1 }
        return Int(ceil(Double(uniqueTriggers.count) / Double(triggersPerScript)))
    }

    private var selectedScriptInstances: Int {
        useAutoScriptInstances ? requiredScriptInstances : manualScriptInstances
    }

    private var canCreatePolicy: Bool {
        selectedScript != nil
            && !uniqueTriggers.isEmpty
            && !newPolicyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && selectedScriptInstances >= requiredScriptInstances
    }

    private var creationPreviewText: String {
        let generatedCount = generatedFromUnmatched.count
        let generatedNote = generatedCount == 0 ? "All imported items matched an existing policy trigger." : "\(generatedCount) item(s) were unmatched and will use generated triggers."
        return "Policy: \(newPolicyName)\nCategory: \(selectedCategory?.name ?? "No category assigned")\nTriggers: \(uniqueTriggers.count)\nScript instances: \(selectedScriptInstances)\n\n\(generatedNote)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "tray.and.arrow.down")
                Text("Bulk Trigger Policy from File")
                    .font(.headline)
            }

            Text("Import software names from TXT/CSV, match them to existing policies, and create one trigger-runner policy.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Divider()

            HStack(spacing: 10) {
                Button(action: { isImportingFile = true }) {
                    Label("Import TXT/CSV", systemImage: "doc.badge.plus")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!workflowReady)

                if !importedFileName.isEmpty {
                    Text("File: \(importedFileName)")
                        .font(.subheadline)
                }

                Spacer()

                if isWorking {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            Text(workflowStatus)
                .font(.caption)
                .foregroundColor(workflowReady ? .secondary : .orange)

            HStack(spacing: 16) {
                Text("Applications identified: \(importedSoftwareNames.count)")
                Text("Triggers prepared: \(uniqueTriggers.count)")
                Text("Generated (unmatched): \(generatedFromUnmatched.count)")
            }
            .font(.caption)
            .foregroundColor(.secondary)

            Divider()

            LazyVGrid(columns: layout.columns, spacing: 14) {
                Picker("Runner Script", selection: Binding(
                    get: { selectedScriptID ?? 0 },
                    set: { selectedScriptID = ($0 == 0 ? nil : $0) }
                )) {
                    Text("Select script").tag(0)
                    ForEach(networkController.scripts.sorted(by: { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending })) { script in
                        Text(script.name).tag(script.jamfId)
                    }
                }

                Picker("Category", selection: $selectedCategoryID) {
                    Text("No category assigned").tag(-1)
                    ForEach(networkController.categories.sorted(by: { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending })) { category in
                        Text(category.name).tag(category.jamfId)
                    }
                }
            }

            Toggle("Auto script instances", isOn: $useAutoScriptInstances)
                .toggleStyle(.switch)

            if !useAutoScriptInstances {
                Stepper("Script instances: \(manualScriptInstances)", value: $manualScriptInstances, in: 1...500)
            } else {
                Text("Script instances (auto): \(requiredScriptInstances)")
                    .font(.subheadline)
            }

            if selectedScriptInstances < requiredScriptInstances {
                Text("Increase script instances to at least \(requiredScriptInstances) to fit all triggers.")
                    .foregroundColor(.red)
                    .font(.caption)
            }

            TextField("Policy Name", text: $newPolicyName)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 10) {
                Button(action: { showCreateConfirmation = true }) {
                    Label("Review & Confirm", systemImage: "checkmark.shield")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canCreatePolicy || isWorking)

                if !lastScriptName.isEmpty {
                    Text("Last script: \(lastScriptName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            if !matches.isEmpty {
                List(matches) { item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.softwareName)
                            .font(.body)
                        Text("Trigger: \(item.selectedTrigger)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Source: \(item.source.rawValue)\(item.matchedPolicyName.isEmpty ? "" : " | Policy: \(item.matchedPolicyName)")")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(minHeight: 160)
            }
        }
        .padding()
        .fileImporter(
            isPresented: $isImportingFile,
            allowedContentTypes: [.plainText, UTType(filenameExtension: "csv") ?? .plainText],
            allowsMultipleSelection: false
        ) { result in
            handleImportedFile(result)
        }
        .onAppear {
            if newPolicyName.isEmpty {
                newPolicyName = defaultPolicyName()
            }
            if selectedScriptID == nil {
                selectedScriptID = lastScriptID == 0 ? nil : lastScriptID
            }
            if selectedCategoryID == -1 {
                selectedCategoryID = lastCategoryID
            }

            Task {
                await prepareWorkflowDataIfNeeded()
            }
        }
        .onChange(of: networkController.scripts.count) { _ in
            ensureDefaultScriptSelection()
        }
        .onChange(of: networkController.categories.count) { _ in
            ensureDefaultCategorySelection()
        }
        .alert("Confirm New Bulk Policy", isPresented: $showCreateConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Create", role: .none) {
                Task { await createBulkPolicy() }
            }
            .disabled(!canCreatePolicy)
        } message: {
            Text(creationPreviewText)
        }
        .sheet(item: $createdPolicyForSheet) { policy in
            PolicyDetailView(server: server, policy: policy, policyID: policy.jamfId ?? 0)
        }
        .alert("Bulk Trigger Policy", isPresented: $showCompletionAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(completionMessage)
        }
    }

    private func handleImportedFile(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            completionMessage = "Import failed: \(error.localizedDescription)"
            showCompletionAlert = true
        case .success(let urls):
            guard let url = urls.first else { return }
            importedFileName = url.lastPathComponent

            do {
                let accessed = url.startAccessingSecurityScopedResource()
                defer {
                    if accessed {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                let data = try Data(contentsOf: url)
                guard let content = String(data: data, encoding: .utf8) else {
                    completionMessage = "Could not read the selected file as UTF-8 text."
                    showCompletionAlert = true
                    return
                }

                importedSoftwareNames = parseSoftwareNames(content: content, fileExtension: url.pathExtension)
                Task { await rebuildMatches() }
            } catch {
                completionMessage = "Import failed: \(error.localizedDescription)"
                showCompletionAlert = true
            }
        }
    }

    private func rebuildMatches() async {
        guard !importedSoftwareNames.isEmpty else {
            matches = []
            generatedFromUnmatched = []
            return
        }

        if !workflowReady {
            await prepareWorkflowDataIfNeeded()
        }

        isWorking = true
        defer { isWorking = false }

        let allDetails = networkController.allPoliciesDetailed.compactMap({ $0 })
        guard !allDetails.isEmpty else {
            completionMessage = "Policy lookup failed: detailed policies are not available yet."
            showCompletionAlert = true
            return
        }

        var detailedByID: [Int: PolicyDetailed] = [:]
        for detailed in allDetails {
            if let jamfID = detailed.general?.jamfId {
                detailedByID[jamfID] = detailed
            }
        }

        let candidates: [(id: Int, name: String, normalized: String, triggerOther: String)] = detailedByID.values.compactMap { detailed in
            guard let id = detailed.general?.jamfId,
                  let name = detailed.general?.name else { return nil }
            let trigger = detailed.general?.triggerOther ?? ""
            return (id, name, normalizeName(name), trigger.lowercased())
        }

        var nextMatches: [BulkTriggerMatch] = []
        var unmatched: [String] = []

        for softwareName in importedSoftwareNames {
            let preferred = preferredTrigger(for: softwareName)
            let normalizedSoftware = normalizeName(softwareName)

            if let triggerMatch = candidates.first(where: { $0.triggerOther == preferred }) {
                nextMatches.append(BulkTriggerMatch(
                    softwareName: softwareName,
                    matchedPolicyName: triggerMatch.name,
                    matchedPolicyID: triggerMatch.id,
                    selectedTrigger: preferred,
                    source: .preferredTrigger
                ))
                continue
            }

            if let nameMatch = candidates.first(where: {
                !$0.triggerOther.isEmpty && ($0.normalized == normalizedSoftware || $0.normalized.contains(normalizedSoftware) || normalizedSoftware.contains($0.normalized))
            }) {
                nextMatches.append(BulkTriggerMatch(
                    softwareName: softwareName,
                    matchedPolicyName: nameMatch.name,
                    matchedPolicyID: nameMatch.id,
                    selectedTrigger: nameMatch.triggerOther,
                    source: .policyName
                ))
                continue
            }

            unmatched.append(softwareName)
            nextMatches.append(BulkTriggerMatch(
                softwareName: softwareName,
                matchedPolicyName: "",
                matchedPolicyID: nil,
                selectedTrigger: preferred,
                source: .generated
            ))
        }

        matches = nextMatches
        generatedFromUnmatched = unmatched
    }

    private func createBulkPolicy() async {
        guard let selectedScript else {
            completionMessage = "Please select a runner script before creating the policy."
            showCompletionAlert = true
            return
        }
        guard !uniqueTriggers.isEmpty else {
            completionMessage = "No triggers are prepared yet. Import a TXT/CSV file first."
            showCompletionAlert = true
            return
        }

        isWorking = true
        defer { isWorking = false }

        // Always create the exact number of script instances required to hold all triggers.
        let selectedInstanceCount = requiredScriptInstances
        let triggerChunks = uniqueTriggers.chunked(into: triggersPerScript)

        var scriptPayloads: [NetBrain.PolicyScriptPayload] = []
        for index in 0..<selectedInstanceCount {
            let params = index < triggerChunks.count ? triggerChunks[index] : []
            scriptPayloads.append(
                NetBrain.PolicyScriptPayload(
                    scriptID: selectedScript.jamfId,
                    scriptName: selectedScript.name,
                    parameters4to11: params
                )
            )
        }

        let customTrigger = generatedCustomTrigger(from: newPolicyName)
        do {
            let createdID = try await networkController.createBulkTriggerPolicy(
                server: server,
                authToken: networkController.authToken,
                policyName: newPolicyName,
                customTrigger: customTrigger,
                scripts: scriptPayloads,
                categoryID: String(selectedCategory?.jamfId ?? -1),
                categoryName: selectedCategory?.name ?? "No category assigned"
            )

            lastScriptID = selectedScript.jamfId
            lastScriptName = selectedScript.name
            lastCategoryID = selectedCategoryID

            try? await networkController.getAllPolicies(server: server, authToken: networkController.authToken)

            let unresolvedSummary: String
            if generatedFromUnmatched.isEmpty {
                unresolvedSummary = "All items matched existing policy triggers."
            } else {
                let shortList = generatedFromUnmatched.prefix(15).joined(separator: "\n")
                let tail = generatedFromUnmatched.count > 15 ? "\n...and \(generatedFromUnmatched.count - 15) more" : ""
                unresolvedSummary = "Generated triggers for unmatched items:\n\(shortList)\(tail)"
            }

            completionMessage = "Created policy '\(newPolicyName)'.\n\nTriggers assigned: \(uniqueTriggers.count)\nScript instances: \(selectedInstanceCount)\n\n\(unresolvedSummary)"
            showCompletionAlert = true

            if let createdID {
                let matchedPolicy = networkController.policies.first(where: { $0.jamfId == createdID })
                createdPolicyForSheet = matchedPolicy ?? Policy(jamfId: createdID, name: newPolicyName)
            }
        } catch {
            let detailed = networkController.lastBulkPolicyCreateErrorMessage
            if detailed.isEmpty {
                completionMessage = "Failed to create policy: \(error.localizedDescription)"
            } else {
                completionMessage = "Failed to create policy:\n\(detailed)"
            }
            showCompletionAlert = true
        }
    }

    private func normalizeName(_ value: String) -> String {
        let lowered = value.lowercased()
        let filtered = lowered.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) }
        return String(String.UnicodeScalarView(filtered))
    }

    private func preferredTrigger(for softwareName: String) -> String {
        "install\(normalizeName(softwareName))-latest"
    }

    private func generatedCustomTrigger(from policyName: String) -> String {
        let slug = normalizeName(policyName)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        return "\(slug)-\(formatter.string(from: Date()))"
    }

    private func defaultPolicyName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return "Bulk Install - \(formatter.string(from: Date()))"
    }

    private func ensureDefaultScriptSelection() {
        if selectedScriptID == nil {
            if let preferred = networkController.scripts.first(where: { $0.jamfId == lastScriptID }) {
                selectedScriptID = preferred.jamfId
            } else {
                selectedScriptID = networkController.scripts.sorted(by: {
                    $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }).first?.jamfId
            }
        }
    }

    private func ensureDefaultCategorySelection() {
        let allIDs = Set(networkController.categories.map { $0.jamfId })
        if selectedCategoryID > 0, allIDs.contains(selectedCategoryID) {
            return
        }
        if lastCategoryID > 0, allIDs.contains(lastCategoryID) {
            selectedCategoryID = lastCategoryID
        } else {
            selectedCategoryID = -1
        }
    }

    private func prepareWorkflowDataIfNeeded() async {
        if workflowReady { return }
        isWorking = true
        workflowStatus = "Preparing policy data…"
        defer { isWorking = false }

        do {
            if networkController.scripts.isEmpty {
                workflowStatus = "Loading scripts…"
                try await networkController.getAllScripts()
            }
            ensureDefaultScriptSelection()

            if networkController.categories.isEmpty {
                workflowStatus = "Loading categories…"
                try await networkController.getAllCategories()
            }
            ensureDefaultCategorySelection()

            if networkController.policies.isEmpty {
                workflowStatus = "Loading policies…"
                try await networkController.getAllPolicies(server: server, authToken: networkController.authToken)
            }

            let basicPolicies = networkController.policies.isEmpty ? networkController.allPoliciesConverted : networkController.policies
            if networkController.allPoliciesDetailed.compactMap({ $0 }).isEmpty || !networkController.fetchedDetailedPolicies {
                workflowStatus = "Loading detailed policies for matching…"
                try await networkController.getAllPoliciesDetailed(server: server, authToken: networkController.authToken, policies: basicPolicies)
            }

            workflowReady = true
            workflowStatus = "Ready - import a TXT/CSV file to analyze software names."
        } catch {
            workflowReady = false
            workflowStatus = "Unable to prepare data: \(error.localizedDescription)"
            completionMessage = "Setup failed: \(error.localizedDescription)"
            showCompletionAlert = true
        }
    }

    private func parseSoftwareNames(content: String, fileExtension: String) -> [String] {
        if fileExtension.lowercased() == "csv" {
            let rows = parseCSVRows(content)
            guard !rows.isEmpty else { return [] }

            let header = rows[0].map { normalizedHeaderValue($0) }
            let nameIndex = header.firstIndex(where: { ["name", "software", "application", "app"].contains($0) })
            let dataRows = nameIndex == nil ? rows : Array(rows.dropFirst())
            let columnIndex = nameIndex ?? 0

            let parsed = dataRows.compactMap { row -> String? in
                guard row.indices.contains(columnIndex) else { return nil }
                let value = row[columnIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                return value.isEmpty ? nil : value
            }
            // If we did not detect a header row but the first value looks like one, drop it.
            let deduped = parsed.uniquedPreservingOrder()
            if let first = deduped.first,
               ["name", "software", "application", "app"].contains(normalizedHeaderValue(first)) {
                return Array(deduped.dropFirst())
            }
            return deduped
        }

        let lines = content
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return lines.uniquedPreservingOrder()
    }

    private func normalizedHeaderValue(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\u{feff}", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    // Lightweight CSV row parsing that supports quoted cells and escaped quotes.
    // Row delimiter is always newline; this intentionally does not support multiline quoted cells.
    private func parseCSVRows(_ content: String) -> [[String]] {
        var rows: [[String]] = []
        let normalized = content.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        let lines = normalized.components(separatedBy: "\n")
        let nonEmptyLines = lines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        let delimiter: Character = {
            guard let first = nonEmptyLines.first else { return "," }
            let commaCount = first.filter { $0 == "," }.count
            let semicolonCount = first.filter { $0 == ";" }.count
            let tabCount = first.filter { $0 == "\t" }.count
            if semicolonCount > commaCount && semicolonCount >= tabCount { return ";" }
            if tabCount > commaCount && tabCount > semicolonCount { return "\t" }
            return ","
        }()

        for line in nonEmptyLines {
            rows.append(parseCSVLine(line, delimiter: delimiter))
        }

        return rows.filter { !$0.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) }
    }

    private func parseCSVLine(_ line: String, delimiter: Character) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        var index = line.startIndex

        while index < line.endIndex {
            let char = line[index]

            if char == "\"" {
                let nextIndex = line.index(after: index)
                if inQuotes, nextIndex < line.endIndex, line[nextIndex] == "\"" {
                    current.append("\"")
                    index = line.index(after: nextIndex)
                    continue
                }
                inQuotes.toggle()
                index = nextIndex
                continue
            }

            if char == delimiter, !inQuotes {
                fields.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
                current = ""
            } else {
                current.append(char)
            }
            index = line.index(after: index)
        }

        fields.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
        return fields
    }
}

private extension Array where Element == String {
    func uniquedPreservingOrder() -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for value in self {
            if !seen.contains(value) {
                seen.insert(value)
                result.append(value)
            }
        }
        return result
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [] }
        var chunks: [[Element]] = []
        var index = 0
        while index < count {
            let end = Swift.min(index + size, count)
            chunks.append(Array(self[index..<end]))
            index += size
        }
        return chunks
    }
}

//  Man1fest0
//
//  Created by Amos Deane on 17/11/2023.
//

import SwiftUI
import UniformTypeIdentifiers

struct CreateView: View {
    
    var server: String
    
    @EnvironmentObject var policyController: PolicyBrain
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var importExportController: ImportExportBrain

    
    @State var categoryName = ""
    
    @State private var categoryID = ""
    
    @State var categories: [Category] = []
    
    @State private var computers: [ Computer ] = []
    
    @State var computerID = ""
    
    @State var computerUDID = ""
    
    @State var computerName = ""
    
    @State var currentDetailedPolicy: PoliciesDetailed? = nil
    
    @State var newCategoryName: String = ""
    
    @State var departmentName: String = ""
    
    @State var enableDisable: Bool = true
    
    @State var newGroupName: String = ""
    
    @State private var packageSelection = Set<Package>()
    
    @State private var packagesAssignedToPolicy: [ Package ] = []
    
    @State private var packageID = "0"
    
    @State private var packageName = ""
    
    @State var policyName = ""
    
    @State var scriptName = ""
    
    @State var scriptID = ""
    
    @State private var selectedResourceType = ResourceType.policyDetail
    
    @State private var selection: Package? = nil
    
    @State var selectedComputer: Computer = Computer(id: 0, name: "")
    
    @State var selectedCategory: Category = Category(jamfId: 0, name: "")
    
    @State var selectedDepartment: Department = Department(jamfId: 0, name: "")
    
    @State var selectedScript: Script = Script(id: "", name: "")
    
    @State var selectedPackage: Package = Package(jamfId: 0, name: "", udid: nil)
    
    @State var scriptParameter4: String = ""
    
    @State var scriptParameter5: String = ""
    
    @State var scriptParameter6: String = ""
    
    @State var searchText = ""
    
    @State  var tempUUID = (UUID(uuidString: "") ?? UUID())
    
    @State private var showingWarning = false
    @State private var selectedCreateTab = 0
        
    let columns = [
        GridItem(.fixed(200)),
        GridItem(.flexible()),
    ]
    
    let columns2 = [
        GridItem(.fixed(400)),
        GridItem(.flexible()),
    ]
    
    var body: some View {
        
        ScrollView {
            
            VStack(alignment: .leading, spacing: 20) {
                
                // New header: nicer title, subtitle and quick actions
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Create")
                            .font(.title)
                            .fontWeight(.semibold)
                        Text("Create categories, groups, packages and scripts")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        Button(action: {
                            Task {
                                try await networkController.getAllCategories()
                                try await networkController.getAllDepartments()
                            }
                            
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)

                        Button(action: {
                            // open import/export filename if available
                            // keep as info-only quick action
                        }) {
                            Image(systemName: "square.and.arrow.down")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.03)))

                //  ################################################################################
                //  TabView - TAB
                //  ################################################################################
                
                VStack {
                    HStack {
                        Text("Create Tool")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Picker("Create Tool", selection: $selectedCreateTab) {
                            Label("General", systemImage: "square.and.pencil").tag(0)
                            Label("Bulk Trigger Policy", systemImage: "list.bullet.clipboard").tag(1)
                        }
                        .pickerStyle(.menu)
                        Spacer()
                    }
                    .padding(.horizontal)

                    Group {
                        if selectedCreateTab == 0 {
                            CreateGeneralTabView(selectedFilename: $importExportController.selectedFilename)
                        } else {
                            CreateBulkTriggerPolicyTabView()
                        }
                    }
                    .padding()
                }
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.02)))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.04)))
                
            }
            
            if progress.showProgressView {
                
                ProgressView {
                    Text("Processing")
                        .padding()
                }
                
            } else {
                Text("")
            }
        }
        .onAppear {
            
            print("CreateView appeared - connecting")
            
            Task {
                try await networkController.getAllPackages()
                try await networkController.getAllScripts()
                try await networkController.getAllDepartments()
                try await networkController.getAllCategories()
            }
        }
        .padding()
        
    }
}



//              ################################################################################
//              push package and new policy
//              ################################################################################


//                LazyVGrid(columns: columns, spacing: 20) {
//
//                    Group {

//                        VStack {
//
//                            TextField("Policy Name", text: $policyName)
//                        }

//                        HStack {

//                            Button(action: {
//
//                                networkController.pushPackage(server: server,authToken: authToken, policyName: policyName, packageName: selectedPackage.name, packageID: Int(selectedPackage.jamfId ) , computerID: $selectedComputer.id, computerName: selectedComputer.name, computerUDID: String(describing: tempUUID), resourceType: selectedResourceType)
//
//                                print("Push Package:\(Int(selectedPackage.jamfId )) to:\($selectedComputer.name)")
//
//                            }) {
//                                HStack(spacing: 10) {
//                                    //                                        Image(systemName: "delete.left.fill")
//                                    Text("Push Package")
//                                }
//                            }
//
//                            Button(action: {
//
//                                networkController.createNewPolicy(server: server,authToken: authToken, policyName: policyName, customTrigger: "", categoryID: String(describing: selectedCategory.jamfId), category: selectedCategory.name, departmentID: String(describing: selectedDepartment.jamfId) , department: selectedDepartment.name , scriptID: String(describing: selectedScript.jamfId), scriptName: selectedScript.name, scriptParameter4: scriptParameter4 , scriptParameter5: scriptParameter5 , scriptParameter6: scriptParameter6 , resourceType: selectedResourceType, notificationName: policyName, notificationStatus: "true")
//
//
//                                print("New Policy:\(Int(selectedPackage.jamfId )) to:\($selectedComputer.name)")
//
//                            }) {
//                                HStack(spacing: 10) {
//                                    Image(systemName: "plus.circle.fill")
//                                    Text("New Policy")
//                                }
//                            }
//                        }
//                    }
//                }
