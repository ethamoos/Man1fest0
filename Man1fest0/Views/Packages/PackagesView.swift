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
    @State private var filteredPackages: [Package] = []
    @StateObject private var filterDebouncer = Debouncer()
    
    var body: some View {

        VStack(alignment: .leading) {
            
            if networkController.packages.count > 0 {
                NavigationView {
                    
                    List(filteredPackages, selection: $selection) { package in
                        NavigationLink(destination: PackageDetailView(package: package, server: server)) {
                            
                            HStack {
                                Image(systemName: "suitcase.fill")
                                Text(package.name ).font(.system(size: 12.0))
                            }
                        }
                    }
                    .searchable(text: $searchText)
                    .onChange(of: searchText) { newValue in
                        // Debounce typing and compute the filtered snapshot off the main actor
                        filterDebouncer.debounce(interval: 0.25) {
                            Task {
                                // Snapshot safely on the MainActor
                                let snapshot = await MainActor.run { networkController.packages }
                                // Filter off-main-thread
                                let q = newValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                                let result: [Package]
                                if q.isEmpty {
                                    result = snapshot
                                } else {
                                    result = await Task.detached(priority: .userInitiated) {
                                        return snapshot.filter { $0.name.lowercased().contains(q) }
                                    }.value
                                }
                                await MainActor.run {
                                    self.filteredPackages = result
                                }
                            }
                        }
                    }
                    .onAppear {
                        // initialize snapshot
                        self.filteredPackages = networkController.packages
                    }
                    .foregroundColor(.blue)
#if os(macOS)
                        .frame(minWidth: 300, maxWidth: .infinity)
#endif
                    Text("\(networkController.packages.count) total packages")

                }
#if os(macOS)
                .navigationTitle("Packages")
#endif
                .listStyle(.inset)
                .navigationViewStyle(DefaultNavigationViewStyle())
                
                
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
        .frame(minWidth: 200, minHeight: 100, alignment: .leading)

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
