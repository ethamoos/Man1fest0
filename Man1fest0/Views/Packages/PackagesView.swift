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
    
    var body: some View {

        VStack(alignment: .leading) {
            
            if networkController.packages.count > 0 {
                NavigationView {
                    
                    List(searchResults, id: \.self, selection: $selection) { package in
                        NavigationLink(destination: PackageDetailView(package: package, server: server)) {
                            
                            HStack {
                                Image(systemName: "suitcase.fill")
                                Text(package.name ).font(.system(size: 12.0))
                            }
                        }
                    }
                    .searchable(text: $searchText)
                    .foregroundColor(.blue)
#if os(macOS)
                        .frame(minWidth: 300, maxWidth: .infinity)
#endif
                    Text("\(networkController.packages.count) total packages")

                }
#if os(macOS)
//                #if os(macOS)
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
        .frame(minWidth: 200, minHeight: 100, alignment: .center)

        .onAppear {
            handleConnect(resourceType: ResourceType.packages)
        }
    }
    
    func handleConnect(resourceType: ResourceType) {
        print("Running handleConnect. resourceType is set as:\(resourceType)")
        networkController.connect(server: server,resourceType: ResourceType.packages, authToken: networkController.authToken)
    }
    
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
