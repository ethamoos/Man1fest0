//
//  PackagesView.swift
//  Man1fest0
//
//  Created by Amos Deane on 15/09/2022.
//


import SwiftUI

struct PackagesView: View {
    
    var server: String
    var selectedResourceType: ResourceType
    @EnvironmentObject var networkController: NetBrain
    @State var searchText = ""
    @State var selection = Set<Package>()
    @State var packages: [Package] = []

    // Snapshot of filtered results used by the List to reduce UI work
    // Use a computed property for filtering to simplify the view and help the compiler
    private var filteredPackages: [Package] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty {
            return networkController.packages
        } else {
            return networkController.packages.filter { pkg in
                pkg.name.lowercased().contains(q) || (pkg.udid?.lowercased().contains(q) ?? false)
            }
        }
    }

    // Main body required for View conformance
    var body: some View {
        VStack(spacing: 0) {
            headerView
            packagesListView
        }
        .onAppear {
            // ensure packages are loaded when view appears
            handleConnect(resourceType: .packages)
        }
    }

    // Local helper to trigger network loads - matches other views' behavior
    func handleConnect(resourceType: ResourceType) {
        print("PackagesView.handleConnect: \(resourceType)")
        networkController.connect(server: server,resourceType: resourceType, authToken: networkController.authToken)
    }

    // Extracted subviews to help the compiler type-check large SwiftUI bodies
    private var headerView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Packages")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Manage uploaded packages — \(networkController.packages.count) total")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            HStack(spacing: 8) {
                Button(action: { handleConnect(resourceType: .packages) }) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh packages")
                .buttonStyle(.bordered)

#if os(macOS)
//                Button(action: {
//                    // Placeholder for Add package
//                }) {
//                    Image(systemName: "plus")
//                }
//                .help("Add package")
//                .buttonStyle(.bordered)
#endif
            }
        }
        .padding([.horizontal, .top])
    }

    private var packagesListView: some View {
        NavigationView {
            // Simpler, compiler-friendly table-like layout with sortable columns
            VStack(spacing: 0) {
                // Header with searchable field and actions
                HStack {
                    // Column headers which act as sort buttons
                    HStack(spacing: 12) {
                        Picker("Sort by", selection: $sortBy) {
                            Text("Name").tag(SortField.name)
                            Text("ID").tag(SortField.id)
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 220)

                        Button(action: { sortAscending.toggle() }) {
                            Image(systemName: sortAscending ? "arrow.up" : "arrow.down")
                        }
                        .help("Toggle sort direction")
                        .buttonStyle(.plain)
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        // Search field
                        TextField("Search packages", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 300)

                        Button(action: { handleConnect(resourceType: .packages) }) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .help("Refresh packages")
                        .buttonStyle(.bordered)
                    }
                }
                .padding([.horizontal, .top])

                Divider()

                // Rows
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(sortedPackages) { package in
                            NavigationLink(destination: PackageDetailView(package: package, server: server)) {
                                HStack(alignment: .center, spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(package.name)
                                            .font(.system(size: 13, weight: .semibold))
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Text(package.jamfId != 0 ? String(package.jamfId) : package.id.uuidString)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal)
                                .contentShape(Rectangle())
                            }
                            Divider()
                        }
                    }
                }
            }
             .searchable(text: $searchText)
             .onChange(of: searchText) { newValue in
                 // Debounce typing and compute the filtered snapshot off the main actor
                 // filterDebouncer.debounce(interval: 0.25) {
                 //     Task {
                 //         // Snapshot safely on the MainActor
                 //         let snapshot = await MainActor.run { networkController.packages }
                 //         // Filter off-main-thread
                 //         let q = newValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                 //         let result: [Package]
                 //         if q.isEmpty {
                 //             result = snapshot
                 //         } else {
                 //             result = await Task.detached(priority: .userInitiated) {
                 //                 return snapshot.filter { $0.name.lowercased().contains(q) || ($0.filename?.lowercased().contains(q) ?? false) }
                 //             }.value
                 //         }
                 //         await MainActor.run {
                 //             self.filteredPackages = result
                 //         }
                 //     }
                 // }
             }
             .onAppear {
                 // initialize snapshot
                 // self.filteredPackages = networkController.packages
             }
             .foregroundColor(.primary)
 #if os(macOS)
             .frame(minWidth: 300, maxWidth: .infinity)
 #endif
 
             // Detail placeholder on right side for NavigationView
             Text("Select a package to view details")
                 .foregroundColor(.secondary)
                 .padding()
         }
 #if os(macOS)
         .navigationTitle("Packages")
 #endif
         .listStyle(.inset)
         .navigationViewStyle(DefaultNavigationViewStyle())
     }
    
    // Sorting state and helpers
    private enum SortField { case name, id }
    @State private var sortBy: SortField = .name
    @State private var sortAscending: Bool = true

    private var sortedPackages: [Package] {
        let arr = filteredPackages
        switch sortBy {
        case .name:
            return arr.sorted { a, b in
                if sortAscending {
                    return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
                } else {
                    return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedDescending
                }
            }
        case .id:
            return arr.sorted { a, b in
                let aId = (a.jamfId != 0) ? a.jamfId : Int.max
                let bId = (b.jamfId != 0) ? b.jamfId : Int.max
                return sortAscending ? (aId < bId) : (aId > bId)
            }
        }
    }
    
    // keep original helper for compatibility
    var searchResults: [Package] {
        
        if searchText.isEmpty {
            networkController.separationLine()
            // print("Search is empty")
            return networkController.packages
        } else {
            print("Search Added")
            return networkController.packages.filter { $0.name.lowercased().contains(searchText.lowercased())}
        }
    }
}
