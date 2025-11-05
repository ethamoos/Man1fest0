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
    
    @State private var action = ""
    
    @State private var feu = false
    
    @State private var fut = false
    
//              ################################################################################
//              Selection
//              ################################################################################


    @State var selectedPackage: Package? = nil
    
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

                //  ################################################################################
                //  Package picker
                //  ################################################################################
                
            LazyVGrid(columns: layout.threeColumnsAdaptive, spacing: 20) {
                HStack {
                    TextField("Filter", text: $packageFilter)
                    Picker(selection: $selectedPackage, label: Text("").bold()) {
                        Text("No package selected").tag(nil as Package?)
                        ForEach(networkController.packages.filter { packageFilter.isEmpty ? true : $0.name.contains(packageFilter) }, id: \ .self) { package in
                            Text(String(describing: package.name))
                                .tag(package as Package?)
                        }
                    }
                    .onAppear {
                        let filtered = networkController.packages.filter { packageFilter.isEmpty ? true : $0.name.contains(packageFilter) }
                        selectedPackage = filtered.first
                    }
                    .onChange(of: networkController.packages) { newPackages in
                        let filtered = newPackages.filter { packageFilter.isEmpty ? true : $0.name.contains(packageFilter) }
                        selectedPackage = filtered.first
                    }
                    .onChange(of: packageFilter) { newFilter in
                        let filtered = networkController.packages.filter { newFilter.isEmpty ? true : $0.name.contains(newFilter) }
                        if let selected = selectedPackage, !filtered.contains(selected) {
                            selectedPackage = filtered.first
                        }
                        if filtered.isEmpty {
                            selectedPackage = nil
                        }
                    }
                    .onChange(of: selectedPackage) { newSelection in
                        let filtered = networkController.packages.filter { packageFilter.isEmpty ? true : $0.name.contains(packageFilter) }
                        if let selected = newSelection, !filtered.contains(selected) {
                            selectedPackage = filtered.first
                        }
                    }
                }
            }
            Divider()
            
            Text("Packages")
            
                HStack {
                    Button(action: {
                        
                        progress.showProgress()
                        progress.waitForABit()
                        
//                        separationLine()
                        print("Editing policy:\(String(describing: policyID))")
                        networkController.addExistingPackages()
                        print("Adding selected package to policy:\(String(describing: selectedPackage))")
                        
                        xmlController.addPackageToPolicy(xmlContent: xmlController.aexmlDoc, xmlContentString: xmlController.currentPolicyAsXML, authToken: networkController.authToken, server: server, packageName: selectedPackage?.name ?? "",packageId: String(describing: selectedPackage?.jamfId ?? 0), policyId: String(describing: policyID), resourceType: ResourceType.policyDetail, newPolicyFlag: false, action: action, fut: fut ? "true" : "", feu: feu ? "true" : "" )
                        
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.square.fill.on.square.fill")
                            Text("Add package")
                            }
                      
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    
                    TextField("Install", text: $action)

                    Toggle(isOn: $fut) {
                        Text("FUT")
                            .font(.caption)
                    }
                    .toggleStyle(.checkbox)
                    .fixedSize()

                    Toggle(isOn: $feu) {
                        Text("FEU")
                            .font(.caption)
                    }
                    .toggleStyle(.checkbox)
                    .fixedSize()

                    //  ################################################################################
                    //              Replace package in policy
                    //  ################################################################################
                    
                    Button(action: {
                        
                        progress.showProgress()
                        progress.waitForABit()
                        
//                        separationLine()
                        print("Assigning package to policy:\(String(describing: selectedPackage?.jamfId))")
                        
                        packageID = String(describing: selectedPackage?.jamfId)
                        packageName = selectedPackage?.name ?? ""
                        
                        networkController.editPolicy(server: server, authToken: networkController.authToken, resourceType: selectedResourceType, packageName: packageName, packageID: packageID, policyID: policyID, action: action, fut: fut ? "true" : "", feu: feu ? "true" : "")
                        
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.square.fill.on.square.fill")
                            Text("Replace All")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        
                        //  ################################################################################
                        //              Replace package in policy
                        //  ################################################################################
                        
                        Button(action: {
                            
                            progress.showProgress()
                            progress.waitForABit()
                            
//                            separationLine()
                            print("Clearing all packages in policy:\(String(describing: policyID))")
                            
                            xmlController.removePackagesFromPolicy(xmlContent: networkController.aexmlDoc, authToken: networkController.authToken, server: server, policyId: String(describing: policyID))
//                        xmlController.removeAllPackagesManual(server: server, authToken: networkController.authToken, policyID: String(describing: policyID))

                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "plus.square.fill.on.square.fill")
                                Text("Remove All")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        
                        
                         Button(action: {
                            
                            progress.showProgress()
                            progress.waitForABit()
                            
//                            separationLine()
                            print("Refresh packages")

                             networkController.connect(server: server,resourceType: ResourceType.packages, authToken: networkController.authToken)
                            
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "plus.square.fill.on.square.fill")
                                Text("Refresh")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
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
