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
                    Picker(selection: $selectedPackage, label: Text("").bold()) {
                        Text("No package selected").tag(nil as Package?)
                        ForEach(networkController.packages.filter({packageFilter == "" ? true : $0.name.contains(packageFilter)}), id: \ .self) { package in
                            Text(String(describing: package.name))
                                .tag(package as Package?)
                        }
                    }
                    .onAppear {
                        if !networkController.packages.isEmpty {
                            selectedPackage = networkController.packages.first
                        } else {
                            selectedPackage = nil
                        }
                    }
                    .onChange(of: networkController.packages) { newPackages in
                        if !newPackages.isEmpty {
                            selectedPackage = newPackages.first
                        } else {
                            selectedPackage = nil
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
                        print("Adding selected package to policy:\(String(describing: selectedPackage))")
                        
                        xmlController.addPackageToPolicy(xmlContent: xmlController.aexmlDoc, xmlContentString: xmlController.currentPolicyAsXML, authToken: networkController.authToken, server: server, packageName: selectedPackage?.name ?? "",packageId: String(describing: selectedPackage?.jamfId ?? 0), policyId: String(describing: policyID), resourceType: ResourceType.policyDetail, newPolicyFlag: false )
                        
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.square.fill.on.square.fill")
                            Text("Add package")
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
                        
                        networkController.separationLine()
                        print("Assigning package to policy:\(String(describing: selectedPackage?.jamfId))")
                        
                        packageID = String(describing: selectedPackage?.jamfId)
                        packageName = selectedPackage?.name ?? ""
                        
                        networkController.editPolicy(server: server, authToken: networkController.authToken, resourceType: selectedResourceType, packageName: packageName, packageID: packageID, policyID: policyID)
                        
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.square.fill.on.square.fill")
                            Text("Replace All Packages")
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
                        
                        networkController.separationLine()
                        print("Clearing all packages in policy:\(String(describing: policyID))")
                        
                        xmlController.removePackagesFromPolicy(xmlContent: networkController.aexmlDoc, authToken: networkController.authToken, server: server, policyId: String(describing: policyID))
//                        xmlController.removeAllPackagesManual(server: server, authToken: networkController.authToken, policyID: String(describing: policyID))

                        
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.square.fill.on.square.fill")
                            Text("Remove All Packages")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    
                    
                     Button(action: {
                        
                        progress.showProgress()
                        progress.waitForABit()
                        
                        networkController.separationLine()
                        print("Refresh packages")

                         networkController.connect(server: server,resourceType: ResourceType.packages, authToken: networkController.authToken)
                        
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.square.fill.on.square.fill")
                            Text("Refresh Packages")
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
