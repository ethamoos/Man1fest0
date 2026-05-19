// ScriptUsageViewJson.swift
//  Man1fest0
//
//  Created by Amos Deane on 24/11/2023.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

struct ScriptUsageView: View {
    
    var server: String
    
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var policyController: PolicyBrain
    
    @State private var searchText = ""
    // Toggle to show failed-policy debug panel (click missing count to toggle)
    @State private var showDetailedFetchDebug: Bool = false
    
    @State var assignedScripts: [PolicyScripts] = []
    @State var assignedScriptsArray: [String] = []
    @State var assignedScriptsByNameDict: [String: String] = [:]
    @State var assignedScriptsByNameSet = Set<String>()
    //    ########################################
    //    SUMMARIES
    //    ########################################

    @State var clippedScripts = Set<String>()
    @State var unassignedScriptsSet = Set<String>()
    @State var unassignedScriptsArray: [String] = []
    @State var unassignedScriptsByNameDict: [String: String] = [:]
    
    @State var allScripts: [ScriptClassic] = []
    @State var allScriptsByNameDict: [String: String] = [:]
    @State var allScriptsByNameSet = Set<String>()
    @State var totalScriptsNotUsed = 0

    // Computed results for the Unassigned Scripts list (filtered by `unassignedFilter`)
    private var unassignedSearchResults: [String] {
        let all = Array(unassignedScriptsSet)
        if unassignedFilter.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return all.sorted()
        }
        let q = unassignedFilter.lowercased()
        return all.filter { $0.lowercased().contains(q) }.sorted()
    }

    //    ########################################
    //    Selections
    //    ########################################
    
    @State var selection = Set<String>()
    @State var selectedKey: [String] = []
    @State var selectedValue: String = ""
    // Filter text for the unassigned scripts list
    @State var unassignedFilter: String = ""
    // Filter text for the assigned scripts list
    @State var assignedFilter: String = ""

    // Rename tools state for scripts
    @State private var toolsNameAction: String = "removelast"
    @State private var toolsCountString: String = "1"
    @State private var toolsMatchString: String = ""
    @State private var toolsReplacementString: String = ""
    @State private var showScriptRenameConfirmation: Bool = false
    // Color for prominent disclosure chevron in rename tools
    @State private var renameDisclosureColorName: String = "blue"

    // Small helper views to reduce type-checking complexity in large body
    @ViewBuilder
    private func allScriptRow(_ script: ScriptClassic) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "applescript")
                .foregroundColor(.blue)
            Text(script.name)
                .lineLimit(1)
            Spacer()
            Text("#\(script.jamfId)")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private func assignedScriptRow(_ script: String, value: String) -> some View {
        HStack {
            Label(script, systemImage: "checkmark.seal")
            Spacer()
            if value.isEmpty {
                Text("#?")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else {
                Text("#\(value)")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private func unassignedScriptRow(_ script: String, value: String) -> some View {
        HStack {
            Label(script, systemImage: "xmark.circle")
                .foregroundColor(.orange)
            Spacer()
            if value.isEmpty {
                Text("#?")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else {
                Text("#\(value)")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .padding(.vertical, 6)
    }

    // Computed cross-platform background color for boxed headings
    private var sectionBoxBackground: Color {
        #if os(iOS)
        return Color(.secondarySystemBackground)
        #elseif os(macOS)
        return Color(NSColor.windowBackgroundColor)
        #else
        return Color.gray.opacity(0.08)
        #endif
    }

    // Computed results for the Assigned Scripts list (filtered by `assignedFilter`)
    private var assignedSearchResults: [String] {
        let all = Array(assignedScriptsByNameDict.keys)
        if assignedFilter.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return all.sorted()
        }
        let q = assignedFilter.lowercased()
        return all.filter { $0.lowercased().contains(q) }.sorted()
    }

    // Policy fetch status text shown in the UI (driven by detailedPoliciesProgress)
    private var policyFetchStatusText: String {
        if networkController.isFetchingDetailedPolicies {
            return "Fetching detailed policies…"
        }
        let expected = networkController.detailedPoliciesProgress.expected
        let loaded = networkController.detailedPoliciesProgress.loaded
        let failed = networkController.detailedPoliciesProgress.failedIDs.count
        if networkController.fetchedDetailedPolicies && failed == 0 {
            return "Detailed policies: Done"
        } else if networkController.fetchedDetailedPolicies && failed > 0 {
            return "Detailed policies: Failed (\(failed))"
        } else if expected > 0 {
            return "Detailed policies: \(loaded) / \(expected)"
        } else {
            return "Detailed policies: Idle"
        }
    }

    private var policyFetchStatusColor: Color {
        if networkController.isFetchingDetailedPolicies {
            return .red
        }
        let failed = networkController.detailedPoliciesProgress.failedIDs.count
        if networkController.fetchedDetailedPolicies && failed == 0 {
            return .green
        } else if networkController.fetchedDetailedPolicies && failed > 0 {
            return .blue
        } else {
            return .secondary
        }
    }
    
    // Computed property: are detailed policies fully downloaded?
    private var detailedPoliciesComplete: Bool {
        let expected = networkController.detailedPoliciesProgress.expected
        let loaded = networkController.detailedPoliciesProgress.loaded
        // Treat as complete if the controller flag is set, if we have any detailed entries, or when expected==loaded
        return networkController.fetchedDetailedPolicies || loaded > 0 || (expected > 0 && loaded == expected)
    }

    @State var totalAvailableHeight: CGFloat = 600
    // Ratios for the three vertical panes (sum should be 1.0)
    @State private var paneRatios: [CGFloat] = [0.33, 0.33, 0.34]
    // Minimum heights (in points) for each pane
    private let paneMinHeight: CGFloat = 120

    var body: some View {
        // Thin wrapper so the compiler doesn't need to type-check one massive expression.
        AnyView(mainBody)
    }

    // The real, large view tree is moved here to reduce type-check complexity of `body`.
    @ViewBuilder
    private var mainBody: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Script Usage")
                        .font(.title)
                        .fontWeight(.semibold)
                    Text("Overview of scripts and where they are used")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Note: Analyse/Refresh controls moved to bottom toolbar to keep UI consistent (one set of controls)
             }
             .padding([.top, .horizontal])

            // Policy detailed fetch status and live count (was present in v1.58)
            HStack(alignment: .center, spacing: 8) {
                // spinner when actively fetching
                if networkController.isFetchingDetailedPolicies {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(policyFetchStatusText)
                        .font(.subheadline)
                        .foregroundColor(policyFetchStatusColor)
                    // show loaded / expected and make missing clickable to show failed IDs
                    let expected = networkController.detailedPoliciesProgress.expected
                    let loaded = networkController.detailedPoliciesProgress.loaded
                    let missing = max(0, expected - loaded)
                    HStack(spacing: 6) {
                        if missing > 0 {
                            Button(action: { showDetailedFetchDebug.toggle() }) {
                                Text("\(loaded) / \(expected) (missing: \(missing))")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
//                                    .underline()
                            }
                            .buttonStyle(.plain)
                            .help("Click to show failed policy IDs and retry them")
                        } else {
                            Text("\(loaded) / \(expected)")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal)

            // When the user toggles the debug panel, show failed policy IDs (if any) and a retry action
            if showDetailedFetchDebug {
                VStack(alignment: .leading, spacing: 6) {
                    if networkController.detailedPoliciesProgress.failedIDs.count > 0 {
                        ForEach(networkController.detailedPoliciesProgress.failedIDs, id: \.self) { id in
                            Text(id)
                                .font(.caption2)
                                .foregroundColor(.red)
                        }

                        HStack { Spacer()
                            Button(action: {
                                Task {
                                    progress.showExtendedProgress()
                                    let failedIDs = networkController.detailedPoliciesProgress.failedIDs
                                    let policiesToRetry = networkController.allPoliciesConverted.filter { p in
                                        guard let pid = p.jamfId else { return false }
                                        return failedIDs.contains(String(pid))
                                    }
                                    if !policiesToRetry.isEmpty {
                                        do {
                                            try await networkController.getAllPoliciesDetailed(server: server, authToken: networkController.authToken, policies: policiesToRetry)
                                        } catch {
                                            print("Retry failed policies error: \(error)")
                                        }
                                    }
                                    progress.endExtendedProgress()
                                }
                            }) {
                                Text("Retry Failed")
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                    } else {
                        Text("No failed policy IDs to show")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
            }

            if networkController.scripts.count == 0 {
                VStack(alignment: .center) {
                    Spacer()
                    Text("No scripts available yet — fetching from server...")
                        .foregroundColor(.secondary)
                        .padding()
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).fill(sectionBoxBackground))
                .padding(.horizontal)
            } else {
                // Resizable three-pane layout
                GeometryReader { geo in
                    // Reserve some vertical space for the fixed toolbar so panes don't push the toolbar off-screen
                    let toolbarReservedHeight: CGFloat = 72
                    // update totalAvailableHeight for gestures and min enforcement
                    let totalH = max(geo.size.height - toolbarReservedHeight, paneMinHeight * 3) // leave reserved space for toolbar
                    Color.clear.onAppear { totalAvailableHeight = totalH }

                    VStack(spacing: 0) {
                        // Top pane: All Scripts
                        VStack(alignment: .leading, spacing: 8) {
                            Text("All Scripts")
                                .font(.headline)
                                .padding(.horizontal)

                            List {
                                ForEach(searchResults, id: \.self) { script in
                                    allScriptRow(script)
                                }
                            }
                            .listStyle(.inset)
                            .searchable(text: $searchText)
                        }
                        .frame(height: max(paneMinHeight, totalH * paneRatios[0]))
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.windowBackgroundColor)).shadow(color: Color.black.opacity(0.02), radius: 2))
                        .padding(.horizontal)

                        // Custom drag handle between top and middle
                        ZStack {
                            Color.clear
                            HStack(spacing: 6) {
                                Capsule().frame(width: 36, height: 4).foregroundColor(Color.secondary.opacity(0.5))
                                Capsule().frame(width: 12, height: 4).foregroundColor(Color.secondary.opacity(0.4))
                                Capsule().frame(width: 8, height: 4).foregroundColor(Color.secondary.opacity(0.35))
                            }
                        }
                        .frame(height: 18)
                        .contentShape(Rectangle())
                        .gesture(DragGesture(minimumDistance: 1).onChanged { value in
                            let delta = value.translation.height
                            let deltaRatio = delta / totalH
                            var r0 = paneRatios[0] + deltaRatio
                            var r1 = paneRatios[1] - deltaRatio
                            let minRatio = paneMinHeight / totalH
                            if r0 < minRatio { r1 -= (minRatio - r0); r0 = minRatio }
                            if r1 < minRatio { r0 -= (minRatio - r1); r1 = minRatio }
                            paneRatios[0] = max(min(r0, 1.0 - minRatio*2), minRatio)
                            paneRatios[1] = max(min(r1, 1.0 - minRatio), minRatio)
                            paneRatios[2] = max(0.0, 1.0 - paneRatios[0] - paneRatios[1])
                        })
                        .onHover { hovering in
                            #if os(macOS)
                            if hovering { NSCursor.resizeUpDown.set() } else { NSCursor.arrow.set() }
                            #endif
                        }

                        // Middle pane: Assigned Scripts
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Assigned Scripts: \(assignedScriptsByNameDict.count)")
                                    .font(.headline)
                                Spacer()
                                if networkController.isFetchingDetailedPolicies {
                                    HStack(spacing: 6) {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                            .scaleEffect(0.8)
                                        Text("Updating…")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    }
                                    .padding(.trailing)
                                }
                            }
                            .padding(.horizontal)

                            HStack {
                                TextField("Filter assigned scripts", text: $assignedFilter)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding(.horizontal)

                                if !assignedFilter.isEmpty {
                                    Button(action: { assignedFilter = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.trailing)
                                }
                            }

                            List(selection: $selection) {
                                ForEach(assignedSearchResults, id: \.self) { script in
                                    // Use the local copy of the mapping to avoid complex expressions involving environment objects
                                    let scriptValue = assignedScriptsByNameDict[script] ?? ""
                                    assignedScriptRow(script, value: scriptValue)
                                }
                            }
                            .listStyle(.inset)
                        }
                        .frame(height: max(paneMinHeight, totalH * paneRatios[1]))
                        .background(RoundedRectangle(cornerRadius: 10).fill(sectionBoxBackground))
                        .padding(.horizontal)

                        // Custom drag handle between middle and bottom
                        ZStack {
                            Color.clear
                            HStack(spacing: 6) {
                                Capsule().frame(width: 36, height: 4).foregroundColor(Color.secondary.opacity(0.5))
                                Capsule().frame(width: 12, height: 4).foregroundColor(Color.secondary.opacity(0.4))
                                Capsule().frame(width: 8, height: 4).foregroundColor(Color.secondary.opacity(0.35))
                            }
                        }
                        .frame(height: 18)
                        .contentShape(Rectangle())
                        .gesture(DragGesture(minimumDistance: 1).onChanged { value in
                            let delta = value.translation.height
                            let deltaRatio = delta / totalH
                            var r1 = paneRatios[1] + deltaRatio
                            var r2 = paneRatios[2] - deltaRatio
                            let minRatio = paneMinHeight / totalH
                            if r1 < minRatio { r2 -= (minRatio - r1); r1 = minRatio }
                            if r2 < minRatio { r1 -= (minRatio - r2); r2 = minRatio }
                            paneRatios[1] = max(min(r1, 1.0 - minRatio), minRatio)
                            paneRatios[2] = max(min(r2, 1.0 - paneRatios[0] - minRatio), minRatio)
                            paneRatios[0] = max(0.0, 1.0 - paneRatios[1] - paneRatios[2])
                        })
                        .onHover { hovering in
                            #if os(macOS)
                            if hovering { NSCursor.resizeUpDown.set() } else { NSCursor.arrow.set() }
                            #endif
                        }

                        // Bottom pane: Unassigned Scripts
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Scripts not in use: \(unassignedScriptsSet.count)")
                                    .sectionHeading(style: .boxed)
                                    .font(.headline)
                                Spacer()
                                if networkController.isFetchingDetailedPolicies {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .scaleEffect(0.8)
                                }
                            }
                            .padding(.horizontal)

                            HStack {
                                TextField("Filter unassigned scripts", text: $unassignedFilter)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding(.horizontal)

                                if !unassignedFilter.isEmpty {
                                    Button(action: { unassignedFilter = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.trailing)
                                }
                            }

                            List(selection: $selection) {
                                ForEach(unassignedSearchResults, id: \.self) { script in
                                    // Localize the lookup result to help the compiler type-check this view
                                    let scriptValue = allScriptsByNameDict[script] ?? ""
                                    unassignedScriptRow(script, value: scriptValue)
                                }
                            }
                            .listStyle(.inset)
                        }
                        .frame(height: max(paneMinHeight, totalH * paneRatios[2]))
                        .background(RoundedRectangle(cornerRadius: 10).fill(sectionBoxBackground))
                        .padding(.horizontal)

                        Spacer(minLength: 6)
                    }
                    .padding(.vertical)
                }
            }

            // Bottom action toolbar (fixed area reserved above via toolbarReservedHeight)
            HStack(spacing: 12) {
                // Delete selected scripts
                Button(action: {
                    // Confirm and delete selected items
                    let items = Array(selection)
                    guard items.count > 0 else { return }
                    progress.showProgress()
                    Task {
                        await performDeleteSelection(items)
                        // Clear selection on main actor
                        await MainActor.run {
                            selection.removeAll()
                        }
                    }
                }) {
                    Text("Delete Selection")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(selection.isEmpty)

                Spacer()

                // Analyse Data (recompute scripts in use based on policies)
                Button(action: {
                    Task {
                        progress.showExtendedProgress()
                        // Ensure we have policies detailed; if not, trigger them
                        if networkController.allPoliciesDetailed.isEmpty {
                            try? await networkController.getAllPolicies(server: server, authToken: networkController.authToken)
                        }
                        // Recompute scripts assigned/unassigned
                        policyController.getScriptsInUse(allPoliciesDetailed: networkController.allPoliciesDetailed)
                        policyController.getScriptValues(allScripts: networkController.scripts)
                        // small delay to ensure UI updates
                        try? await Task.sleep(nanoseconds: 200_000_000)
                        progress.endExtendedProgress()
                    }
                }) {
                    Text("Analyse Data")
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                // Enable once at least some detailed policies exist
                .disabled(!detailedPoliciesComplete)

                // Refresh policy detailed data
                Button(action: {
                    networkController.allPoliciesDetailed.removeAll()
                    Task {
                        try? await networkController.getAllPoliciesDetailed(server: server, authToken: networkController.authToken, policies: networkController.allPoliciesConverted)
                    }
                }) {
                    Text("Refresh Policy Data")
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
            .padding()

            // Rename tools for scripts (operate on selected script names)
            ProminentDisclosure(indicatorColor: prominentDisclosureColorForName(renameDisclosureColorName)) {
                HStack(spacing: 8) {
                    Text("Rename Tools")
                        .font(.headline)
                    Spacer()
                    Menu {
                        ForEach(["blue","green","red","orange","purple","gray"], id: \.self) { name in
                            Button(action: { renameDisclosureColorName = name }) {
                                HStack {
                                    Circle()
                                        .fill(prominentDisclosureColorForName(name))
                                        .frame(width: 10, height: 10)
                                    Text(name.capitalized)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(prominentDisclosureColorForName(renameDisclosureColorName))
                                .frame(width: 12, height: 12)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                        }
                    }
                    .menuStyle(BorderlessButtonMenuStyle())
                }
            } content: {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Action", selection: $toolsNameAction) {
                        Text("Remove last chars").tag("removelast")
                        Text("Remove first chars").tag("removefirst")
                        Text("Replace last chars").tag("replacelast")
                        Text("Replace first chars").tag("replacefirst")
                        Text("Replace all occurrences").tag("replaceall")
                        Text("Add last characters").tag("addlast")
                        Text("Add first characters").tag("addfirst")
                    }
                    .pickerStyle(.segmented)

                    HStack(spacing: 8) {
                        if toolsNameAction == "removelast" || toolsNameAction == "replacelast" || toolsNameAction == "removefirst" || toolsNameAction == "replacefirst" {
                            TextField("Count", text: $toolsCountString)
                                .frame(width: 80)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        if toolsNameAction == "replacelast" || toolsNameAction == "replaceall" || toolsNameAction == "replacefirst" || toolsNameAction == "addlast" || toolsNameAction == "addfirst" {
                            TextField("Replacement", text: $toolsReplacementString)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        if toolsNameAction == "replaceall" {
                            TextField("Match", text: $toolsMatchString)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        Spacer()
                        Button(action: {
                            let countInt = Int(toolsCountString) ?? 0
                            progress.showProgress()
                            progress.waitForABit()
                            Task {
                                for id in selection {
                                    do {
                                        try await networkController.getDetailedScript(scriptID: String(id))
                                    } catch {
                                        print("Failed to load detailed script for id \(id): \(error)")
                                    }
                                    networkController.updateScriptNameLogical(server: server, authToken: networkController.authToken, scriptID: String(id), action: toolsNameAction, count: countInt, match: toolsMatchString, replacement: toolsReplacementString)
                                    try? await Task.sleep(nanoseconds: 200_000_000)
                                }
                                do { try await networkController.getScripts(server: server, authToken: networkController.authToken) } catch { print("Failed to refresh scripts after rename: \(error)") }
                                progress.endProgress()
                            }
                        }) {
                            Text("Run on Selected")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(selection.isEmpty)
                    }
                }
                .padding()
            }
            .alert("Confirm Rename", isPresented: $showScriptRenameConfirmation) {
                Button("Proceed", role: .destructive) {
                    let countInt = Int(toolsCountString) ?? 0
                    runScriptRenameForSelected(countInt: countInt)
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You're about to perform renames across multiple scripts. This action cannot be undone. Proceed?")
            }

            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            // Initial data load
            Task {
                progress.showProgress()
                do {
                    try await networkController.getAllScripts()
                    try await networkController.getAllPolicies(server: server)
                    
                } catch {
                    print("Failed to load scripts/policies: \(error)")
                    networkController.publishError(error, title: "Failed to load scripts/policies")
                }
                progress.endProgress()
                
            }
            
            
            if networkController.fetchedDetailedPolicies == false {
                
                print("fetchedDetailedPolicies is set to false - running getAllPoliciesDetailed")
                Task {
                    try await networkController.getAllPoliciesDetailed(server: server, authToken: networkController.authToken, policies: networkController.allPoliciesConverted)
                    
                }
                if networkController.allPoliciesDetailed.count == networkController.policies.count {
                    print("Detailed policies have downloaded - analyse usage")
               
                } else {
                    print("Waiting for detailed policies to download")
                    progress.showExtendedProgress()
                    progress.currentProgress = 0.25
                    if backgroundTasks.unassignedPackagesArray.count > 0 {
                        progress.currentProgress = 0.5
                    }
                    print("End extended progress")
                    progress.endExtendedProgress()
                }

                print("Setting: fetchedDetailedPolicies to true")
                networkController.fetchedDetailedPolicies = true
                
            } else {
                print("fetchedDetailedPolicies has run - ignoring")
            }
            
            
        }
        .onChange(of: networkController.scripts) { _ in
            // Scripts list updated: recompute local value maps
            getScriptValues()
            // After the script name/id map is updated, recompute assigned/unassigned
            recomputeAssignedUnassignedFromPolicies()
        }
        .onChange(of: policyController.assignedScriptsByNameDict) { _ in
            // If PolicyBrain's assigned mapping changes (e.g. via Analyse Data), refresh
            refreshAssignedScripts()
            recomputeAssignedUnassignedFromPolicies()
        }
        // Automatically recompute assigned/unassigned when detailed policies arrive
        .onChange(of: networkController.allPoliciesDetailed) { _ in
            recomputeAssignedUnassignedFromPolicies()
        }
        .onChange(of: assignedFilter) { _ in
            // assigned filter changed - nothing else needed as the list is computed
        }
        .onChange(of: unassignedFilter) { _ in
            // Unassigned filter text changed: update unassigned scripts list
            updateUnassignedScripts()
        }
     }
    
    // MARK: - Local Data Handling
    
    private func getScriptValues() {
        // Compute local maps of script names to IDs and vice versa, for fast lookup
        allScriptsByNameDict = [:]
        allScriptsByNameSet = Set<String>()
        for script in networkController.scripts {
            allScriptsByNameDict[script.name] = String(describing: script.jamfId)
            allScriptsByNameSet.insert(script.name)
        }
        
        // Assigned scripts: take the mapping provided by PolicyBrain but
        // compute assigned/unassigned using Jamf IDs to avoid mismatches
        // caused by name differences (case, whitespace, etc.).
        assignedScriptsByNameDict = policyController.assignedScriptsByNameDict
        assignedScriptsByNameSet = Set(assignedScriptsByNameDict.keys)

        // Build sets of IDs (strings) for robust subtraction
        let allIDsSet: Set<String> = Set(allScriptsByNameDict.values)
        let assignedIDsSet: Set<String> = Set(assignedScriptsByNameDict.values)

        // Unassigned IDs are those present in all scripts but not in assigned IDs
        let unassignedIDs = allIDsSet.subtracting(assignedIDsSet)

        // Map unassigned IDs back to script names for display
        unassignedScriptsSet = Set(allScriptsByNameDict.compactMap { name, id in
            return unassignedIDs.contains(id) ? name : nil
        })

        // Update state arrays for views
        assignedScriptsArray = Array(assignedScriptsByNameDict.values)
        assignedScripts = policyController.assignedScripts
        unassignedScriptsArray = Array(unassignedScriptsSet)
    }
    
    private func refreshAssignedScripts() {
        // Refresh the list of assigned scripts based on the current policyController data
         assignedScriptsByNameDict = policyController.assignedScriptsByNameDict
        assignedScriptsByNameSet = Set(assignedScriptsByNameDict.keys)
        assignedScriptsArray = Array(assignedScriptsByNameDict.values)

        // Recompute unassigned scripts whenever assigned mapping changes
        // Use ID-based subtraction to avoid name-matching pitfalls
        let allIDsSet: Set<String> = Set(allScriptsByNameDict.values)
        let assignedIDsSet: Set<String> = Set(assignedScriptsByNameDict.values)
        let unassignedIDs = allIDsSet.subtracting(assignedIDsSet)
        unassignedScriptsSet = Set(allScriptsByNameDict.compactMap { name, id in
            return unassignedIDs.contains(id) ? name : nil
        })
        unassignedScriptsArray = Array(unassignedScriptsSet)
    }

    private func recomputeAssignedUnassignedFromPolicies() {
        // Build name->id and id->name maps from the master scripts list
        let nameToId = allScriptsByNameDict
        var idToName: [String: String] = [:]
        for (name, id) in nameToId {
            idToName[id] = name
        }

        // Collect assigned IDs referenced by any detailed policy
        var assignedIDs = Set<String>()
        for eachPolicy in networkController.allPoliciesDetailed {
            guard let scriptsFound = eachPolicy?.scripts else { continue }
            for script in scriptsFound {
                if let sid = script.jamfId {
                    assignedIDs.insert(String(describing: sid))
                }
            }
        }

        // Build assigned name->id mapping for display (use name if available, else fallback to id placeholder)
        var assignedNameToId: [String: String] = [:]
        for id in assignedIDs {
            if let name = idToName[id] {
                assignedNameToId[name] = id
            } else {
                let placeholder = "#\(id)"
                assignedNameToId[placeholder] = id
            }
        }

        // Compute unassigned IDs and map back to names
        let allIDsSet = Set(nameToId.values)
        let unassignedIDs = allIDsSet.subtracting(assignedIDs)

        var unassignedNames: [String] = []
        for id in unassignedIDs {
            if let name = idToName[id] {
                unassignedNames.append(name)
            }
        }

        // Update state on main thread
        DispatchQueue.main.async {
            self.assignedScriptsByNameDict = assignedNameToId
            self.assignedScriptsByNameSet = Set(assignedNameToId.keys)
            self.assignedScriptsArray = Array(assignedNameToId.values)

            self.unassignedScriptsSet = Set(unassignedNames)
            self.unassignedScriptsArray = unassignedNames
        }
    }
    
    private func updateUnassignedScripts() {
        // Update the list of unassigned scripts based on the current filter text
        // Compute unassigned using IDs to be robust against name differences
        let allIDsSet: Set<String> = Set(allScriptsByNameDict.values)
        let assignedIDsSet: Set<String> = Set(assignedScriptsByNameDict.values)
        let unassignedIDs = allIDsSet.subtracting(assignedIDsSet)

        var candidates = allScriptsByNameDict.compactMap { name, id in
            return unassignedIDs.contains(id) ? name : nil
        }

        if !unassignedFilter.isEmpty {
            let filter = unassignedFilter.lowercased()
            candidates = candidates.filter { $0.lowercased().contains(filter) }
        }

        unassignedScriptsSet = Set(candidates)
        unassignedScriptsArray = Array(unassignedScriptsSet)
    }

    // Perform deletion for selected display keys (resolves names to Jamf IDs then deletes)
    private func performDeleteSelection(_ selectedItems: [String]) async {
        var idsToDelete: [String] = []

        for raw in selectedItems {
            let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)

            // Try local view dictionary first
            if let id = allScriptsByNameDict[key] {
                idsToDelete.append(id)
                continue
            }

            // Try policyController's dictionary if available
            if let id = policyController.allScriptsByNameDict[key] {
                idsToDelete.append(id)
                continue
            }

            // Fallback: lookup in networkController.scripts by name
            if let s = networkController.scripts.first(where: { $0.name == key }) {
                idsToDelete.append(String(describing: s.jamfId))
                continue
            }

            // If key looks like an ID already, accept it
            if Int(key) != nil {
                idsToDelete.append(key)
                continue
            }

            print("Warning: could not resolve script id for selected item '\(key)'")
        }

        guard idsToDelete.count > 0 else {
            print("No valid script IDs found to delete")
            await MainActor.run { progress.endProgress() }
            return
        }

        for id in idsToDelete {
            do {
                try await networkController.deleteScript(server: server, resourceType: ResourceType.script, itemID: id, authToken: networkController.authToken)
                print("Deleted script id: \(id)")
            } catch {
                print("Failed to delete script id \(id): \(error)")
            }
        }

        // Refresh the scripts list after deletions
        do {
            try await networkController.getAllScripts()
        } catch {
            print("Failed to refresh scripts after delete: \(error)")
        }

        // Recompute local script value maps and hide progress on main actor
        await MainActor.run {
            getScriptValues()
            progress.endProgress()
        }
    }

    // Run logical rename for selected scripts (resolve names->ids then call NetBrain helper)
    private func runScriptRenameForSelected(countInt: Int) {
        progress.showProgress()
        progress.waitForABit()
        let controller = networkController
        let authToken = networkController.authToken
        Task {
            // Resolve selected names to Jamf IDs
            let selectedNames = Array(selection)
            var ids: [String] = []
            for raw in selectedNames {
                let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                if let id = allScriptsByNameDict[key] {
                    ids.append(id)
                    continue
                }
                if let id = policyController.allScriptsByNameDict[key] {
                    ids.append(id)
                    continue
                }
                if let s = networkController.scripts.first(where: { $0.name == key }) {
                    ids.append(String(describing: s.jamfId))
                    continue
                }
                if Int(key) != nil {
                    ids.append(key)
                    continue
                }
                print("Warning: could not resolve script id for selected item '\(key)'")
            }

            for id in ids {
                await controller.updateScriptNameLogical_v2(server: server, authToken: authToken, resourceType: ResourceType.script, scriptID: id, action: toolsNameAction, count: countInt, match: toolsMatchString, replacement: toolsReplacementString)
                try? await Task.sleep(nanoseconds: UInt64(controller.getPolicyRequestDelay() * 1_000_000_000))
            }

            // Refresh scripts and local maps
            try? await controller.getAllScripts()
            await MainActor.run {
                getScriptValues()
                progress.endProgress()
            }
        }
    }

    // Search results filtered by `searchText`
    private var searchResults: [ScriptClassic] {
        let allScripts = networkController.scripts
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
             return allScripts
         }
         let q = searchText.lowercased()
         return allScripts.filter { $0.name.lowercased().contains(q) }
     }
 
}

struct ScriptUsageView_Previews: PreviewProvider {
    static var previews: some View {
        ScriptUsageView(server: "https://example.com")
            .environmentObject(Progress())
            .environmentObject(NetBrain())
            .environmentObject(PolicyBrain())
    }
}

// end of file
