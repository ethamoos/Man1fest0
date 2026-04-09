//
//  ComputerSearchesView.swift
//  Man1fest0
//
//  Created by Amos Deane on 09/04/2026.
//

import SwiftUI

struct ComputerSearchesView: View {
    
    var selectedResourceType = ResourceType.computerBasic
    
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var xmlController: XmlBrain
    
    @State var server: String
    @State private var showingWarning = false
    
    //  ################################################################################
    //  SEARCHES AND SELECTIONS
    //  ################################################################################
    
    @State private var searchText = ""
    @State var selectionSearch = AdvancedComputerSearch(id: "0", name: "")
    @State var mySelection: String = ""
    
    // Keep a selection set for batch operations (delete).
    @State var selection = Set<AdvancedComputerSearch>()
    
    // Single selected search for the detail pane
    @State private var selectedSearch: AdvancedComputerSearch? = nil
    
    let columns = [
        GridItem(.fixed (170)),
        GridItem(.fixed (170)),
    ]
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            Section(header: Text("Advanced Searches:").bold().padding()) {
                
                // NavigationSplitView shows a persistent master list on the left and a detail pane on the right.
                NavigationSplitView {
                    // Master list (supports multi-selection for batch delete via `selection`)
                    List(selection: $selection) {
                        ForEach(searchResults) { search in
                            HStack {
                                Text(search.name)
                                Spacer()
                                Text("ID: \(search.id)")
                                    .foregroundColor(.secondary)
                            }
                            .tag(search)
                            .contentShape(Rectangle())
                        }
                    }
                    .onChange(of: selection) { newSelection in
                        // Keep the detail pane in sync with the list selection
                        if let first = newSelection.first {
                            selectedSearch = first
                        } else {
                            selectedSearch = nil
                        }
                    }
                    .listStyle(SidebarListStyle())
                    .foregroundColor(.blue)
                    .frame(minWidth: 260)
                    .searchable(text: $searchText, placement: .sidebar)
                } detail: {
                    // Detail pane - show selected search's detail view, or a placeholder
                    if let search = selectedSearch {
                        ComputerSearchesDetailView(server: server, search: search)
                            .environmentObject(networkController)
                            .environmentObject(xmlController)
                    } else {
                        Text("Select an Advanced Search to view details")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            
            VStack() {
                
                Button(action: {
                    
                    progress.showProgress()
                    progress.waitForABit()
                    
                    Task {
                        try await networkController.getAdvancedComputerSearch(userID: "")
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
                            // Code to execute when "Yes" is tapped
                            Task {
                                try await networkController.batchDeleteAdvancedComputerSearch(selection: selection, server: server, authToken: networkController.authToken)
                            }
                            print("Yes tapped")
                        },
                        secondaryButton: .cancel()
                    )
                }
                
            }
            .padding()
        }
        
        Divider()
        
        .onAppear() {
            Task {
                try await networkController.getAdvancedComputerSearch(userID: "")
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
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return searches
        } else {
            return searches.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.id.localizedCaseInsensitiveContains(searchText) }
        }
    }
}
