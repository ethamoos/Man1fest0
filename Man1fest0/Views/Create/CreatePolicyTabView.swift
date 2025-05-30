//
//  CreatePolicyView.swift
//  Man1fest0
//
//  Created by Amos Deane on 31/07/2024.
//

import SwiftUI

struct CreatePolicyTabView: View {
    
    var server: String { UserDefaults.standard.string(forKey: "server") ?? "" }
    
    
    //    ########################################
    //    EnvironmentObjects
    //    ########################################
    
    @EnvironmentObject var networkController: NetBrain
    // @EnvironmentObject var controller: JamfController
    @EnvironmentObject var progress: Progress

    
    @EnvironmentObject var layout: Layout

    
    @State var categoryName = ""
    
    @State private var categoryID = ""
    
    @State var categories: [Category] = []
    
    @State private var computers: [ Computer ] = []
    
    @State var computerID = ""
    
    @State var computerUDID = ""
    
    @State var computerName = ""
    
    @State var currentDetailedPolicy: PoliciesDetailed? = nil
    
    @State var newCategoryName: String = ""
    
    @State var departmentName: String = ""
    
    @State var enableDisable: Bool = true
    
    @State var newGroupName: String = ""
    
    
    @State private var packagesAssignedToPolicy: [ Package ] = []
    
    //    @State private var packageID = "1723"
    @State private var packageID = "0"
    
    @State private var packageName = ""
    
    //    @State private var policyPackages = ""
    
    @State var policyName = ""
    
    @State var scriptName = ""
    
    @State var scriptID = ""
    
    @State private var selectedResourceType = ResourceType.policyDetail
    
    
    
    
    //    ########################################
    //    Selections
    //    ########################################
    
    @State private var packageSelection = Set<Package>()

    @State private var selection: Package? = nil
    
    @State var selectedComputer: Computer = Computer(id: 0, name: "")
    
    @State var selectedCategory: Category = Category(jamfId: 0, name: "")
    
    @State var selectedDepartment: Department = Department(jamfId: 0, name: "")
    
    @State var selectedScript: Script = Script(id: "", name: "")
    
    @State var selectedPackage: Package = Package(jamfId: 0, name: "", udid: nil)
    
    //    ########################################
    //    scriptParameters
    //    ########################################
    
    @State var scriptParameter4: String = ""
    
    @State var scriptParameter5: String = ""
    
    @State var scriptParameter6: String = ""
    
    @State var searchText = ""
    
    //    ########################################
    
    @State private var showingWarning = false
    
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 10) {
            
            Group {
                
                
                LazyVGrid(columns: columns, spacing: 30) {
                    
                    HStack {
                        Image(systemName:"hammer")
                        TextField("Policy Name", text: $policyName)
                        
                        Button(action: {
                            
                            progress.showProgress()
                            progress.waitForABit()
                            
                            networkController.createNewPolicy(server: server, authToken: networkController.authToken, policyName: policyName, customTrigger: policyName, categoryID: String(describing: selectedCategory.jamfId), category: selectedCategory.name, departmentID: String(describing: selectedDepartment.jamfId ?? 0) , department: selectedDepartment.name , scriptID: String(describing: $selectedScript.id), scriptName: selectedScript.name, scriptParameter4: scriptParameter4 , scriptParameter5: scriptParameter5 , scriptParameter6: scriptParameter6 , resourceType: selectedResourceType, notificationName: policyName, notificationStatus: "true")
                            
                            // ##############################################################################
                            //                            DEBUG - POLICY
                            // ##############################################################################
                            
                            networkController.separationLine()
                            print("Creating new Policy:\(policyName)")
                            print("categoryID:\(selectedCategory.jamfId)")
                            print("Category:\(selectedCategory.name)")
                            print("selectedDepartment ID:\(String(describing: selectedDepartment.jamfId ?? 0))")
                            print("selectedCategory:\(selectedCategory.name)")
                            
                        }) {
                            Text("Create Policy")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    }
//                    .foregroundColor(.blue)
//                    .background(.green)
                    .background(Color.green)
                }
                
                // ##########################################################################################
                //                        Selections
                // ##########################################################################################
                
                
                LazyVGrid(columns: columns, spacing: 30) {
                    Picker(selection: $selectedCategory, label: Text("Category")) {
                        Text("").tag("") //basically added empty tag and it solve the case
                        ForEach(networkController.categories, id: \.self) { category in
                            Text(String(describing: category.name))
                        }
                    }
                }
                
                LazyVGrid(columns: columns, spacing: 30) {
                    Picker(selection: $selectedDepartment, label: Text("Department:")) {
                        Text("").tag("") //basically added empty tag and it solve the case
                        ForEach(networkController.departments, id: \.self) { department in
                            Text(String(describing: department.name)).tag(department.name)
                        }
                    }
                }
            }
            
            Group {
                
                LazyVGrid(columns: columns, spacing: 30) {
                    Picker(selection: $selectedPackage, label: Text("Package:")) {
                        Text("").tag("") //basically added empty tag and it solve the case
                        ForEach(networkController.packages, id: \.self) { package in
                            Text(String(describing: package.name))
                        }
                    }
                }
                
                LazyVGrid(columns: columns, spacing: 20) {
                    Picker(selection: $selectedScript, label: Text("Scripts")) {
                        Text("").tag("") //basically added empty tag and it solve the case
                        ForEach(networkController.scripts, id: \.self) { script in
                            Text(String(describing: script.name))
                        }
                    }
                }

                
                // ######################################################################################
                //                        Script parameters
                // ######################################################################################
                
                
                LazyVGrid(columns: layout.columns, spacing: 20) {
                    
                    HStack(spacing: 10) {
                        TextField("Parameter 4", text: $scriptParameter4)
                        TextField("Parameter 5", text: $scriptParameter5)
                        TextField("Parameter 6", text: $scriptParameter6)
                    }
                }
                Divider()
            }
        
            .padding()

        }
        .background(Color.green)

        .foregroundColor(.blue)
        .padding()
    }
}

//#Preview {
//    CreatePolicyTabView()
//}
