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
            List(selection: $selection) {
                ForEach(filteredPackages) { package in
                    NavigationLink(destination: PackageDetailView(package: package, server: server)) {
                        PackageRow(package: package, server: server)
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
    
    // Small extracted row view to reduce body complexity and help type-checking
    private struct PackageRow: View {
        let package: Package
        let server: String

        var body: some View {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: "archivebox.fill")
                        .foregroundColor(.blue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(package.name)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        // Use udid as a best-effort filename placeholder; Package model doesn't include filename
                        Text(package.udid ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                VStack(alignment: .trailing) {
                    // Show jamfId when present, otherwise show the UUID id
                    if package.jamfId != 0 {
                        Text("ID: \(package.jamfId)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else {
                        Text("ID: \(package.id.uuidString)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 6)
        }
    }
    
    var body: some View {

        VStack(alignment: .leading) {
            headerView

            if networkController.packages.count > 0 {
                packagesListView
            } else {
                ProgressView {
                    Text("Loading")
                        .font(.title)
                        .progressViewStyle(.horizontal)
                }
                .padding()
                Spacer()
            }
        }
        .frame(minWidth: 300, minHeight: 180, alignment: .leading)
        .onAppear {
            handleConnect(resourceType: ResourceType.packages)
        }
    }
    
    func handleConnect(resourceType: ResourceType) {
        print("Running handleConnect. resourceType is set as:\(resourceType)")
        networkController.connect(server: server,resourceType: ResourceType.packages, authToken: networkController.authToken)
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
