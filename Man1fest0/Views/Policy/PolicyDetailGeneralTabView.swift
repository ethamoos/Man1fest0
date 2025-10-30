//
//  PolicyDetailGeneralTabView.swift
//  Man1fest0
//
//  Created by Amos Deane on 19/08/2025.
//


import SwiftUI

struct PolicyDetailGeneralTabView: View {
    
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var scopingController: ScopingBrain
    @EnvironmentObject var xmlController: XmlBrain
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var layout: Layout
    
    var server: String
    var selectedPoliciesInt: [Int?]
    @State var iconFilter = ""

    
    //  ####################################################################################
    //  BOOLS
    //  ####################################################################################
    
    @State var status: Bool = true
    @State private var showingWarning = false
    @State private var showingWarningDelete = false
    
    @State var enableDisable: Bool = true
    @State private var showingWarningClearPackages = false
    @State private var showingWarningClearScripts = false
    
    //  ####################################################################################
    //    Category SELECTION
    //  ####################################################################################
    
    @State var categories: [Category] = []
    @State  var selectedCategory: Category? = nil
    
    //  ########################################################################################
    //  SELECTIONS
    //  ########################################################################################
    
    @State var computerGroupSelection = ComputerGroup(id: 0, name: "", isSmart: false)
    
    @State var iconMultiSelection = Set<String>()
    
    @State var selectedIconString = ""
    
    @State var selectedIcon: Icon? = nil
    
//  ############################################################################
//  Sort order
//  ############################################################################

    
    @State private var sortOption: SortOption = .alphabetical
        
        enum SortOption: String, CaseIterable, Identifiable {
            case alphabetical = "Alphabetical"
            case reverseAlphabetical = "Reverse Alphabetical"
            
            var id: String { self.rawValue }
        }
        
        var sortedIcons: [Icon?] {
            switch sortOption {
            case .alphabetical:
                return networkController.allIconsDetailed.sorted { $0.name < $1.name }
            case .reverseAlphabetical:
                return networkController.allIconsDetailed.sorted { $0.name > $1.name}
            }
        }
    
    
    var body: some View {
        
        //  ############################################################################
        //  Category - update
        //  ############################################################################
        
        VStack(alignment: .leading) {
            
            LazyVGrid(columns: layout.threeColumnsAdaptive, spacing: 20) {
                HStack {
                    Picker(selection: $selectedCategory, label: Text("Category:")) {
                        Text("No category selected").tag(nil as Category?)
                        ForEach(networkController.categories, id: \.self) { category in
                            Text(String(describing: category.name)).tag(category as Category?)
                        }
                    }
                    .onAppear {
                        if !networkController.categories.isEmpty {
                            selectedCategory = networkController.categories.first
                        }
                    }
                    .onChange(of: networkController.categories) { newCategories in
                        if !newCategories.isEmpty {
                            selectedCategory = newCategories.first
                        }
                    }
                    Button(action: {
                        progress.showProgress()
                        progress.waitForABit()
                        if let category = selectedCategory {
                            networkController.processBatchUpdateCategory(selection: selectedPoliciesInt, server: server,  resourceType: ResourceType.policyDetail, authToken: networkController.authToken, newCategoryName: String(describing: category.name), newCategoryID:  String(describing: category.jamfId))
                        } else {
                            print("No category selected")
                        }
                    }) {
                        HStack(spacing: 10) {
                            Text("Update")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    Spacer()
                }
                //                .background(Color.green.opacity(0.5))
                //                    .border(Color.yellow)
            }
            
            // ####################################################################
            //              Update Category Enable
            //  ####################################################################
            
            LazyVGrid(columns: layout.threeColumnsAdaptive, spacing: 20) {
                HStack {
                    Button(action: {
                        progress.showProgressView = true
                        networkController.processingComplete = false
                        progress.waitForABit()
                        if let category = selectedCategory {
                            print("Setting category to:\(String(describing: category))")
                            networkController.selectedCategory = category
                            networkController.processUpdatePoliciesCombined(selection: selectedPoliciesInt, server: server, resourceType: ResourceType.policies, enableDisable: enableDisable, authToken: networkController.authToken)
                        } else {
                            print("No category selected")
                        }
                        print("Policy enable/disable status is set as:\(String(describing: enableDisable))")
                    }) {
                        Text("Update Category/Enable")
                            .help("This updates the category and also applies the enable/disable settings")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    
                    //  ########################################################################
                    //  Enable or Disable Policies Toggle
                    //  ########################################################################
                    
                    Toggle("", isOn: $enableDisable)
                        .toggleStyle(SwitchToggleStyle(tint: .red))
                    if enableDisable {
                        Text("Enabled")
                    } else {
                        Text("Disabled")
                    }
                }
            }
            //            Spacer()
            //                .padding()
            //        }
            //        .background(Color.purple.opacity(0.5))
            //            .border(Color.orange)
            //    }
            
            //  ################################################################################
            //  UPDATE POLICY - COMPLETE
            //  ################################################################################
            
            // ################################################################################
            //                        Icons
            // ################################################################################
            
            
            // ################################################################################
            //                        Icons - picker
            // ################################################################################
            
          
            LazyVGrid(columns: layout.columns, spacing: 10) {
                
                
                HStack {
                    TextField("Filter", text: $iconFilter)
                    Picker(selection: $selectedIcon, label: Text("").bold()) {
                        Text("No icon selected").tag(nil as Icon?)
                        ForEach(networkController.allIconsDetailed.filter { iconFilter.isEmpty ? true : $0.name.lowercased().contains(iconFilter.lowercased()) }, id: \.self) { icon in
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(Color.gray.opacity(0.15))
                                        .frame(minWidth: 32, maxWidth: 32, minHeight: 32, maxHeight: 32)
                                    AsyncImage(url: URL(string: icon.url ))  { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(minWidth: 32, maxWidth: 32, minHeight: 32, maxHeight: 32)
                                            .clipped()
                                    } placeholder: {
                                        ProgressView()
                                            .frame(width: 32, height: 32)
                                    }
                                }
                                Text(String(describing: icon.name))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                            .frame(height: 36)
                            .frame(minWidth: 32, maxWidth: 32, minHeight: 32, maxHeight: 32)
                            .tag(icon as Icon?)
                        }
                    }
                    .onAppear {
                        if !networkController.allIconsDetailed.isEmpty {
                            // Only set selectedIcon if the first icon exists
                            selectedIcon = networkController.allIconsDetailed.first
                        } else {
                            selectedIcon = nil
                        }
                    }
                    .onChange(of: networkController.allIconsDetailed) { newIcons in
                        if !newIcons.isEmpty {
                            selectedIcon = newIcons.first
                        } else {
                            selectedIcon = nil
                        }
                    }
                }
                //
                //                ############################################################
                //                Update Icon Button
                //                ############################################################
                
                
                
                
                
                
                
                HStack {
                    Button(action: {
                        progress.showProgress()
                        progress.waitForABit()
                        if let icon = selectedIcon {
                            xmlController.updateIconBatch(selectedPoliciesInt: selectedPoliciesInt , server: server, authToken: networkController.authToken, iconFilename: String(describing: icon.name), iconID: String(describing: icon.id), iconURI: String(describing: icon.url))
                        } else {
                            print("No icon selected")
                        }
                    }) {
                        Text("Update Icon")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
                HStack {
                    Button(action: {
                        progress.showProgress()
                        progress.waitForABit()
                        networkController.getAllIconsDetailed(server: server, authToken: networkController.authToken, loopTotal: 20000)                        }) {
                            Text("Refresh Icons")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                }
            }
                    Spacer()
        }
        .padding()
    }
}
