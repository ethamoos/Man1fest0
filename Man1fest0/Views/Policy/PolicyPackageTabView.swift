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
    
    @State private var selection: Package? = nil
    
    var body: some View {
        
        VStack(alignment: .leading) {
         
            //              ################################################################################
            //              List packages
            //              ################################################################################
            
            if let currentPolicyPackages = networkController.currentDetailedPolicy?.policy.package_configuration?.packages {
                
                if currentPolicyPackages.count >= 1 {
                    
                    List(currentPolicyPackages, id: \.self, selection: $selection) { package in
                        
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
                        ForEach(networkController.packages.filter({packageFilter == "" ? true : $0.name.contains(packageFilter)}), id: \.self) { package in
                            Text(String(describing: package.name))
                                .tag(package as Package?)
                                .tag(selectedPackage as Package?)
                        }
                    }
                    
                    .onAppear {
                        
                        if networkController.packages.count >= 1 {
                            print("Setting package picker default")
                            selectedPackage = networkController.packages[0] }
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
                        
                        xmlController.addPackageToPolicy(xmlContent: networkController.xmlDoc, xmlContentString: networkController.currentPolicyAsXML, authToken: networkController.authToken, server: server, packageName: selectedPackage?.name ?? "",packageId: String(describing: selectedPackage?.jamfId ?? 0), policyId: String(describing: policyID), resourceType: ResourceType.policyDetail, newPolicyFlag: false )
                        
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
                            Text("Replace All Package")
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
