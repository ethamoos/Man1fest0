//
//  PackagesActionView.swift
//  Man1fest0
//
//  Created by Amos Deane on 06/09/2023.
//

import SwiftUI

struct PackagesActionView: View {
    
    var selectedResourceType: ResourceType = ResourceType.package
    var server: String

    //  ########################################################################################
    //  EnvironmentObjects
    //  ########################################################################################
    
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var layout: Layout
    @EnvironmentObject var networkController: NetBrain
    
    //  ########################################################################################

    @State private var searchText = ""
    @State private var showingWarning = false
    
    
    //    ########################################################################################
    //    Selections
    //    ########################################################################################
    
    @State var selectedCategory: Category = Category(jamfId: 0, name: "")
    
    @State var selection = Set<Package>()
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            if networkController.packages.count > 0 {
                
                Section(header: Text("All Packages").bold().padding(.leading)) {
                    
                    List(searchResults, id: \.self, selection: $selection) { package in
                        
                        HStack {
                            Image(systemName: "suitcase.fill")
                            Text(package.name ).font(.system(size: 12.0))
                        }
                        .foregroundColor(.blue)
                    }
                    .searchable(text: $searchText)
                    
                    Text("\(networkController.packages.count) total packages")
                    
                        #if os(macOS)
                .navigationTitle("Packages")
#endif
                        .listStyle(.inset)
                }
                .padding()
            }
        }

        .onAppear {
            handleConnect(resourceType: ResourceType.packages)
            if networkController.categories.count <= 1 {
                print("No categories - fetching")
                networkController.connect(server: server,resourceType: ResourceType.category, authToken: networkController.authToken)
            }
            
            
        }
        
        Divider()
        
        VStack(alignment: .leading) {
            
                
            HStack(spacing: 20) {
                
                Button(action: {
                    
                    showingWarning = true
                    progress.showProgressView = true
                    progress.waitForABit()
               
                }) {
                    
                    HStack(spacing:10) {
                        Image(systemName: "delete.left.fill")
                        Text("Delete")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .shadow(color: .gray, radius: 2, x: 0, y: 2)
                }

                .buttonStyle(.borderedProminent)
                .tint(.red)
                .alert(isPresented: $showingWarning) {
                    Alert(
                        title: Text("Caution!"),
                        message: Text("This action will delete data.\n Always ensure that you have a backup!"),
                        primaryButton: .destructive(Text("I understand!")) {
                            // Code to execute when "Yes" is tapped
                            networkController.processDeletePackages(selection: selection, server: server, resourceType: selectedResourceType, authToken: networkController.authToken)
                            
                            print("Yes tapped")
                        },
                        secondaryButton: .cancel()
                    )
                }
                
                
                Button(action: {
                    
                    networkController.connect(server: server,resourceType: ResourceType.packages, authToken: networkController.authToken)
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
                
                //              ####################################################################
                //              CATEGORY
                //              ####################################################################
                
            LazyVGrid(columns: layout.columnsFlex) {
                HStack {
                    
                    Picker(selection: $selectedCategory, label: Text("Category").fontWeight(.bold)) {
                        ForEach(networkController.categories, id: \.self) { category in
                            Text(String(describing: category.name))
                                .tag(category as Category?)
                                .tag(selectedCategory as Category?)
                        }
                    }
                    .onAppear {
                        
                        if networkController.categories.isEmpty != true {
                            print("Setting categories picker default")
                            selectedCategory = networkController.categories[0] }
                    }
                    
                    Button(action: {
                        
                        progress.showProgress()
                        progress.waitForABit()
                        
                        networkController.processUpdatePackagesCategory(selection: selection, server: server,resourceType: ResourceType.package,authToken: networkController.authToken, selectedCategory: selectedCategory)
                        
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.clockwise")
                            Text("Update")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
            }
        }
        .padding()


        List(Array(selection), id: \.self) { package in
            
            Text(package.name )
            
        }
        
        if progress.showProgressView == true {
            
            ProgressView {
                Text("Processing")
                    .padding()
            }
        } else {
            Text("")
        }
    }
    
    func handleConnect(resourceType: ResourceType) {
        print("Running handleConnect. resourceType is set as:\(resourceType)")
        networkController.connect(server: server,resourceType: ResourceType.packages, authToken: networkController.authToken)
    }
    
    var searchResults: [Package] {
        
        if searchText.isEmpty {
            return networkController.packages
        } else {
            print("Search Added")
            return networkController.packages.filter { $0.name.lowercased().contains(searchText.lowercased())}
        }
    }
}


//struct PackagesActionView_Previews: PreviewProvider {
//    static var previews: some View {
//        PackagesActionView()
//    }
//}
