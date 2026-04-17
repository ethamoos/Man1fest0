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
    @State private var unassignedFilter = ""
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

    // Policy fetch status text shown in the UI
    private var policyFetchStatusText: String {
        if networkController.isFetchingDetailedPolicies {
            return "Fetching detailed policies…"
        } else if networkController.fetchedDetailedPolicies && networkController.retryFailedDetailedPolicyCalls.count == 0 {
            return "Detailed policies: Done"
        } else if networkController.fetchedDetailedPolicies && networkController.retryFailedDetailedPolicyCalls.count > 0 {
            return "Detailed policies: Failed (\(networkController.retryFailedDetailedPolicyCalls.count))"
        } else {
            return "Detailed policies: Idle"
        }
    }

    private var policyFetchStatusColor: Color {
        if networkController.isFetchingDetailedPolicies {
            return .red
        } else if networkController.fetchedDetailedPolicies && networkController.retryFailedDetailedPolicyCalls.isEmpty {
            return .green
        } else if networkController.fetchedDetailedPolicies && !networkController.retryFailedDetailedPolicyCalls.isEmpty {
            return .blue
        } else {
            return .secondary
        }
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
                            Text("Assigned Scripts")
                                .font(.headline)
                                .padding(.horizontal)

                            List(selection: $selection) {
                                ForEach(assignedScriptsByNameDict.keys.sorted(), id: \.self) { script in
                                    // Use the local copy of the mapping to avoid complex expressions involving environment objects
                                    let scriptValue = assignedScriptsByNameDict[script] ?? ""
                                    HStack {
                                        Label(script, systemImage: "checkmark.seal")
                                        Spacer()
                                        Text(scriptValue)
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    }
                                    .padding(.vertical, 6)
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
                            Text("Scripts not in use")
                                .sectionHeading(style: .boxed)
                                .font(.headline)
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
                                    HStack {
                                        Label(script, systemImage: "xmark.circle")
                                            .foregroundColor(.orange)
                                        Spacer()
                                        Text(scriptValue)
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    }
                                    .padding(.vertical, 6)
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
        }
        .onChange(of: networkController.scripts) { _ in
            // Scripts list updated: recompute local value maps
            getScriptValues()
        }
        .onChange(of: policyController.assignedScriptsByNameDict) { _ in
            // Assigned scripts mapping updated: refresh assigned scripts list
            refreshAssignedScripts()
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
        
        // Assigned scripts: extract from policyController's data
        assignedScriptsByNameDict = policyController.assignedScriptsByNameDict
        assignedScriptsByNameSet = Set(assignedScriptsByNameDict.keys)
        
        // Unassigned scripts: compute set difference from all scripts
        unassignedScriptsSet = allScriptsByNameSet.subtracting(assignedScriptsByNameSet)
        
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
    }
    
    private func updateUnassignedScripts() {
        // Update the list of unassigned scripts based on the current filter text
        if unassignedFilter.isEmpty {
            unassignedScriptsSet = allScriptsByNameSet.subtracting(assignedScriptsByNameSet)
        } else {
            let filter = unassignedFilter.lowercased()
            unassignedScriptsSet = allScriptsByNameSet.subtracting(assignedScriptsByNameSet).filter { $0.lowercased().contains(filter) }
        }
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
