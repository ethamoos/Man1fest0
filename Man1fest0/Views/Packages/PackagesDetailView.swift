// PackagesDetailView.swift
// Restored PackageDetailView with editors for Info and Notes

import SwiftUI

struct PackageDetailView: View {
    
    var package: Package
    var server: String
    
    @State private var packageID = ""
    @State private var packageName = ""
    @State private var packageFileName = ""
    @State private var packageInfo = ""
    @State private var packageNotes = ""
    
    //  ########################################################################################
    //  EnvironmentObjects
    //  ########################################################################################

    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var layout: Layout

    //  ########################################################################################
    //  Selections
    //  ########################################################################################

    // Use jamfId-based selection for Category to avoid Picker tag/selection mismatches
    @State var selectedCategoryId: Int? = nil
    private var selectedCategory: Category? {
        networkController.categories.first(where: { $0.jamfId == selectedCategoryId })
    }
    
    @State private var showingWarning = false
    
    var body: some View {
        
        let currentPackage = networkController.packageDetailed

        VStack(alignment: .leading, spacing: 20) {
                        
            if let currentPackage = currentPackage {
                 Section(header: Text("Package Detail").bold()) {
                     
                    Text("Name:\t\t\(currentPackage.name)")
                    Text("ID:\t\t\t\(currentPackage.id)")
                    Text("Filename:\t\(currentPackage.filename)")
                    Text("Category:\t\(currentPackage.category)")
//                    Text("Info:\t\t\t\(String(describing: currentPackage?.info ?? "") )")
//                    Text("Notes:\n\n\(String(describing: currentPackage?.notes ?? "") )")
                    Text("Priority:\t\t\(currentPackage.priority)")
                    Text("Fill Template:\t\(currentPackage.fillUserTemplate)")
                    Text("Fill Users:\t\(currentPackage.fillExistingUsers)")
                }
                
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
                
                .alert(isPresented: $showingWarning) {
                    Alert(
                        title: Text("Caution!"),
                        message: Text("This action will delete data.\n Always ensure that you have a backup!"),
                        primaryButton: .destructive(Text("I understand!")) {
                            // Code to execute when "Yes" is tapped
                            networkController.deletePackage(server: server, resourceType: ResourceType.package, itemID: String(currentPackage.id), authToken: networkController.authToken)
                            
                            print("Yes tapped")
                        },
                        secondaryButton: .cancel()
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                
                //              ####################################################################
                //              CATEGORY
                //              ####################################################################
                
                    Divider()

//                LazyVGrid(columns: layout.columnsFlex) {
                    HStack {
                        
                        Picker(selection: $selectedCategoryId, label: Text("Category").fontWeight(.bold)) {
                            Text("No category selected").tag(nil as Int?)
                            ForEach(networkController.categories, id: \.self) { category in
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
                                networkController.updateCategory(server: server, authToken: networkController.authToken, resourceType: ResourceType.package, categoryID: String(cat.jamfId), categoryName: String(describing: cat.name), updatePressed: true, resourceID: String(currentPackage.id))
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
                    
                    //              ####################################################################
                    //              UPDATE NAME AND FILENAME
                    //              ####################################################################
                    
                    
//                    HStack {
//
//
//                    }
                    
                    HStack {
                        
                        // Placeholder shows current filename; bind the TextField to $packageFileName
                        TextField(currentPackage.filename, text: $packageFileName)
                             .textSelection(.enabled)
                        
                        Button(action: {
                            progress.showProgress()
                            progress.waitForABit()
                            networkController.updatePackageFileName(server: server, authToken: networkController.authToken, resourceType:  ResourceType.package, packageFileName: packageFileName, packageID: String(currentPackage.id))
                            
                            networkController.separationLine()
                            print("Renaming Package Filename:\(packageName)")
                        }) {
                            Text("Rename File")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        
                        TextField(currentPackage.name, text: $packageName)
                            .textSelection(.enabled)
                        
                        Button(action: {
                            progress.showProgress()
                            progress.waitForABit()
                            networkController.updatePackageName(server: server, authToken: networkController.authToken, resourceType:  ResourceType.package, packageName: packageName, packageID: String(currentPackage.id))
                            
                            networkController.separationLine()
                            print("Renaming Package:\(packageName)")
                        }) {
                            Text("Rename Package")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    }
                    
//                }

                //              ####################################################################
                //              PACKAGE INFO & NOTES EDITORS
                //              ####################################################################

                Divider()

                // Package Info editor
                VStack(alignment: .leading, spacing: 8) {
                    Text("Package Info").fontWeight(.bold)
                    TextEditor(text: $packageInfo)
                        .frame(minHeight: 120)
                        .border(Color.gray)

                    HStack {
                        Spacer()
                        Button(action: {
                            progress.showProgress()
                            progress.waitForABit()
                            // Call NetBrain to update the package info
                            networkController.updatePackageInfo(server: server, authToken: networkController.authToken, resourceType: ResourceType.package, packageInfo: packageInfo, packageID: String(currentPackage.id))
                            networkController.separationLine()
                            print("Updated Package Info for id: \(String(describing: currentPackage.id))")
                        }) {
                            Text("Update Info")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    }
                }

                Divider()

                // Package Notes editor
                VStack(alignment: .leading, spacing: 8) {
                    Text("Package Notes").fontWeight(.bold)
                    TextEditor(text: $packageNotes)
                        .frame(minHeight: 120)
                        .border(Color.gray)

                    HStack {
                        Spacer()
                        Button(action: {
                            progress.showProgress()
                            progress.waitForABit()
                            // Call NetBrain to update the package notes
                            networkController.updatePackageNotes(server: server, authToken: networkController.authToken, resourceType: ResourceType.package, packageNotes: packageNotes, packageID: String(currentPackage.id))
                            networkController.separationLine()
                            print("Updated Package Notes for id: \(String(describing: currentPackage.id))")
                        }) {
                            Text("Update Notes")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    }
                }

                // Refresh button to re-fetch detailed package after updates
                Divider()
                HStack {
                    Spacer()
                    Button(action: {
                        progress.showProgress()
                        Task {
                            do {
                                try await networkController.getDetailedPackage(server: server, authToken: networkController.authToken, packageID: String(describing: package.jamfId))
                                progress.endProgress()
                                print("Refresh: fetched detailed package for id \(String(describing: package.jamfId))")
                            } catch {
                                progress.endProgress()
                                print("Refresh failed: \(error)")
                                networkController.separationLine()
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
            } else {
                // No detailed package yet - show helpful message and a refresh action
                VStack(alignment: .leading, spacing: 8) {
                    Text("No detailed package loaded for \(package.name)")
                        .foregroundColor(.secondary)
                    HStack {
                        Button("Load details") {
                            progress.showProgress()
                            Task {
                                do {
                                    try await networkController.getDetailedPackage(server: server, authToken: networkController.authToken, packageID: String(package.jamfId))
                                    progress.endProgress()
                                } catch {
                                    progress.endProgress()
                                    print("Failed to load package details: \(error)")
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        Spacer()
                    }
                }
            }
        }
        // Restore onAppear and populate editors when detailed package arrives
        .onAppear() {
            Task {
                do {
                    try await networkController.getDetailedPackage(server: server, authToken: networkController.authToken, packageID: String(describing: package.jamfId))
                    print("PackageDetailView.onAppear: requested detailed package for jamfId=\(package.jamfId)")
                } catch {
                    print("Error fetching detailed package on appear: \(error)")
                }
            }
            if networkController.categories.count <= 1 {
                print("No categories - fetching")
                networkController.connect(server: server,resourceType: ResourceType.category, authToken: networkController.authToken)
            }
        }
        // When the detailed package is updated, populate the edit state if it's currently empty
        .onChange(of: networkController.packageDetailed) { newPackage in
            print("PackageDetailView.onChange: networkController.packageDetailed changed: \(String(describing: newPackage))")
            if let p = newPackage {
                if packageName.isEmpty {
                    packageName = p.name
                }
                if packageFileName.isEmpty {
                    packageFileName = p.filename
                }
                packageInfo = p.info
                packageNotes = p.notes
            }
        }
    }
}
