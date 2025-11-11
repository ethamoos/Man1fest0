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

    @EnvironmentObject var progress: Progress

    @EnvironmentObject var layout: Layout

    //    ########################################
    //    Variables
    //    ########################################
    
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
    
    @State private var createDepartmentIsChecked = false
    
    @State var enableDisable: Bool = true
    
    @State var newGroupName: String = ""
    
    @State private var packagesAssignedToPolicy: [ Package ] = []
    
    @State private var packageID = "0"
    
    @State private var packageName = ""
        
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
                    
                            if createDepartmentIsChecked == true {
                                networkController.createDepartment(name: policyName, server: server, authToken: networkController.authToken )
                            }
                            
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
                        
                        Toggle(isOn: $createDepartmentIsChecked) {
                            Text("New Department")
                        }
                        .toggleStyle(.checkbox)
                    }
                    .background(Color.green)
                }

    // ##########################################################################################
    // Toggle enable create new department automatically
    // ##########################################################################################
                
                VStack {
                    
                    Toggle(isOn: $createDepartmentIsChecked) {
                        Text("New Department")
                    }
                    .toggleStyle(.checkbox)
                }
                
    // ##########################################################################################
    //                        Selections
    // ##########################################################################################
    
                LazyVGrid(columns: columns, spacing: 30) {
                    Picker(selection: $selectedCategory, label: Text("Category")) {
                        ForEach(networkController.categories, id: \.self) { category in
                            Text(category.name).tag(category)
                        }
                    }
                }
                
                LazyVGrid(columns: columns, spacing: 30) {
                    Picker(selection: $selectedDepartment, label: Text("Department:")) {
                        ForEach(networkController.departments, id: \.self) { department in
                            Text(department.name).tag(department)
                        }
                    }
                }
            }
            
            Group {
                
                LazyVGrid(columns: columns, spacing: 30) {
                    Picker(selection: $selectedPackage, label: Text("Package:")) {
                        ForEach(networkController.packages, id: \.self) { package in
                            Text(package.name).tag(package)
                        }
                    }
                }
                
                LazyVGrid(columns: columns, spacing: 20) {
                    Picker(selection: $selectedScript, label: Text("Scripts")) {
                        ForEach(networkController.scripts, id: \.self) { script in
                            Text(script.name).tag(script)
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
            
            Group {
                
                Divider()
                
            }
        }
        .background(Color.green)
        .foregroundColor(.blue)
        .padding()
    }
}

//#Preview {
//    CreatePolicyTabView()
//}
