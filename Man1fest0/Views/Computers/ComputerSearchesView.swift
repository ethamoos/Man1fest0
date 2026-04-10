//
//  ComputerSearchesView.swift
//  Man1fest0
//
//  Created by Copilot on 09/04/2026.
//

import SwiftUI

#if os(macOS)
import AppKit
#endif

struct ComputerSearchesView: View {
    
    var selectedResourceType = ResourceType.computerBasic
    
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var xmlController: XmlBrain
    
    @State var server: String
    @State private var showingWarning = false
    
    //  SEARCH AND SELECTIONS
    @State private var searchText = ""
    @State var selectionSearch = AdvancedComputerSearch(id: 0, name: "")
    
    // Keep a selection set for batch operations (delete).
    // Use a Set of IDs for stable selection/highlighting
    @State var selection = Set<Int>()
    
    // Single selected search for the detail pane
    @State private var selectedSearch: AdvancedComputerSearch? = nil
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            Section(header: Text("Computer Searches:").bold().padding()) {
                
                NavigationSplitView {
                    // sidebar
                    VStack(alignment: .leading, spacing: 6) {
                        // Debug header: show current counts and any last error
                        HStack(spacing: 12) {
                            Text("Search count: \(networkController.allAdvancedComputerSearches.count)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            if let err = networkController.lastErrorMessage {
                                Text("Error: \(err)")
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                            }
                            Spacer()
                        }
                        
                        // If no results, show a friendly placeholder and a refresh button
                        if searchResults.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("No Computer Searches found").font(.headline)
                                Text("Try refreshing or check your Jamf connection and credentials.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Button("Refresh") {
                                    Task {
                                        do { try await networkController.getAdvancedComputerSearch("") } catch { print("Refresh failed: \(error)") }
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.blue)
                            }
                            .padding()
                        } else {
                            List(selection: $selection) {
                                ForEach(searchResults, id: \.id) { search in
                                    HStack {
                                        Text(search.name)
                                        Spacer()
                                        Text("ID: \(search.id)")
                                            .foregroundColor(.secondary)
                                    }
                                    .tag(search.id)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        // Set the selection to this item's id so the list highlights it
                                        selection = [search.id]
                                        selectedSearch = search
                                    }
                                }
                            }
                            .onChange(of: selection) { newSelection in
                                if let firstId = newSelection.first, let found = networkController.allAdvancedComputerSearches.first(where: { $0.id == firstId }) {
                                    selectedSearch = found
                                } else {
                                    selectedSearch = nil
                                }
                            }
                            .listStyle(SidebarListStyle())
                            .frame(minWidth: 260)
                            .searchable(text: $searchText, placement: .sidebar)
                        }
                    }
                } detail: {
                    if let firstId = selection.first {
                        ComputerSearchDetailView(searchId: firstId)
                            .environmentObject(networkController)
                            .environmentObject(xmlController)
                    } else {
                        Text("Select a Computer Search to view details")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            
            VStack() {
                
                Button(action: {
                    progress.showProgress()
                    progress.waitForABit()
                    Task {
                        do {
                            try await networkController.getAdvancedComputerSearch("")
                        } catch {
                            print("Failed to fetch advanced computer searches: \(error)")
                        }
                    }
                }) {
#if os(macOS)
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
#else
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.clockwise")
                    }
#endif
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                
                Button(action: {
                    progress.showProgress()
                    progress.waitForABit()
                    showingWarning = true
                }) {
#if os(macOS)
                    HStack(spacing: 10) {
                        Image(systemName: "delete.left")
                        Text("Delete")
                    }
#else
                    HStack(spacing: 10) {
                        Image(systemName: "delete.left")
                    }
#endif
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .shadow(color: .gray, radius: 2, x: 0, y: 2)
                .alert(isPresented: $showingWarning) {
                    Alert(
                        title: Text("Caution!"),
                        message: Text("This action will delete data.\n Always ensure that you have a backup!"),
                        primaryButton: .destructive(Text("I understand!")) {
                            let nc = networkController
                            let srv = server
                            let token = networkController.authToken
                            // Build a Set<AdvancedComputerSearch> from the selected IDs
                            let selSet: Set<AdvancedComputerSearch> = Set(selection.compactMap { id in
                                nc.allAdvancedComputerSearches.first(where: { $0.id == id })
                            })
                            Task {
                                try await nc.batchDeleteAdvancedComputerSearch(selection: selSet, server: srv, authToken: token, resourceType: .advancedComputerSearch)
                            }
                            print("Yes tapped")
                        },
                        secondaryButton: .cancel()
                    )
                }
                
            }
            .padding()
            .onAppear() {
                Task {
                    do {
                        try await networkController.getAdvancedComputerSearch("")
                    } catch {
                        print("Failed to load advanced computer searches on appear: \(error)")
                    }
                }
            }
            .onChange(of: networkController.authToken) { newToken in
                // Reload searches when auth token changes (e.g., on login)
                Task {
                    guard !newToken.isEmpty else { return }
                    do { try await networkController.getAdvancedComputerSearch("") } catch { print("Reload on authToken change failed: \(error)") }
                }
            }
            
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
        
        var searchResults: [AdvancedComputerSearch] {
            let searches = networkController.allAdvancedComputerSearches
            let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                return searches
            } else {
                return searches.filter { $0.name.localizedCaseInsensitiveContains(trimmed) || String(describing: $0.id).localizedCaseInsensitiveContains(trimmed) }
            }
        }
    }
    
    struct ComputerSearchDetailView: View {
        @EnvironmentObject var networkController: NetBrain
        let searchId: Int

        var body: some View {
            Group {
                if let d = networkController.advancedComputerSearchDetailed, d.id == searchId {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(d.name).font(.title)
                        Text("ID: \(d.id)").foregroundColor(.secondary)
                        if let crit = d.criteria {
                            Text("Criteria:").font(.headline)
                            ScrollView { Text(crit).font(.body) }
                        }
                        HStack(spacing: 12) {
                            Button("Open in Browser") {
                                // Prefer opening the Jamf UI page for this advanced computer search.
                                var base = networkController.server.trimmingCharacters(in: .whitespacesAndNewlines)
                                if base.hasSuffix("/") { base.removeLast() }
                                let uiURLString = "\(base)/advancedComputerSearches.html?id=\(searchId)&o=r"
                                if let uiURL = URL(string: uiURLString) {
                                    #if os(macOS)
                                    NSWorkspace.shared.open(uiURL)
                                    #endif
                                } else {
                                    // Fallback: attempt the resource endpoint
                                    if let apiURL = URL(string: networkController.server + "/JSSResource/advancedcomputersearches/id/" + String(searchId)) {
                                        #if os(macOS)
                                        NSWorkspace.shared.open(apiURL)
                                        #endif
                                    }
                                }
                             }
                             .buttonStyle(.bordered)

                            Button("Delete Selection") {
                                 Task {
                                     let setSel: Set<AdvancedComputerSearch> = Set([AdvancedComputerSearch(id: d.id, name: d.name)])
                                     try? await networkController.batchDeleteAdvancedComputerSearch(selection: setSel, server: networkController.server, authToken: networkController.authToken, resourceType: .advancedComputerSearch)
                                 }
                             }
                             .buttonStyle(.borderedProminent)
                             .tint(.red)
                             Spacer()
                         }
                         Spacer()
                     }
                     .padding()
                 } else {
                     Text("Loading...")
                        .task(id: searchId) {
                            do {
                                try await networkController.getDetailAdvancedComputerSearch(userID: String(searchId))
                            } catch {
                                print("Failed to load detail for id \(searchId): \(error)")
                            }
                        }
                 }
            }
        }
    }
}
