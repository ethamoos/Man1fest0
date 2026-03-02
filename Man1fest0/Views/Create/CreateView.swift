//
//  CreateView.swift
//  Man1fest0
//
//  Created by Amos Deane on 17/11/2023.
//

import SwiftUI

struct CreateView: View {
    
    var server: String
    
    @EnvironmentObject var policyController: PolicyBrain
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var importExportController: ImportExportBrain

    
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
    
    @State private var packageSelection = Set<Package>()
    
    @State private var packagesAssignedToPolicy: [ Package ] = []
    
    @State private var packageID = "0"
    
    @State private var packageName = ""
    
    @State var policyName = ""
    
    @State var scriptName = ""
    
    @State var scriptID = ""
    
    @State private var selectedResourceType = ResourceType.policyDetail
    
    @State private var selection: Package? = nil
    
    @State var selectedComputer: Computer = Computer(id: 0, name: "")
    
    @State var selectedCategory: Category = Category(jamfId: 0, name: "")
    
    @State var selectedDepartment: Department = Department(jamfId: 0, name: "")
    
    @State var selectedScript: Script = Script(id: "", name: "")
    
    @State var selectedPackage: Package = Package(jamfId: 0, name: "", udid: nil)
    
    @State var scriptParameter4: String = ""
    
    @State var scriptParameter5: String = ""
    
    @State var scriptParameter6: String = ""
    
    @State var searchText = ""
    
    @State  var tempUUID = (UUID(uuidString: "") ?? UUID())
    
    @State private var showingWarning = false
    
//    @State private var showProgressView = false
    
    let columns = [
        GridItem(.fixed(200)),
        GridItem(.flexible()),
    ]
    
    let columns2 = [
        GridItem(.fixed(400)),
        GridItem(.flexible()),
    ]
    
    var body: some View {
        
        ScrollView {
            
            VStack(alignment: .leading, spacing: 20) {
                
                // New header: nicer title, subtitle and quick actions
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Create")
                            .font(.title)
                            .fontWeight(.semibold)
                        Text("Create categories, groups, packages and scripts")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        Button(action: {
                            // quick refresh
                            networkController.connect(server: server,resourceType: ResourceType.category, authToken: networkController.authToken)
                            networkController.connect(server: server,resourceType: ResourceType.department, authToken: networkController.authToken)
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)

                        Button(action: {
                            // open import/export filename if available
                            // keep as info-only quick action
                        }) {
                            Image(systemName: "square.and.arrow.down")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.03)))

                //  ################################################################################
                //  TabView - TAB
                //  ################################################################################
                
                VStack {
                    TabView {
                        
                        CreateGeneralTabView(selectedFilename: $importExportController.selectedFilename)
                            .tabItem {
                                //                                Text("Scoping")
                                Label("General", systemImage: "square.and.pencil")
                            }
                    }
                    .padding()
                }
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.02)))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.04)))
                
            }
            
            if progress.showProgressView {
                
                ProgressView {
                    
                    Text("Processing")
                        .padding()
                }
                
            } else {
                Text("")
            }

        }
        //    }
        //}
        
        .onAppear {
            
            print("CreateView appeared - connecting")
            networkController.connect(server: server,resourceType: ResourceType.category, authToken: networkController.authToken)
            networkController.connect(server: server,resourceType: ResourceType.department, authToken: networkController.authToken)
            networkController.connect(server: server,resourceType: ResourceType.packages, authToken: networkController.authToken)
            networkController.connect(server: server,resourceType: ResourceType.scripts, authToken: networkController.authToken)
        }
        .padding()
        
        
        
    }
}
//}




//              ################################################################################
//              push package and new policy
//              ################################################################################


//                LazyVGrid(columns: columns, spacing: 20) {
//
//                    Group {

//                        VStack {
//
//                            TextField("Policy Name", text: $policyName)
//                        }

//                        HStack {

//                            Button(action: {
//
//                                networkController.pushPackage(server: server,authToken: authToken, policyName: policyName, packageName: selectedPackage.name, packageID: Int(selectedPackage.jamfId ) , computerID: $selectedComputer.id, computerName: selectedComputer.name, computerUDID: String(describing: tempUUID), resourceType: selectedResourceType)
//
//                                print("Push Package:\(Int(selectedPackage.jamfId )) to:\($selectedComputer.name)")
//
//                            }) {
//                                HStack(spacing: 10) {
//                                    //                                        Image(systemName: "delete.left.fill")
//                                    Text("Push Package")
//                                }
//                            }
//
//                            Button(action: {
//
//                                networkController.createNewPolicy(server: server,authToken: authToken, policyName: policyName, customTrigger: "", categoryID: String(describing: selectedCategory.jamfId), category: selectedCategory.name, departmentID: String(describing: selectedDepartment.jamfId) , department: selectedDepartment.name , scriptID: String(describing: selectedScript.jamfId), scriptName: selectedScript.name, scriptParameter4: scriptParameter4 , scriptParameter5: scriptParameter5 , scriptParameter6: scriptParameter6 , resourceType: selectedResourceType, notificationName: policyName, notificationStatus: "true")
//
//
//                                print("New Policy:\(Int(selectedPackage.jamfId )) to:\($selectedComputer.name)")
//
//                            }) {
//                                HStack(spacing: 10) {
//                                    Image(systemName: "plus.circle.fill")
//                                    Text("New Policy")
//                                }
//                            }
//                        }
//                    }
//                }
