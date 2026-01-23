//
//  PolicyPackageTabView.swift
//  Man1fest0
//
//  Created by Amos Deane on 10/07/2024.
//

import SwiftUI
import AEXML


struct PolicyPackageTabView: View {
    
    
    @EnvironmentObject var networkController: NetBrain
    
    @EnvironmentObject var progress: Progress
    
    @EnvironmentObject var policyController: PolicyBrain
    
    @EnvironmentObject var xmlController: XmlBrain
    
    @EnvironmentObject var layout: Layout
    
    var policyID: Int
    var server: String
    var resourceType: ResourceType
    
    @State private var selectedResourceType = ResourceType.policyDetail
    
    //  ################################################################################
    //              PACKAGES
    //  ################################################################################
    
    var packageSelection: Set<Package>
    
    @State var packageFilter = ""
    
    @State private var packagesAssignedToPolicy: [ Package ] = []
    
    @State private var packageID = "1723"
    
    @State private var packageName = ""
    
    @State var action: String = "Install"
    
    // Represent FUT/FEU as booleans in the UI; APIs accept string "true"/"false"
    @State private var fut: Bool = false
    @State private var feu: Bool = false
    
    
    
//              ################################################################################
//              Selection
//              ################################################################################


    // Use selectedPackageId (Int?) for Picker selection to avoid UUID-based identity mismatches
    @State var selectedPackageId: Int? = nil
    // Convenience computed property to access the selected Package from the id
    private var selectedPackage: Package? {
        networkController.packages.first(where: { $0.jamfId == selectedPackageId })
    }
    
    var body: some View {
        
        VStack(alignment: .leading) {
         
            //              ################################################################################
            //              List packages
            //              ################################################################################
            
            if let currentPolicyPackages = networkController.policyDetailed?.package_configuration?.packages {
                
                if currentPolicyPackages.count >= 1 {
                    
                    List(currentPolicyPackages, id: \.self) { package in
                        
                        HStack {
                            Image(systemName: "suitcase")
                            Text(package.name )
                        }
                    }
                    .frame(minHeight: 100)
                    
                } else {
                    VStack(alignment: .leading) {
                        Text("No packages present")
                    } .font(.headline)
                        .padding()
                    Spacer()
                }
            }
                
                
                //  ################################################################################
                //              Edit package assignment to policy
                //  ################################################################################
                
                //        Group {
                //  ################################################################################
                //              Add via multi-package to policy
                //  ################################################################################
                
            Divider()

//            VStack(alignment: .leading) {
//                Text("Assign Packages").font(.system(size: 12, weight: .bold, design: .default))
//            }
//            .padding()
                
                
                //  ################################################################################
                //  Package picker
                //  ################################################################################
                
            LazyVGrid(columns: layout.threeColumnsAdaptive, spacing: 20) {
                HStack {
                    TextField("Filter", text: $packageFilter)
                    Picker(selection: $selectedPackageId, label: Text("").bold()) {
                        Text("No package selected").tag(nil as Int?)
                        ForEach(networkController.packages.filter { packageFilter.isEmpty ? true : $0.name.contains(packageFilter) }, id: \.self) { package in
                            Text(String(describing: package.name))
                                .tag(package.jamfId as Int?)
                        }
                    }
                    .onAppear {
                        let filtered = networkController.packages.filter { packageFilter.isEmpty ? true : $0.name.contains(packageFilter) }
                        selectedPackageId = filtered.first?.jamfId
                    }
                    .onChange(of: networkController.packages) { newPackages in
                        let filtered = newPackages.filter { packageFilter.isEmpty ? true : $0.name.contains(packageFilter) }
                        selectedPackageId = filtered.first?.jamfId
                    }
                    .onChange(of: packageFilter) { newFilter in
                        let filtered = networkController.packages.filter { newFilter.isEmpty ? true : $0.name.contains(newFilter) }
                        if let selected = selectedPackage, !filtered.contains(where: { $0.jamfId == selected.jamfId }) {
                            selectedPackageId = filtered.first?.jamfId
                        }
                        if filtered.isEmpty {
                            selectedPackageId = nil
                        }
                    }
                    .onChange(of: selectedPackageId) { newSelectionId in
                        let filtered = networkController.packages.filter { packageFilter.isEmpty ? true : $0.name.contains(packageFilter) }
                        if let id = newSelectionId, !filtered.contains(where: { $0.jamfId == id }) {
                            selectedPackageId = filtered.first?.jamfId
                        }
                    }
                }
            }
            
                HStack {
                    Button(action: {
                        
                        progress.showProgress()
                        progress.waitForABit()
                        
                        networkController.separationLine()
                        print("Editing policy:\(String(describing: policyID))")
                        networkController.addExistingPackages()
                        print("Adding selected package to policy id:\(String(describing: selectedPackageId))")
                        let pkg = selectedPackage
                        // Provide explicit action/fut/feu values to match XmlBrain API
                        xmlController.addPackageToPolicy(xmlContent: xmlController.aexmlDoc,
                                                         xmlContentString: xmlController.currentPolicyAsXML,
                                                         authToken: networkController.authToken,
                                                         server: server,
                                                         packageName: pkg?.name ?? "",
                                                         packageId: String(describing: pkg?.jamfId ?? 0),
                                                         policyId: String(describing: policyID),
                                                         resourceType: ResourceType.policyDetail,
                                                         newPolicyFlag: false,
                                                         action: "Install",
                                                         fut: String(fut),
                                                         feu: String(feu))

                        // Refresh detailed policy to reflect changes
                        Task {
                            do {
                                try await networkController.getDetailedPolicy(server: server, authToken: networkController.authToken, policyID: String(describing: policyID))
                            } catch {
                                print("Failed to refresh detailed policy after adding package: \(error)")
                            }
                        }

                    }) {
                        HStack(spacing: 10) {
//                            Image(systemName: "plus.square.fill.on.square.fill")
                            Text("Add Package")
                        }
                  
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .help("Add the selected package to this policy's package configuration.")
                    
                    //  ################################################################################
                    //              Replace package in policy
                    //  ################################################################################
                    
                    Button(action: {
                        
                        progress.showProgress()
                        progress.waitForABit()
                        
                        networkController.separationLine()
                        print("Assigning package to policy id:\(String(describing: selectedPackageId))")
                        packageID = String(describing: selectedPackageId ?? 0)
                        packageName = selectedPackage?.name ?? ""
                        
                        networkController.editPolicy(server: server, authToken: networkController.authToken, resourceType: selectedResourceType, packageName: packageName, packageID: packageID, policyID: policyID, action: action, fut: String(fut), feu: String(feu))
                        
                    }) {
                        HStack(spacing: 10) {
//                            Image(systemName: "plus.square.fill.on.square.fill")
                            Text("Replace All")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .help("Replace all packages in this policy with the selected package and options.")
                    
                    TextField("Action", text: $action)
                        .textFieldStyle(.roundedBorder)
                    Toggle("FUT", isOn: $fut)
                        .toggleStyle(CheckboxToggleStyle())
                    Toggle("FEU", isOn: $feu)
                        .toggleStyle(CheckboxToggleStyle())
                    
                    //  ################################################################################
                    //              Replace package in policy
                    //  ################################################################################
                    
                    Button(action: {
                        
                        progress.showProgress()
                        progress.waitForABit()
                        
                        networkController.separationLine()
                        print("Clearing all packages in policy:\(String(describing: policyID))")
                        
                        xmlController.removePackagesFromPolicy(xmlContent: xmlController.aexmlDoc, authToken: networkController.authToken, server: server, policyId: String(describing: policyID))
//                        xmlController.removeAllPackagesManual(server: server, authToken: networkController.authToken, policyID: String(describing: policyID))

                        
                    }) {
                        HStack(spacing: 10) {
//                            Image(systemName: "plus.square.fill.on.square.fill")
                            Text("Remove All")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .help("Remove all packages assigned to this policy.")
                    
                    
                     Button(action: {
                        
                        progress.showProgress()
                        progress.waitForABit()
                        
                        networkController.separationLine()
                        print("Refresh packages")

                         networkController.connect(server: server,resourceType: ResourceType.packages, authToken: networkController.authToken)
                        
                    }) {
                        HStack(spacing: 10) {
//                            Image(systemName: "plus.square.fill.on.square.fill")
                            Text("Refresh")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .help("Refresh package list from the server.")
                    
                    
                    
                    
//                }
            }
        }
        
        .onAppear() {
            
            fetchData()
        }
    }
    
    
    func fetchData() {
        
        if  networkController.packages.count <= 1 {
            print("No package data - fetching")
            print("Count is:\(networkController.packages.count))")
//            print(networkController.packages.count)
            networkController.connect(server: server,resourceType: ResourceType.packages, authToken: networkController.authToken)

        } else {
            
            print("package data is available")
            print("Count is:\(networkController.packages.count)")
            
        }
        
    }
    
}
    //#Preview {
    //    PolicyPackageTabView()
    //}


