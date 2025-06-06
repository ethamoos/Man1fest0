//
//  CreateGeneralTabView.swift
//  Manifesto
//
//  Created by Amos Deane on 31/07/2024.
//

import SwiftUI

struct CreateGeneralTabView: View {
    
    var server: String { UserDefaults.standard.string(forKey: "server") ?? "" }

    //    ########################################
    //    EnvironmentObjects
    //    ########################################
    
    @EnvironmentObject var networkController: NetBrain
    // @EnvironmentObject var controller: JamfController
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var layout: Layout
    @EnvironmentObject var importExportController: ImportExportBrain
    @Binding var selectedFilename: String

    @State var enableDisable: Bool = true
    
    @State var searchText = ""
    
    @State private var showingWarning = false
    
    @State private var selectedResourceType = ResourceType.policyDetail

    //    ########################################
    //    Categories
    //    ########################################
    
    @State var categoryName = ""
    
    @State private var categoryID = ""
    
    @State var categories: [Category] = []
    
    @State var newCategoryName: String = ""
    
    //    ########################################
    //    Computers
    //    ########################################
    
    @State private var computers: [ Computer ] = []
    
    @State var computerID = ""
    
    @State var computerUDID = ""
    
    @State var computerName = ""
    
    @State var currentDetailedPolicy: PoliciesDetailed? = nil
    
    @State var buildingName: String = ""
    
    @State var departmentName: String = ""
    
    @State var newGroupName: String = ""
    
    //    ########################################
    //    Packages
    //    ########################################
    
    @State private var packageSelection = Set<Package>()
    
    @State private var packagesAssignedToPolicy: [ Package ] = []
    
    @State private var packageID = "0"
    
    @State private var newPackageName = ""
    
    @State private var fileName = ""
    
    @State var policyName = ""
    
    //    ########################################
    //    Scripts
    //    ########################################
    
    @State var scriptName = ""
    
    @State var scriptID = ""
    
    @State var scriptParameter4: String = ""
    
    @State var scriptParameter5: String = ""
    
    @State var scriptParameter6: String = ""
    
    //    ########################################
    //    Selections
    //    ########################################
    
    @State private var selection: Package? = nil
    
    @State var selectedComputer: Computer = Computer(id: 0, name: "")
    
    @State var selectedCategory: Category = Category(jamfId: 0, name: "")
    
    @State var selectedDepartment: Department = Department(jamfId: 0, name: "")
    
    @State var selectedScript: ScriptClassic = ScriptClassic(name: "", jamfId: 0)
    
    @State var selectedPackage: Package = Package(jamfId: 0, name: "", udid: nil)
    
    
    //    ########################################
    //    Various
    //    ########################################
    
//    @State private var packageSelection = Set<Package>()
    
    @State var packageFilter = ""
    @State var filePath = ""
    
    
    
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 10) {

            // ######################################################################################
            //                        Create New Building
            // ######################################################################################
            
            HStack {
                Image(systemName:"hammer")
                
                Text("Create New Building").bold()
            }
            LazyVGrid(columns: layout.columns, spacing: 20) {
                
                TextField("Building Name", text: $buildingName)
            }
            
            Button(action: {
                
                progress.showProgress()
                progress.waitForABit()
                
                networkController.createBuilding(name: buildingName, server: server, authToken: networkController.authToken )
                
                networkController.separationLine()
                print("Creating new Building:\(buildingName)")
                
            }) {
                Text("Create")
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            
            Divider()
            
            // ######################################################################################
            //                        Create New Department
            // ######################################################################################
            
            HStack {
                Image(systemName:"hammer")
                
                Text("Create New Department").bold()
            }
            LazyVGrid(columns: layout.columns, spacing: 20) {
                
                TextField("Department Name", text: $departmentName)
            }
            
            Button(action: {
                
                progress.showProgress()
                progress.waitForABit()
                
                networkController.createDepartment(name: departmentName, server: server, authToken: networkController.authToken )
                
                networkController.separationLine()
                print("Creating new department:\(departmentName)")
                
            }) {
                Text("Create")
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            
            Divider()
            
            // ######################################################################################
            //                        Create New Category
            // ######################################################################################
            
            HStack {
                Image(systemName:"hammer")
                
                Text("Create New Category").bold()
            }
            
            LazyVGrid(columns: layout.columns, spacing: 20) {
                
                TextField("Category Name", text: $newCategoryName)
            }
            
            Button(action: {
                
                progress.showProgress()
                progress.waitForABit()
                
                networkController.createCategory(name: newCategoryName, server: server, authToken: networkController.authToken )
                
                networkController.separationLine()
                print("Creating new category:\(newCategoryName)")
                
            }) {
                Text("Create")
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            
            Divider()
            
            
            // ######################################################################################
            //                        Create New Smart Group
            // ######################################################################################
            
            //                    Text("Create New Smart Group").bold()
            //
            //                    LazyVGrid(columns: columns2, spacing: 20) {
            //
            //                        TextField("Static Group Name", text: $newGroupName)
            //                    }
            //
            //                    Button(action: {
            //
            //                        progress.showProgress()
            //
            //                        progress.waitForABit()
            //
            //                        networkController.createSmartGroup(name: newGroupName, smart: true, server: server, authToken: networkController.authToken)
            //
            //
            //                        networkController.separationLine()
            //
            //                        print("Creating new group:\(newCategoryName)")
            //
            //                    }) {
            //                        Text("Create")
            //                    }
            
            // ######################################################################################
            //                        Create New Static Group
            // ######################################################################################
            
            HStack {
                Image(systemName:"hammer")
                Text("Create New Static Group").bold()
            }
            
            LazyVGrid(columns: layout.columns, spacing: 20) {
                TextField("Static Group Name", text: $newGroupName)
            }
            Button(action: {
                
                progress.showProgress()
                progress.waitForABit()
                networkController.createStaticGroup(name: newGroupName, smart: false, server: server, resourceType: ResourceType.computerGroup, authToken: networkController.authToken)
                networkController.separationLine()
                self.fileName = importExportController.selectedFilename
                print("Creating new group:\(newCategoryName)")
                
            }) {
                Text("Create")
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            
            
            // ######################################################################################
            //                        Create New Package Record
            // ######################################################################################
            
            HStack {
                Image(systemName:"hammer")
                Text("Create New Package Record").bold()
            }
            
            LazyVGrid(columns: layout.threeColumns, spacing: 10) {
                
                TextField("Package Name", text: $newPackageName)
                TextField("File Name", text: $selectedFilename)
            }
            Text("Selected file is:\(importExportController.selectedFilename)")
            Button(action: {
                
                progress.showProgress()
                progress.waitForABit()
                
                networkController.separationLine()
                networkController.createPackageRecord(name: newPackageName, server: server, authToken: networkController.authToken)
                print("Creating new package:\(newCategoryName)")
                
            }) {
                Text("Create")
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            
            .alert(isPresented: $networkController.hasError) {
                Alert(
                    title: Text("Error"),
                    message: Text("Error code is:\(networkController.currentResponseCode)"),
                    dismissButton: .default(Text("Ok"))
                )
            }
            
#if os(macOS)
            
            HStack {
                Button(action: {
                    let openURL = importExportController.showOpenPanel()
                    print("openURL path is:\(String(describing: openURL?.path ?? ""))")
                    if (openURL != nil) {
                        self.filePath = openURL!.path
                    } else {
                        print("Something went wrong setting openURL")
                    }
                }, label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Select File")
                    }
                })
                
                Button(action: {
                    progress.showProgress()
                    progress.waitForABit()
                    packageID = String(describing: selectedPackage.jamfId)
                    importExportController.uploadPackage(authToken: networkController.authToken, server: server, packageId: packageID, pathToFile: self.filePath)
                    layout.separationLine()
                    
                }) {
                    HStack {
                        Image(systemName: "suitcase.fill")
                    Text("Upload Package")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                

//                Button(action: {
//                    progress.showProgress()
//                    progress.waitForABit()
//                    networkController.separationLine()
//                    print("Selected package is:\(String(describing: selectedPackage.name))")
//                    print("Selected packageID is:\(String(describing: selectedPackage.jamfId))")
//                }) {
//                    HStack(spacing: 10) {
//                        Image(systemName: "plus.square.fill.on.square.fill")
//                        Text("Test Package")
//                    }
//                }
//                .buttonStyle(.borderedProminent)
//                .tint(.blue)
//                }
            }
#endif
            LazyVGrid(columns: layout.threeColumnsAdaptive, spacing: 20) {
                HStack {
                    TextField("Filter", text: $packageFilter)
                    Picker(selection: $selectedPackage, label: Text("").bold()) {
                        ForEach(networkController.packages.filter({packageFilter == "" ? true : $0.name.contains(packageFilter)}), id: \.self) { package in
                            Text(String(describing: package.name))
                                .tag(package as Package?)
                                .tag(selectedPackage as Package?)
                        }
                    }
                    .onAppear {
                        if networkController.packages.count >= 1 {
                            print("Setting package picker default")
                            selectedPackage = networkController.packages[0] }
                    }
                }
            }
        }
        .foregroundColor(.blue)
        .padding()
    }
}


//#Preview {
//    CreateGeneralTabView()
//}
