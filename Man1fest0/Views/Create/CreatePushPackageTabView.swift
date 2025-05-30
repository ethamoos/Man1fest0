//
//  CreatePushPackageTabView.swift
//  Man1fest0
//
//  Created by Amos Deane on 31/07/2024.
//

import SwiftUI

struct CreatePushPackageTabView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}





// ##############################################################################################
//                            DEBUG - PACKAGE
// ##############################################################################################




//                    Divider()
//
//                    Group {
//
//                        Text("Push Package").bold()
//
//                        Divider()
//
//                        LazyVGrid(columns: columns, spacing: 20) {
//
//                            HStack(spacing: 10) {
//
//                                TextField("Policy Name", text: $policyName)
//
//                                Button(action: {
//
//                                    networkController.pushPackage(server: server,authToken: authToken, policyName: policyName, packageName: selectedPackage.name, packageID: Int(selectedPackage.jamfId ) , computerID: $selectedComputer.id, computerName: selectedComputer.name, computerUDID: String(describing: tempUUID), resourceType: selectedResourceType)
//                                    print("Push Package:\(Int(selectedPackage.jamfId )) to:\($selectedComputer.name)")
//
//                                }) {
//                                    HStack(spacing: 10) {
//                                        Text("Push Package")
//                                    }
//                                }
//                            }
//                        }
//
//                        Group {
//
//                            LazyVGrid(columns: columns, spacing: 20) {
//                                Picker(selection: $selectedComputer, label: Text("Computer:").bold()) {
//                                    ForEach(networkController.computers, id: \.self) { computer in
//                                        Text(String(describing: computer.name)).tag(computer.name)
//                                    }
//                                }
//                            }
//
//                            LazyVGrid(columns: columns, spacing: 20) {
//                                Picker(selection: $selectedCategory, label: Text("Category")) {
//                                    ForEach(networkController.categories, id: \.self) { category in
//                                        Text(String(describing: category.name))
//                                    }
//                                }
//                            }
//
//                            LazyVGrid(columns: columns, spacing: 20) {
//                                Picker(selection: $selectedDepartment, label: Text("Department:").bold()) {
//                                    ForEach(networkController.departments, id: \.self) { department in
//                                        Text(String(describing: department.name)).tag(department.name)
//                                    }
//                                }
//                            }
//
//
//                            LazyVGrid(columns: columns, spacing: 20) {
//                                Picker(selection: $selectedPackage, label: Text("Package:").bold()) {
//                                    Text("").tag("") //basically added empty tag and it solve the case
//                                    ForEach(networkController.packages, id: \.self) { package in
//                                        Text(String(describing: package.name))
//                                    }
//                                }
//                            }
//
//                            LazyVGrid(columns: columns, spacing: 20) {
//                                Picker(selection: $selectedScript, label: Text("Scripts")) {
//                                    ForEach(networkController.scripts, id: \.self) { script in
//                                        Text(String(describing: script.name))
//                                    }
//                                }
//                            }
//                        }
//#Preview {
//    CreatePushPackageTab()
//}
