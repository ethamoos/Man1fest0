//
//  CreatePolicyView.swift
//  Manifesto
//
//  Created by Amos Deane on 06/08/2024.
//

import SwiftUI

@available(iOS 17.0, macOS 13.0, *)

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
    
    // ################################################################################
    // New items
    // ################################################################################
    
    @State var newPolicyName = ""
    // @State var departmentName: String = ""
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
    
    // Sorting for package selection list
    private enum PackageSortField: Hashable { case name, id }
    @State private var packageSortBy: PackageSortField = .name
    @State private var packageSortAscending: Bool = true

    // ################################################################################
    // Scripts
    // ################################################################################
    
    @State var scriptName = ""
    @State var scriptID = ""
    
    // ################################################################################
    // Selections
    // ################################################################################
    
    @State var selectedComputer: Computer = Computer(id: 0, name: "")
    
    // ################################################################################
    // Selection IDs used by Pickers to avoid mismatched tag/selection warnings
    // ################################################################################

    @State var selectedCategoryId: Int? = nil
    @State var selectedDepartmentId: Int? = nil
    @State var selectedScriptId: Int? = nil
    @State var selectedPackage: Package = Package(jamfId: 0, name: "", udid: nil)
    // Use jamfId (Int) for multi-selection so List selection matches the id used by the data source
    @State var packageMultiSelection = Set<Int>()
    @State var iconMultiSelection = Set<String>()
    @State var selectedIconString = ""
    @State var iconFilter: String = ""
    @State var categoryFilter: String = ""
    @State var departmentFilter: String = ""
    @State var scriptFilter: String = ""

    // Use optional ID selection for icon picker
    @State var selectedIconId: Int? = nil
    
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
                
                Section(header:
                            // Header now includes sort controls
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("All Packages").bold().padding(.leading)
                                    Spacer()
                                    HStack(spacing: 8) {
                                        Picker("Sort by", selection: $packageSortBy) {
                                            Text("Name").tag(PackageSortField.name)
                                            Text("ID").tag(PackageSortField.id)
                                        }
                                        .pickerStyle(.segmented)
                                        .frame(maxWidth: 220)

                                        Button(action: { packageSortAscending.toggle() }) {
                                            Image(systemName: packageSortAscending ? "arrow.up" : "arrow.down")
                                        }
                                        .buttonStyle(.plain)
                                        .help("Toggle sort direction")
                                    }
                                }
                            }
                ) {
                    
                    // Identify items by their jamfId (Int) and bind selection to a Set<Int>
                    List(sortedPackages, id: \.jamfId, selection: $packageMultiSelection) { package in
                        
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
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    progress.showProgress()
                    progress.waitForABit()
                    print("Refresh")
                    print("Icon selection id is:\(String(describing: selectedIconId))")
                    Task {
                        networkController.connect(server: server,resourceType: ResourceType.category, authToken: networkController.authToken)
                        networkController.connect(server: server,resourceType: ResourceType.department, authToken: networkController.authToken)
                        networkController.connect(server: server,resourceType: ResourceType.packages, authToken: networkController.authToken)
                        networkController.connect(server: server,resourceType: ResourceType.scripts, authToken: networkController.authToken)
                    }
                }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
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
        
        
        List(Array(packageMultiSelection), id: \.self) { selectedJamfId in
            Text(networkController.packages.first(where: { $0.jamfId == selectedJamfId })?.name ?? "")
        }
        
        .frame(height: 100)
        
        VStack {
            
            Group {
                
            // ######################################################################################
            // CREATE NEW POLICY - with multiple packages
            // ######################################################################################
                
                LazyVGrid(columns: columns, spacing: 5) {
                    
                    HStack {
                        Image(systemName:"hammer")
                        TextField("Policy Name", text: $newPolicyName)
                        Button(action: {
                            progress.showProgress()
                            progress.waitForABit()
                            
                            // Resolve selection values from the networkController arrays using the selected IDs
                            // Find the category by jamfId (Int) which is what the Picker tags use
                            let categoryNameLocal = networkController.categories.first(where: { $0.jamfId == selectedCategoryId })?.name ?? ""
                            let departmentNameLocal = networkController.departments.first(where: { $0.jamfId == selectedDepartmentId })?.name ?? ""
                            let iconLocal = networkController.allIconsDetailed.first(where: { $0.id == selectedIconId })
                            let iconIdString = String(iconLocal?.id ?? 0)
                            let iconNameLocal = iconLocal?.name ?? ""
                            let iconUrlLocal = iconLocal?.url ?? ""
                            let scriptLocal = networkController.scripts.first(where: { $0.jamfId == selectedScriptId })
                            let scriptNameLocal = scriptLocal?.name ?? ""
                            let scriptIdString = String(scriptLocal?.jamfId ?? 0)

                            // Prepare selected package ids to pass to XML builder
                            let selectedPackageIdsToAdd = Set(packageMultiSelection)
                            
                            xmlController.createNewPolicyViaAEXML(authToken: networkController.authToken,
                                                                  server: server,
                                                                  policyName: newPolicyName,
                                                                  policyID: newPolicyId,
                                                                  scriptName: scriptNameLocal,
                                                                  scriptID: scriptIdString,
                                                                  packageName: packageName,
                                                                  packageID: packageID,
                                                                  SelfServiceEnabled: enableSelfService,
                                                                  department: departmentNameLocal,
                                                                  category: categoryNameLocal,
                                                                  enabledStatus: enableDisable,
                                                                  iconId: iconIdString,
                                                                  iconName: iconNameLocal,
                                                                  iconUrl: iconUrlLocal,
                                                                  selectedPackageIds: selectedPackageIdsToAdd, packages: networkController.packages)
                            
                            layout.separationLine()
                            print("Creating New Policy:\(newPolicyName)")
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

            // Prominent Icons filter header so it's always visible
            VStack(alignment: .leading, spacing: 6) {
                Text("Icons").bold().padding(.bottom, 4)
                HStack {
                    TextField("Filter icons", text: $iconFilter)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: .infinity)
                    if !iconFilter.isEmpty {
                        Button(action: { iconFilter = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(6)
                .background(Color.gray.opacity(0.06))
                .cornerRadius(6)
            }
            
        //  ################################################################################
        //              selections
        //  ################################################################################
        
        // ##########################################################################################
        //                        Icons - picker
        // ##########################################################################################
        
            LazyVGrid(columns: columns, spacing: 30) {
                 VStack(alignment: .leading, spacing: 6) {
                     // Prominent filter field for icons placed above the picker and stretched to full width
                     //                    HStack(spacing: 8) {
 //                        TextField("Filter icons", text: $iconFilter)
 //                            .textFieldStyle(.roundedBorder)
 //                            .frame(maxWidth: .infinity)
 //
 //                        // Clear button for convenience
 //                        if !iconFilter.isEmpty {
 //                            Button(action: { iconFilter = "" }) {
 //                                Image(systemName: "xmark.circle.fill")
 //                                    .foregroundColor(.secondary)
 //                            }
 //                            .buttonStyle(.plain)
 //                        }
 //                    }
                     
                    Picker(selection: $selectedIconId, label: Text("Icon:")) {
                        // Filter icons by name when iconFilter is non-empty
                        ForEach(networkController.allIconsDetailed.filter { icon in
                            guard !iconFilter.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return true }
                            return icon.name.localizedCaseInsensitiveContains(iconFilter)
                        }, id: \.id) { icon in
                            HStack(spacing: 8) {
                                // Fixed-size thumbnail to avoid variable icon sizes
                                AsyncImage(url: URL(string: icon.url)) { image in
                                    image.resizable().scaledToFit()
                                } placeholder: {
                                    Image(systemName: "photo")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(.gray)
                                }
                                .frame(width: 24, height: 24)
                                .clipShape(Circle())
                                
                                Text(icon.name)
                            }
                            .tag(icon.id)
                        }
                    }
//                    .onChange(of: networkController.allIconsDetailed) { newIcons in
//                        if selectedIconId == nil {
//                            selectedIconId = newIcons.first?.id
//                        }
//                    }
                }
             }
            
            // ##########################################################################################
            //                        Category
            // ##########################################################################################
            Divider()

            Group {
                LazyVGrid(columns: columns, spacing: 30) {
                    VStack(alignment: .leading, spacing: 6) {
                        TextField("Filter categories", text: $categoryFilter)
                            .textFieldStyle(.roundedBorder)
                        
                        Picker(selection: $selectedCategoryId, label: Text("Category")) {
                            // Use jamfId (Int) for tags so the Picker selection (an Int?) matches the tags.
                            ForEach(networkController.categories.filter { cat in
                                categoryFilter.isEmpty ? true : cat.name.localizedCaseInsensitiveContains(categoryFilter)
                            }, id: \.jamfId) { category in
                                Text(category.name).tag(category.jamfId)
                            }
                        }
                        .onChange(of: networkController.categories) { newCategories in
                            if selectedCategoryId == nil {
                                selectedCategoryId = newCategories.first?.jamfId
                            }
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
                     VStack(alignment: .leading, spacing: 6) {
                         TextField("Filter departments", text: $departmentFilter)
                             .textFieldStyle(.roundedBorder)
                         
                         Picker(selection: $selectedDepartmentId, label: Text("Department:")) {
                             ForEach(networkController.departments.filter { dept in
                                departmentFilter.isEmpty ? true : dept.name.localizedCaseInsensitiveContains(departmentFilter)
                             }, id: \.jamfId) { department in
                                 Text(department.name).tag(department.jamfId)
                             }
                         }
                     }
                 }
             }
             Divider()

             Group {
                  
                  LazyVGrid(columns: columns, spacing: 20) {
                      VStack(alignment: .leading, spacing: 6) {
                          TextField("Filter scripts", text: $scriptFilter)
                              .textFieldStyle(.roundedBorder)
                          
                          Picker(selection: $selectedScriptId, label: Text("Scripts")) {
                              ForEach(networkController.scripts.filter { s in
                                  scriptFilter.isEmpty ? true : s.name.localizedCaseInsensitiveContains(scriptFilter)
                              }, id: \.jamfId) { script in
                                  Text(script.name).tag(script.jamfId)
                              }
                          }
                          .onChange(of: networkController.scripts) { newScripts in
                              if selectedScriptId == nil {
                                  selectedScriptId = newScripts.first?.jamfId
                              }
                          }
                      }
                  }
                  
                  // ######################################################################################
             }
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
    
    // Combined sorted packages based on current searchResults and sort settings
    private var sortedPackages: [Package] {
        let arr = searchResults
        switch packageSortBy {
        case .name:
            return arr.sorted { a, b in
                if packageSortAscending {
                    return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
                } else {
                    return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedDescending
                }
            }
        case .id:
            return arr.sorted { a, b in
                // Treat jamfId==0 as large so it sorts after real ids
                let aId = (a.jamfId != 0) ? a.jamfId : Int.max
                let bId = (b.jamfId != 0) ? b.jamfId : Int.max
                return packageSortAscending ? (aId < bId) : (aId > bId)
            }
        }
    }
}
