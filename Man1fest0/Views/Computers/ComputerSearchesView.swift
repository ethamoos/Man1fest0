//
//  ComputerSearchesView.swift
//  Man1fest0
//
//  Created by Copilot on 09/04/2026.
//

import SwiftUI

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
    @State var selection = Set<AdvancedComputerSearch>()

    // Single selected search for the detail pane
    @State private var selectedSearch: AdvancedComputerSearch? = nil

    var body: some View {

        VStack(alignment: .leading) {

            Section(header: Text("Computer Searches:").bold().padding()) {

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
                    if let search = selectedSearch {
                        ComputerSearchDetailView(search: search)
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
                        // API function currently accepts a userID param but does not use it; pass empty string
                        try await networkController.getAdvancedComputerSearch("")
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
                            let sel = selection
                            Task {
                                try await nc.batchDeleteAdvancedComputerSearch(selection: sel, server: srv, authToken: token)
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
                 // Load advanced computer searches; pass empty userID (parameter currently unused)
                 try await networkController.getAdvancedComputerSearch("")
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
    var search: AdvancedComputerSearch
    var body: some View {
        VStack(alignment: .leading) {
            Text(search.name)
                .font(.title)
                .padding(.bottom, 4)
            Text("ID: \(search.id)")
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
    }
}
