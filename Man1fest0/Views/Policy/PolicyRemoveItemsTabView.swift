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
    
    @EnvironmentObject var scopingController: ScopingBrain
    
    @EnvironmentObject var layout: Layout
    
    var policyID: Int
    var server: String
    var resourceType: ResourceType
    
    @State var showingWarningClearLimit: Bool = false
    
    @State var showingWarningClearExclusions: Bool = false
    
    @State private var selectedResourceType = ResourceType.policyDetail
    
    // ########################################################################################
    // Interval picker state and options for logFlushInterval
    @State private var selectedIntervalNumber = "Three"
    @State private var selectedIntervalUnit = "Months"
    private let intervalNumbers = ["Zero", "One", "Two", "Three", "Six"]
    private let intervalUnits = ["Days", "Weeks", "Months", "Years"]
    // Computed property to combine number and unit
    private var combinedInterval: String { "\(selectedIntervalNumber)+\(selectedIntervalUnit)" }
    
    //  #############################################################################
    //              Selection
    //  #############################################################################
    
    
    var body: some View {
        
        //  #########################################################################
        //  CLEAR OPTIONS - STRIP OUT EXISTING ELEMENTS
        //  #########################################################################
        
        VStack(alignment: .leading) {
            
            LazyVGrid(columns: layout.columns, alignment: .leading, spacing: 20) {
                
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
                        
                        Debug.separationLine()
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
                        Debug.separationLine()
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
                        Debug.separationLine()
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
                        Debug.separationLine()
                        print("Pressing clear reboot")
                    }) {
                        Text("Clear Reboot")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .help("This clears the reboot node from the policy")
                }
                
                Button(action: {
                    progress.showProgress()
                    progress.waitForABit()
                    showingWarningClearLimit = true
                }) {
                    Text("Clear Limitations")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .alert(isPresented: $showingWarningClearLimit) {
                    Alert(
                        title: Text("Caution!"),
                        message: Text("This action will clear any current limitations on the policy scoping.\n Some devices previously blocked may now receive the policy"),
                        primaryButton: .destructive(Text("I understand!")) {
                            // Code to execute when "Yes" is tapped
                            xmlController.updatePolicyScopeLimitAutoRemove(authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policyID: String(describing:policyID), currentPolicyAsXML: xmlController.currentPolicyAsXML)
                            print("Yes tapped")
                        },
                        secondaryButton: .cancel()
                    )
                }
                
                Button(action: {
                    progress.showProgress()
                    progress.waitForABit()
                    showingWarningClearExclusions = true
                }) {
                    Text("Clear Exclusions")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .alert(isPresented: $showingWarningClearExclusions) {
                    Alert(
                        title: Text("Caution!"),
                        message: Text("This action will clear any current exclusions on the policy scoping.\n Some devices previously blocked may now receive the policy"),
                        primaryButton: .destructive(Text("I understand!")) {
                            // Code to execute when "Yes" is tapped
                            xmlController.removeExclusions(server: server, policyID: String(describing:policyID), authToken: networkController.authToken)
                            print("Yes tapped")
                        },
                        secondaryButton: .cancel()
                    )
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

//                LazyVGrid(columns: layout.columns, spacing: 20) {
                //                Divider()
                HStack{
                    Text("Flush Log Interval").font(.headline)
                    Image(systemName: "delete.left.fill")
                }

                HStack {
                    Picker("Interval Number", selection: $selectedIntervalNumber) {
                        ForEach(intervalNumbers, id: \.self) { number in
                            Text(number)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    Text("+")
                    Picker("Interval Unit", selection: $selectedIntervalUnit) {
                        ForEach(intervalUnits, id: \.self) { unit in
                            Text(unit)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                Button(action: {
                    
                    progress.showProgress()
                    progress.waitForABit()
                    
                    Task {
                        try await scopingController.logFlushInterval(server: server, policyId: String(describing: policyID), logType: "policy", interval: combinedInterval,authToken: networkController.authToken)
                    }
                    //
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Flush Log Interval")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                //                }
                //                Spacer()
            }
            .padding()
            Spacer()
        }
    }
}


//#Preview {
//    PolicyPackageTabView()
//}
