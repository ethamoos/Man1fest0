//
//  CreatePolicyView.swift
//  Manifesto
//
//  Created by Amos Deane on 06/08/2024.
//

import SwiftUI

@available(iOS 17.0, *)

struct CreatePolicyView: View {
    
    var selectedResourceType: ResourceType = ResourceType.package
    
    var server: String
    
    
    //              ################################################################################
    //              EnvironmentObject
    //              ################################################################################
    
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var xmlController: XmlBrain
    @EnvironmentObject var policyController: PolicyBrain
    @EnvironmentObject var layout: Layout
    @EnvironmentObject var importExportBrain: ImportExportBrain
    @EnvironmentObject var networkController: NetBrain
    
    //              ################################################################################
    //              Variables
    //              ################################################################################
    @State private var searchText = ""
    @State private var showingWarning = false
    @State var enableDisable: Bool = true
    @State private var selfServiceEnable = true
    @State private var createDepartmentIsChecked = false
    @State private var enableSelfService = false
    
    //              ################################################################################
    //              categories
    //              ################################################################################
    
    @State var categoryName = ""
    @State private var categoryID = ""
    @State var categories: [Category] = []
    
    //              ################################################################################
    //              computers
    //              ################################################################################
    
    @State private var computers: [ Computer ] = []
    @State var computerID = ""
    @State var computerUDID = ""
    @State var computerName = ""
    @State var currentDetailedPolicy: PoliciesDetailed? = nil
    
    //              ################################################################################
    //              New items
    //              ################################################################################
    
    @State var newPolicyName = ""
    //    @State var departmentName: String = ""
    @State var newCategoryName: String = ""
    @State var newGroupName: String = ""
    @State var newPolicyId = "0"

    //              ################################################################################
    //              Packages
    //              ################################################################################
    
    @State private var packageSelection = Set<Package>()
    @State private var packagesAssignedToPolicy: [ Package ] = []
    @State private var packageID = "0"
    @State private var packageName = ""
    
    // ################################################################################
    // Scripts
    // ################################################################################
    
    @State var scriptName = ""
    @State var scriptID = ""
    
    //              ################################################################################
    //              Selections
    //              ################################################################################
    
    @State var selectedComputer: Computer = Computer(id: 0, name: "")
    
    @State var selectedCategory: Category = Category(jamfId: 0, name: "")
    
    @State var selectedDepartment: Department = Department(jamfId: 0, name: "")
    
    @State var selectedScript: ScriptClassic = ScriptClassic(name: "", jamfId: 0)
    
    @State var selectedPackage: Package = Package(jamfId: 0, name: "", udid: nil)
    
    @State var packageMultiSelection = Set<Package>()
    
    @State var iconMultiSelection = Set<String>()
    
    @State var selectedIconString = ""
    
    @State var selectedIcon: Icon? = Icon(id: 0, url: "", name: "")
    
    @State var selectedIconList: Icon = Icon(id: 0, url: "", name: "")
    
    //      ################################################################################
    //      Script parameters
    //      ################################################################################
    
    @State var scriptParameter4: String = "Parameter 1"
    
    @State var scriptParameter5: String = "Parameter 2"
    
    @State var scriptParameter6: String = "Parameter 3"
        
    @State  var tempUUID = (UUID(uuidString: "") ?? UUID())
    
    
        
    var body: some View {
        
        VStack(alignment: .leading) {
            
            if networkController.packages.count > 0 {
                
                Section(header: Text("All Packages").bold().padding(.leading)) {
                    
                    List(searchResults, id: \.self, selection: $packageMultiSelection) { package in
                        HStack {
                            Image(systemName: "suitcase.fill")
                            Text(package.name ).font(.system(size: 12.0))
                        }
                        .foregroundColor(.blue)
                    }
                    .searchable(text: $searchText)
                    
                    VStack(alignment: .leading) {
                        Text("\(networkController.packages.count) total packages")
                    }
                        #if os(macOS)
                .navigationTitle("Packages")
#endif
                        .listStyle(.inset)
                        .padding()
                }
            }
        }
        //              ################################################################################
        //              Toolbar
        //              ################################################################################
#if os(macOS)
        .toolbar {

            Button(action: {
                progress.showProgress()
                progress.waitForABit()
                print("Refresh")
                print("Icon selection is:\(String(describing: selectedIcon?.id))")
                Task {
                    networkController.connect(server: server,resourceType: ResourceType.category, authToken: networkController.authToken)
                    networkController.connect(server: server,resourceType: ResourceType.department, authToken: networkController.authToken)
                    networkController.connect(server: server,resourceType: ResourceType.packages, authToken: networkController.authToken)
                    networkController.connect(server: server,resourceType: ResourceType.scripts, authToken: networkController.authToken)
                }
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                }
            }
        }
        
#endif
        
        //  ################################################################################
        //              Toolbar - END
        //  ################################################################################
  
        Divider()
        
        //  ################################################################################
        //              selections
        //  ################################################################################
        
        
        List(Array(packageMultiSelection), id: \.self) { package in
            
            Text(package.name )
            
        }
        
        .frame(height: 100)
        
        VStack {
            
            Group {
                
            // ######################################################################################
            // CREATE NEW POLICY - with multiple packages
            // ######################################################################################
                
                LazyVGrid(columns: columns, spacing: 5) {
                    
//                    HStack {
//                        Image(systemName:"hammer")
//                        TextField("Policy Name", text: $newPolicyName)
//                        
//                        Button(action: {
//                            
//                            progress.showProgress()
//                            progress.waitForABit()
//                            
//                            xmlController.createNewPolicyXML(server: server, authToken: networkController.authToken, policyName: newPolicyName, customTrigger: newPolicyName, departmentID: String(describing: selectedDepartment.jamfId), notificationName: newPolicyName, notificationStatus: "true", iconId: String(describing: selectedIcon?.id ?? 0),iconName: String(describing: selectedIcon?.name ?? ""),iconUrl: String(describing: selectedIcon?.url ?? ""), selfServiceEnable: String(describing: selfServiceEnable))
//                            
//                            
//                            //
//                            xmlController.addCategoryToPolicy(xmlContent: xmlController.aexmlDoc.xml, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policyId: newPolicyId, categoryName: selectedCategory.name, categoryId: String(describing: selectedCategory.jamfId), newPolicyFlag: true)
//                            
//                            xmlController.addSelectedPackagesToPolicy(selection: packageMultiSelection, authToken: networkController.authToken, server: server, xmlContent: xmlController.aexmlDoc, policyId: "0")
//                            
//                            if createDepartmentIsChecked == true {
//                                networkController.createDepartment(name: newPolicyName, server: server, authToken: networkController.authToken )
//                                networkController.createDepartment(name: newPolicyName, server: server, authToken: networkController.authToken )
//                            }
//                            
//                            layout.separationLine()
//                            print("Creating New Policy:\(newPolicyName)")
//                            print("Category:\(selectedCategory.name)")
//                            print("Department:\(selectedDepartment.name)")
//                            //                            print("xml is:\(policyController.newPolicyAsXML)")
//                            //                            print("authToken is:\(networkController.authToken)")
//                        }) {
//                            Text("Create Policy")
//                        }
//                        .buttonStyle(.borderedProminent)
//                        .tint(.blue)
//                        
//                        Toggle(isOn: $createDepartmentIsChecked) {
//                            Text("New Department")
//                        }
//                        .toggleStyle(.checkbox)
//                    }
                    
                    HStack {
                        Image(systemName:"hammer")
                        TextField("Policy Name", text: $newPolicyName)
                        Button(action: {
                            progress.showProgress()
                            progress.waitForABit()
                            
                            xmlController.createNewPolicyViaAEXML(authToken: networkController.authToken, server: server, policyName: newPolicyName, policyID: newPolicyId, scriptName: scriptName, scriptID: scriptID, packageName: packageName, packageID: packageID, SelfServiceEnabled: enableSelfService, department: selectedDepartment.name, category: selectedCategory.name, enabledStatus: enableDisable,iconId: String(describing: selectedIcon?.id ?? 0),iconName: String(describing: selectedIcon?.name ?? ""),iconUrl: String(describing: selectedIcon?.url ?? ""))
                            
                            
//                            xmlController.addSelectedPackagesToPolicy(selection: packageMultiSelection, authToken: networkController.authToken, server: server, xmlContent: xmlController.aexmlDoc, policyId: "0")
//                            if createDepartmentIsChecked == true {
//                                networkController.createDepartment(name: newPolicyName, server: server, authToken: networkController.authToken )
//                                networkController.createDepartment(name: newPolicyName, server: server, authToken: networkController.authToken )
//                            }
                            
                            layout.separationLine()
                            print("Creating New Policy:\(newPolicyName)")
//                            print("Category:\(selectedCategory.name)")
//                            print("Department:\(selectedDepartment.name)")
                            //                            print("xml is:\(policyController.newPolicyAsXML)")
                            //                            print("authToken is:\(networkController.authToken)")
                        }) {
                            Text("Create Policy")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        
                        Toggle(isOn: $createDepartmentIsChecked) {
                            Text("New Department")
                        }
                        .toggleStyle(.checkbox)
                        
                        Toggle(isOn: $enableSelfService) {
                            Text("Self Service")
                        }
                        .toggleStyle(.checkbox)
                    }
                }

//                LazyVGrid(columns: layout.columnsFixed, spacing: 5) {
//                    
//                    VStack(alignment: .leading) {
//                        Text("Note: All Fields Must Be Filled")
//                    }
//                }

                
                VStack(alignment: .leading) {
                    
                    LazyVGrid(columns: layout.columnsFlexAdaptiveMedium, spacing: 20) {

                        HStack {
                            Text("Self-Service").bold()
                            if #available(macOS 14.0, *) {
                                Toggle("", isOn: $selfServiceEnable)
                                    .toggleStyle(SwitchToggleStyle(tint: .red))
                                    .onChange(of: enableDisable) {
                                        print("Self-Service is currently:\(selfServiceEnable)")
                                    }
                            } else {
                                // Fallback on earlier versions
                                Toggle("", isOn: $selfServiceEnable)
                                    .toggleStyle(SwitchToggleStyle(tint: .red))
                            }
                        }
                    }
                }
            }
            
    // ##########################################################################################
    //                        Icons
    // ##########################################################################################
            
            Divider()
            
//            LazyVGrid(columns: column, spacing: 30) {
//                
//                VStack(alignment: .leading) {
//                    
//                    Text("Icons").bold()
                    //#if os(macOS)
                    //                List(networkController.allIconsDetailed, id: \.self, selection: $selectedIcon) { icon in
                    //                    HStack {
                    //                        Image(systemName: "photo.circle")
                    //                        Text(String(describing: icon?.name ?? "")).font(.system(size: 12.0)).foregroundColor(.black)
                    //                        AsyncImage(url: URL(string: icon?.url ?? "" )) { image in
                    //                            image.resizable().frame(width: 15, height: 15)
                    //                        } placeholder: {
                    //                        }
                    //                    }
                    //                    .foregroundColor(.gray)
                    //                    .listRowBackground(selectedIconString == icon?.name
                    //                                       ? Color.green.opacity(0.3)
                    //                                       : Color.clear)
                    //                    .tag(icon)
                    //                }
                    //                .cornerRadius(8)
                    //                .frame(minWidth: 300, maxWidth: .infinity, maxHeight: 200, alignment: .leading)
                    //#else
                    //
                    //                List(networkController.allIconsDetailed, id: \.self) { icon in
                    //                    HStack {
                    //                        Image(systemName: "photo.circle")
                    //                        Text(String(describing: icon?.name ?? "")).font(.system(size: 12.0)).foregroundColor(.black)
                    //                        AsyncImage(url: URL(string: icon?.url ?? "" )) { image in
                    //                            image.resizable().frame(width: 15, height: 15)
                    //                        } placeholder: {
                    //                        }
                    //                    }
                    //                }
                    //#endif
                    //                                    .background(.gray)
//                }
//            }
        
    // ##########################################################################################
    //                        Selections
    // ##########################################################################################
        
        
        // ##########################################################################################
        //                        Icons - picker
        // ##########################################################################################
        
            LazyVGrid(columns: columns, spacing: 30) {
                Picker(selection: $selectedIcon, label: Text("Icon:")) {
                    Text("").tag("") //basically added empty tag and it solve the case
                    ForEach(networkController.allIconsDetailed, id: \.self) { icon in
                        
                            HStack {
                                Text(String(describing: icon.name))
                                AsyncImage(url: URL(string: icon.url )) { image in
                                    image.resizable().clipShape(Circle()).aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    //                        Color.red
                                }
                            }

//                        Text(String(describing: icon?.name ?? "")).font(.system(size: 12.0)).foregroundColor(.black).tag(icon?.name)

                    }
                }
            }
            
            // ##########################################################################################
            //                        Category
            // ##########################################################################################
            Divider()

            Group {
                LazyVGrid(columns: columns, spacing: 30) {
                    Picker(selection: $selectedCategory, label: Text("Category")) {
                        ForEach(networkController.categories, id: \.self) { category in
                            Text(String(describing: category.name))
                        }
                    }
                }
            }
            
            // ##########################################################################################
            //                        Department
            // ##########################################################################################
            Divider()

            Group {
                LazyVGrid(columns: columns, spacing: 30) {
                    Picker(selection: $selectedDepartment, label: Text("Department:")) {
                        ForEach(networkController.departments, id: \.self) { department in
                            Text(String(describing: department.name)).tag(department.name)
                        }
                    }
                }
            }
            Divider()

            Group {
                
                LazyVGrid(columns: columns, spacing: 20) {
                    Picker(selection: $selectedScript, label: Text("Scripts")) {
                        ForEach(networkController.scripts, id: \.self) { script in
                            Text(String(describing: script.name))
                        }
                    }
                }
                
                // ######################################################################################
                //                        Script parameters
                // ######################################################################################
                
                LazyVGrid(columns: layout.threeColumnsAdaptive, spacing: 5) {
                    
                    HStack(spacing: 20) {
                        TextField("Parameter 4", text: $scriptParameter4)
                        TextField("Parameter 5", text: $scriptParameter5)
                        TextField("Parameter 6", text: $scriptParameter6)
                    }
                }
                Divider()

#if os(macOS)
                VStack(alignment: .leading) {
                    
                    LazyVGrid(columns: layout.columnsFlexAdaptiveMedium, spacing: 20) {
                        
                        HStack {
                            Button(action: {
                                let openURL = importExportBrain.showOpenPanel()
                                print("openURL is:\(String(describing: openURL))")
                                if (openURL != nil) {
                                    let path = openURL!.path
                                    do {
                                        print("Data imported - setting as importedString")
                                        importExportBrain.importedString = try String(contentsOfFile: path, encoding: .ascii)
                                        print(importExportBrain.importedString)
                                    }
                                    catch let error {
                                        print("Something went wrong: \(error)")
                                    }
                                }
                            }, label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Select File")
                                }
                            })
                            .buttonStyle(.borderedProminent)
                            .tint(.yellow)
                            .shadow(color: .gray, radius: 2, x: 0, y: 2)

                            Button(action: {
                                progress.showProgress()
                                progress.waitForABit()
                                policyController.clonePolicy(xmlContent: importExportBrain.importedString, server: server, policyName: newPolicyName, authToken: networkController.authToken )
                                layout.separationLine()
                                print("Creating New Policy:\(newPolicyName)")
                            }) {
                                Text("Import Policy")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                        }
                    }
                }
                #endif
            }
                
                Divider()
                
    // ######################################################################################
    //                        Create New Department
    // ######################################################################################
                
//            VStack(alignment: .leading) {
//                
//                LazyVGrid(columns: layout.columnsAdaptive, spacing: 20) {
//                    
//                    HStack {
//                        Image(systemName:"hammer")
//                        Text("Department").bold()
//                        TextField("Department Name", text: $newPolicyName)
//                    
//                    Button(action: {
//                        
//                        progress.showProgress()
//                        progress.waitForABit()
//                        
//                        networkController.createDepartment(name: newPolicyName, server: server, authToken: networkController.authToken )
//                        
//                        networkController.separationLine()
//                        print("Creating new department:\(newPolicyName)")
//                        
//                    }) {
//                        Text("Create")
//                    }
//                    .buttonStyle(.borderedProminent)
//                    .tint(.blue)
//                    }
//
//                }
//            }
        }
        
        // ######################################################################################
        //                        onAppear
        // ######################################################################################
        
        .onAppear {
            print("CreateView appeared - connecting")
            handleConnect()
        }
        .padding()
        
        if progress.showProgressView == true {
            ProgressView {
                Text("Processing")
                    .padding()
            }
        } else {
            Text("")
        }
    }
    
    func handleConnect() {
        print("Running handleConnect.")
        networkController.fetchStandardData()
        if networkController.allIconsDetailed.count <= 1 {
            print("getAllIconsDetailed is:\(networkController.allIconsDetailed.count) - running")
            networkController.getAllIconsDetailed(server: server, authToken: networkController.authToken, loopTotal: 1000)
        } else {
            print("getAllIconsDetailed has already run")
            print("getAllIconsDetailed is:\(networkController.allIconsDetailed.count) - running")
        }
    }
    
    var searchResults: [Package] {
        if searchText.isEmpty {
            return networkController.packages
        } else {
            return networkController.packages.filter { $0.name.lowercased().contains(searchText.lowercased())}
        }
    }
}



//#Preview {
//    CreatePolicyView()
//}
