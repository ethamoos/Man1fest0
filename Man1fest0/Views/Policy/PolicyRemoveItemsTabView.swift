//
//  PolicyRemoveItemsView.swift
//  Man1fest0
//
//  Created by Amos Deane on 18/08/2025.
//

import SwiftUI
import AEXML


struct PolicyRemoveItemsTabView: View {
    
    
    @EnvironmentObject var networkController: NetBrain
    
    @EnvironmentObject var progress: Progress
    
    @EnvironmentObject var policyController: PolicyBrain
    
    @EnvironmentObject var xmlController: XmlBrain
    
    @EnvironmentObject var layout: Layout
    
    var policyID: Int
    var server: String
    var resourceType: ResourceType
    
    @State private var selectedResourceType = ResourceType.policyDetail
    
    
    //              ################################################################################
    //              Selection
    //              ################################################################################
    
    
    var body: some View {
        
        //  ################################################################################
        //  CLEAR OPTIONS - STRIP OUT EXISTING ELEMENTS
        //  ################################################################################
        
        VStack(alignment: .leading) {
            
            LazyVGrid(columns: layout.columnsWide, alignment: .leading, spacing: 20) {
                
                HStack(spacing: 10) {
                    
                    Button(action: {
                        progress.showProgress()
                        progress.waitForABit()
                        xmlController.clearSelfService()
                        xmlController.updatePolicy(server: server, authToken: networkController.authToken, policyID: String(describing: policyID), policyXML: String(describing: xmlController.aexmlDoc.xml))
                        
                        networkController.separationLine()
                        print("Pressing clear SelfService")
                    }) {
                        Text("Clear Self-Service")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .help("This clears the self-service node from the policy")
                }
                
                HStack(spacing: 10) {
                    
                    Button(action: {
                        progress.showProgress()
                        progress.waitForABit()
                        xmlController.clearMaintenance(server: server, authToken: networkController.authToken, policyID: String(describing: policyID), policyXML: String(describing: xmlController.aexmlDoc.xml))
                        
                        networkController.separationLine()
                        print("Pressing clear Maintenance")
                    }) {
                        Text("Clear Maintenance")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .help("This clears the maintenance node from the policy")
                }
                
                HStack(spacing: 10) {
                    
                    Button(action: {
                        progress.showProgress()
                        progress.waitForABit()
                        xmlController.clearPrinters()
                        networkController.separationLine()
                        print("Pressing clear Printers")
                        xmlController.updatePolicy(server: server, authToken: networkController.authToken, policyID: String(describing: policyID), policyXML: String(describing: xmlController.aexmlDoc.xml))
                        
                    }) {
                        Text("Clear Printers")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .help("This clears the printers node from the policy")
                }
                
                HStack(spacing: 10) {
                    
                    Button(action: {
                        progress.showProgress()
                        progress.waitForABit()
                        xmlController.clearDockItems()
                        xmlController.updatePolicy(server: server, authToken: networkController.authToken, policyID: String(describing: policyID), policyXML: String(describing: xmlController.aexmlDoc.xml))
                        networkController.separationLine()
                        print("Pressing clear DockItems")
                    }) {
                        Text("Clear DockItems")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .help("This clears the dock_items node from the policy")
                }
                
                HStack(spacing: 10) {
                    
                    Button(action: {
                        progress.showProgress()
                        progress.waitForABit()
                        xmlController.clearReboot()
                        xmlController.updatePolicy(server: server, authToken: networkController.authToken, policyID: String(describing: policyID), policyXML: String(describing: xmlController.aexmlDoc.xml))
                        networkController.separationLine()
                        print("Pressing clear reboot")
                    }) {
                        Text("Clear Reboot")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .help("This clears the reboot node from the policy")
                }
                
                //                    Button(action: {
                //                        progress.showProgress()
                //                        progress.waitForABit()
                //                        xmlController.updatePolicy(server: server, authToken: networkController.authToken, policyID: String(describing: policyID), policyXML: xmlController.aexmlDoc.xml)
                //                        networkController.separationLine()
                //                        print("Pressing update policy")
                //                    }) {
                //                        HStack(spacing: 10) {
                //                            Text("Submit Changes")
                //                        }
                //                    }
                //                    .buttonStyle(.borderedProminent)
                //                    .tint(.blue)
                //                    .help("This submits changes to the server")
                //
                
                HStack(spacing: 10) {
                    
                    Button(action: {
                        progress.showProgress()
                        progress.waitForABit()
                        xmlController.readXMLDataFromString(xmlContent: xmlController.currentPolicyAsXML)
                        
                        networkController.separationLine()
                        print("Refresh data")
                    }) {
                        HStack(spacing: 10) {
                            Text("Refresh")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .help("This refreshes the data for the latest selected policy")
                }
//                    .padding()
                Spacer()

            }
            .padding()
//                .onAppear() {
//                    
//                    fetchData()
//                }
        }
    }
    
    
    func fetchData() {
        
        //        if  networkController.packages.count <= 1 {
        //            print("No package data - fetching")
        //            print("Count is:\(networkController.packages.count))")
        ////            networkController.connect(server: server,resourceType: ResourceType.packages, authToken: networkController.authToken)
        //        } else {
        //            print("package data is available")
        //            print("Count is:\(networkController.packages.count)")
        //        }
    }
}
//#Preview {
//    PolicyPackageTabView()
//}
