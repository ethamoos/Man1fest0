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
    @State  var selectedCategory: Category = Category(jamfId: 0, name: "")
    
    var body: some View {
        
        //  ############################################################################
        //  Category - update
        //  ############################################################################
        
        VStack(alignment: .leading) {

            LazyVGrid(columns: layout.columnsFlexMedium, spacing: 20) {
                HStack {
                    Picker(selection: $selectedCategory, label: Text("Category:")) {
                        Text("").tag("") //basically added empty tag and it solve the case
                        ForEach(networkController.categories, id: \.self) { category in
                            Text(String(describing: category.name))
                        }
                    }
                    
                    Button(action: {
                        
                        progress.showProgress()
                        progress.waitForABit()
                        
                        networkController.processBatchUpdateCategory(selection: selectedPoliciesInt, server: server,  resourceType: ResourceType.policyDetail, authToken: networkController.authToken, newCategoryName: String(describing: selectedCategory.name), newCategoryID:  String(describing: selectedCategory.jamfId))
                        
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
                        print("Setting category to:\(String(describing: selectedCategory))")
                        print("Policy enable/disable status is set as:\(String(describing: enableDisable))")
                        networkController.selectedCategory = selectedCategory
                        networkController.processUpdatePoliciesCombined(selection: selectedPoliciesInt, server: server, resourceType: ResourceType.policies, enableDisable: enableDisable, authToken: networkController.authToken)
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
            Spacer()
                .padding()
        }
//        .background(Color.purple.opacity(0.5))
//            .border(Color.orange)
        //    }
        
        //  ################################################################################
        //  UPDATE POLICY - COMPLETE
        //  ################################################################################
        
        // ################################################################################
        //                        Icons
        // ################################################################################
        
        //    VStack(alignment: .leading) {
        
//        Text("Icons").bold()
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
        //    }
        
        // ################################################################################
        //                        Icons - picker
        // ################################################################################
        
        //            LazyVGrid(columns: columns, spacing: 10) {
        //                Picker(selection: $selectedIcon, label: Text("Icon:")) {
        //                    //                            Text("").tag("")
        //                    ForEach(networkController.allIconsDetailed, id: \.self) { icon in
        //                        HStack {
        //                            Text(String(describing: icon?.name ?? ""))
        //
        //                            AsyncImage(url: URL(string: icon?.url ?? "" ))  { image in
        //                                    image
        //                                        .resizable()
        //                                        .scaledToFill()
        //                                } placeholder: {
        //                                    ProgressView()
        //                                }
        //                                .frame(width: 05, height: 05)
        //                                .background(Color.gray)
        //                                .clipShape(Circle())
        //                        }
        //                        .frame(width: 05, height: 05)
        //                    }
        //
        // ############################################################
        //  Update Icon Button
        //  ############################################################
        //                }
        //                HStack {
        //                    Button(action: {
        //
        //                        progress.showProgress()
        //                        progress.waitForABit()
        //
        //                        networkController.updateIconBatch(selectedPoliciesInt: selectedPoliciesInt , server: server, authToken: networkController.authToken, iconFilename: String(describing: selectedIcon?.name ?? ""), iconID: String(describing: selectedIcon?.id ?? 0), iconURI: String(describing: selectedIcon?.url ?? ""))
        //                    }) {
        //                        Text("Update Icon")
        //                    }
        //                    .buttonStyle(.borderedProminent)
        //                    .tint(.blue)
        //                }
        //        }
        .padding()
    }
}
