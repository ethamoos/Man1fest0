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
    
    // Use jamfId-based selection to avoid UUID identity mismatches in Picker
    @State var selectedCategoryId: Int? = nil
    private var selectedCategory: Category? {
        networkController.categories.first(where: { $0.jamfId == selectedCategoryId })
    }
    
    @State var selection = Set<Package>()
    // Rename tools
    @State private var toolsNameAction: String = "removelast"
    @State private var toolsCountString: String = "1"
    @State private var toolsMatchString: String = ""
    @State private var toolsReplacementString: String = ""
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            if networkController.packages.count > 0 {
                
                Section(header: Text("All Packages").bold().padding(.leading)) {
                    
                    List(searchResults, selection: $selection) { package in
                        
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
            Task { try await networkController.getAllPackages() }
            
            if networkController.categories.count <= 1 {
                print("No categories - fetching")
                  Task { try await networkController.getAllCategories() }
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
                
                //              ####################################################################
                //              CATEGORY
                //              ####################################################################
                
            // Rename tools for packages
            DisclosureGroup("Rename Tools") {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Action", selection: $toolsNameAction) {
                        Text("Remove last chars").tag("removelast")
                        Text("Replace last chars").tag("replacelast")
                        Text("Replace all occurrences").tag("replaceall")
                    }
                    .pickerStyle(.segmented)

                    HStack(spacing: 8) {
                        if toolsNameAction == "removelast" || toolsNameAction == "replacelast" {
                            TextField("Count", text: $toolsCountString)
                                .frame(width: 80)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        if toolsNameAction == "replacelast" || toolsNameAction == "replaceall" {
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
                                for pkg in selection {
                                    networkController.updatePackageNameLogical(server: server, authToken: networkController.authToken, resourceType: ResourceType.package, packageID: String(pkg.jamfId ?? 0), action: toolsNameAction, count: countInt, match: toolsMatchString, replacement: toolsReplacementString)
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
                .padding()
            }

            LazyVGrid(columns: layout.columnsFlex) {
                HStack {
                    
                    Picker(selection: $selectedCategoryId, label: Text("Category").fontWeight(.bold)) {
                        Text("No category selected").tag(nil as Int?)
                        ForEach(networkController.categories) { category in
                            Text(String(describing: category.name))
                                .tag(category.jamfId as Int?)
                        }
                    }
                    .onAppear {
                        if selectedCategoryId == nil {
                            selectedCategoryId = networkController.categories.first?.jamfId
                        }
                    }
                    
                    Button(action: {
                        
                        progress.showProgress()
                        progress.waitForABit()
                        
                        if let cat = selectedCategory {
                            networkController.processUpdatePackagesCategory(selection: selection, server: server,resourceType: ResourceType.package,authToken: networkController.authToken, selectedCategory: cat)
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
                }
            }
        }
        .padding()


        List(Array(selection)) { package in
            
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
    
//
    
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
