//
//  PackagesView.swift
//  Man1fest0
//
//  Created by Amos Deane on 15/09/2022.
//


import SwiftUI

struct PackagesActionSortedView: View {
    
    var server: String
    var selectedResourceType: ResourceType
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var layout: Layout
    @State var searchText = ""
    @State var selection = Set<Package>()
    // macOS Table uses UUID-based selection; keep both representations and sync between them
    @State private var packageSelectionIDs = Set<UUID>()
    @State var packages: [Package] = []

    // ########################################################################################
    // Action state (mirrors PackagesActionView so the same operations are available here)
    // ########################################################################################
    @State private var showingWarning = false
    // Use jamfId-based selection to avoid UUID identity mismatches in Picker
    @State private var selectedCategoryId: Int? = nil
    private var selectedCategory: Category? {
        networkController.categories.first(where: { $0.jamfId == selectedCategoryId })
    }
    // Rename tools
    @State private var toolsNameAction: String = "removelast"
    @State private var toolsCountString: String = "1"
    @State private var toolsMatchString: String = ""
    @State private var toolsReplacementString: String = ""

    // Snapshot of filtered results used by the List to reduce UI work
    // Use a computed property for filtering to simplify the view and help the compiler
    private var filteredPackages: [Package] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty {
            return networkController.packages
        } else {
            return networkController.packages.filter { pkg in
                pkg.name.lowercased().contains(query) || (pkg.udid?.lowercased().contains(query) ?? false)
            }
        }
    }

    // Main body required for View conformance
    var body: some View {
        VStack(spacing: 0) {
            headerView
#if os(macOS)
            // Split the screen: package list on top, actions in the bottom half.
            VSplitView {
                packagesListView
                    .frame(minHeight: 200)
                actionsSection
                    .frame(minHeight: 220)
            }
#else
            packagesListView
            Divider()
            actionsSection
#endif
        }
        .onAppear {
            // ensure packages are loaded when view appears
            Task {
                try await networkController.getAllPackages()
            }
            // ensure categories are available for the Category picker
            if networkController.categories.count <= 1 {
                Task { try await networkController.getAllCategories() }
            }
        }
    }
 

    // Extracted subviews to help the compiler type-check large SwiftUI bodies

    // ########################################################################################
    // Actions section — Delete / Refresh / Rename Tools / Category update / selected list.
    // Operates on `selection` (kept in sync with the table's UUID selection).
    // ########################################################################################
    private var actionsSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {

                Text("Actions")
                    .font(.headline)

                Text("\(selection.count) selected")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Delete + Refresh
                HStack(spacing: 20) {
                    Button(action: {
                        showingWarning = true
                        progress.showProgressView = true
                        progress.waitForABit()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "delete.left.fill")
                            Text("Delete")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(selection.isEmpty)
                    .shadow(color: .gray, radius: 2, x: 0, y: 2)
                    .alert(isPresented: $showingWarning) {
                        Alert(
                            title: Text("Caution!"),
                            message: Text("This action will delete data.\n Always ensure that you have a backup!"),
                            primaryButton: .destructive(Text("I understand!")) {
                                networkController.processDeletePackages(selection: selection, server: server, resourceType: selectedResourceType, authToken: networkController.authToken)
                                print("Yes tapped")
                            },
                            secondaryButton: .cancel()
                        )
                    }

                    Button(action: {
                        Task { try await networkController.getAllPackages() }
                        print("Refresh")
                        progress.showProgress()
                        progress.waitForABit()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }

                // Rename tools for packages
                DisclosureGroup("Rename Tools") {
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
                                    let controller = networkController
                                    let authToken = networkController.authToken
                                    for pkg in selection {
                                        await controller.updatePackageNameLogical(server: server, authToken: authToken, resourceType: ResourceType.package, packageID: String(pkg.jamfId), action: toolsNameAction, count: countInt, match: toolsMatchString, replacement: toolsReplacementString)
                                        try? await Task.sleep(nanoseconds: 200_000_000)
                                    }
                                    progress.endProgress()
                                }
                            }) {
                                Text("Run on Selected")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(selection.isEmpty)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Category update
                LazyVGrid(columns: layout.columnsFlex) {
                    HStack {
                        Picker(selection: $selectedCategoryId, label: Text("Category").fontWeight(.bold)) {
                            Text("No category selected").tag(nil as Int?)
                            ForEach(networkController.categories) { category in
                                Text(String(describing: category.name))
                                    .tag(category.jamfId as Int?)
                            }
                        }

                        Button(action: {
                            progress.showProgress()
                            progress.waitForABit()
                            if let cat = selectedCategory {
                                networkController.processUpdatePackagesCategory(selection: selection, server: server, resourceType: ResourceType.package, authToken: networkController.authToken, selectedCategory: cat)
                            } else {
                                print("No category selected")
                            }
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.clockwise")
                                Text("Update")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .disabled(selection.isEmpty || selectedCategory == nil)
                    }
                }

                // Selected packages
                if !selection.isEmpty {
                    Divider()
                    Text("Selected packages")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ForEach(Array(selection)) { package in
                        Text(package.name)
                            .font(.system(size: 12))
                    }
                }

                if progress.showProgressView == true {
                    ProgressView {
                        Text("Processing").padding()
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var headerView: some View {        HStack(alignment: .center) {
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
                Button(action: {   Task { try await networkController.getAllPackages()}}) {
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
                        .frame(maxWidth: 300)

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

                        Button(action: { Task { try await networkController.getAllPackages()} }) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .help("Refresh packages")
                        .buttonStyle(.bordered)
                    }
                }
                .padding([.horizontal, .top])

                Divider()

                // Column headers to make the list appear as a table (Name | ID)
                HStack {
                    HStack(alignment: .center) {
                        Text("Name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.leading)

                    // ID column header - fixed width so columns line up
                    Text("ID")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 120, alignment: .trailing)
                        .padding(.trailing)
                }
                .padding(.vertical, 6)
                // cross-platform background color
#if os(macOS)
                .background(Color(NSColor.controlBackgroundColor))
#else
                .background(Color(UIColor.secondarySystemBackground))
#endif

                // Rows
                #if os(macOS)
                // Native macOS Table with selection by UUID
                Table(sortedPackages, selection: $packageSelectionIDs) {
                    TableColumn("Name") { pkg in
                        Text(pkg.name)
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)
                    }
                    TableColumn("ID") { pkg in
                        Text(pkg.jamfId != 0 ? String(pkg.jamfId) : pkg.id.uuidString)
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                            .frame(width: 120, alignment: .trailing)
                    }
                }
                .onChange(of: packageSelectionIDs) { newIDs in
                    // Sync UUID selection to package objects set used elsewhere
                    let selectedPkgs = networkController.packages.filter { newIDs.contains($0.id) }
                    self.selection = Set(selectedPkgs)
                }
                .onChange(of: selection) { newSelection in
                    // If other code modifies the Set<Package>, reflect that back into the UUID-based table selection
                    let ids = Set(newSelection.map { $0.id })
                    if ids != packageSelectionIDs {
                        packageSelectionIDs = ids
                    }
                }
                #else
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
                                    // ID column - prefer jamfId when available, otherwise UUID
                                    Text(package.jamfId != 0 ? String(package.jamfId) : package.id.uuidString)
                                        .font(.caption.monospaced())
                                        .foregroundColor(.secondary)
                                        .frame(width: 120, alignment: .trailing)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal)
                                .contentShape(Rectangle())
                            }
                            Divider()
                        }
                    }
                }
                #endif
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
             .frame(minWidth: 350, maxWidth: .infinity)
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
