//
//  PolicyDetailClearItemsTabView.swift
//  Man1fest0
//
//  Created by Amos Deane on 19/08/2025.
//


import SwiftUI

struct PolicyDetailClearItemsTabView: View {
    
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var scopingController: ScopingBrain
    @EnvironmentObject var xmlController: XmlBrain
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var layout: Layout
    
    var server: String
    var selectedPoliciesInt: [Int?]
    
    @State private var showingWarningClearPackages = false
    @State private var showingWarningClearScripts = false
    @State private var showingWarningDelete = false
    @State private var showingWarningClearScope = false
    @State private var showingWarningClearLimit = false
    @State private var showingWarningClearMaintenance = false
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            //  ################################################################################
            //  Clear Limitations
            //  ################################################################################
            
            LazyVGrid(columns: layout.column, alignment: .leading, spacing: 10) {
                
                HStack(spacing:20 ){
                    
                    Text("Clear Limitations")
                    
                    Button(action: {
                        showingWarningClearLimit = true
                        progress.showProgress()
                        progress.waitForABit()
                        print("Pressing clear limitations")
                        for eachItem in selectedPoliciesInt {
                            print("Updating for \(String(describing: eachItem ?? 0))")
                            let currentPolicyID = (eachItem ?? 0)
                            
                            Task {
                                do {
                                    let policyAsXML = try await xmlController.getPolicyAsXMLaSync(server: server, policyID: currentPolicyID, authToken: networkController.authToken)
                                    
                                    xmlController.updatePolicyScopeLimitAutoRemove(authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policyID: String(describing:currentPolicyID), currentPolicyAsXML: policyAsXML)
                                } catch {
                                    print("Fetching detailed policy as xml failed: \(error)")
                                }
                            }
                        }
                    }) {
                        Text("Clear")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .alert(isPresented: $showingWarningClearScope) {
                        Alert(title: Text("Caution!"), message: Text("This action will clear any limitations from the policy scoping.\n You will need to re-add these if you still require them"), dismissButton: .default(Text("I understand!")))
                    }
                }
                //            }
                
                //  ################################################################################
                //              Clear Scope
                //  ################################################################################
                
                //            LazyVGrid(columns: layout.columnsWide, spacing: 20) {
                
                HStack(spacing:20 ){
                    
                    Text("Clear Scope")
                    
                    Button(action: {
                        showingWarningClearScope = true
                        progress.showProgress()
                        progress.waitForABit()
                        
                        for eachItem in selectedPoliciesInt {
                            
                            let currentPolicyID = (String(describing: eachItem ?? 0))
                            networkController.clearScope(server: server,resourceType:  ResourceType.policies, policyID: currentPolicyID, authToken: networkController.authToken)
                            print("Clear Scope for policy:\(eachItem ?? 0)")
                        }
                    }) {
                        Text("Clear")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .alert(isPresented: $showingWarningClearScope) {
                        Alert(title: Text("Caution!"), message: Text("This action will clear devices from the policy scoping.\n You will need to rescope in order to deploy"), dismissButton: .default(Text("I understand!")))
                    }
                }
                //            }
                
                //  ################################################################################
                //              DELETE
                //  ################################################################################
                
                //            LazyVGrid(columns: layout.columnsWide, spacing: 20) {
                
                HStack(spacing:20 ){
                    
                    Text("Delete Policies")
                    
                    Button(action: {
                        showingWarningDelete = true
                        progress.showProgressView = true
                        print("Set showProgressView to true")
                        print(progress.showProgressView)
                        progress.waitForABit()
                        print("Check processingComplete")
                        print(String(describing: networkController.processingComplete))
                    }) {
                        Text("Delete")
                    }
                    .alert(isPresented: $showingWarningDelete) {
                        Alert(
                            title: Text("Caution!"),
                            message: Text("This action will delete data.\n Always ensure that you have a backup!"),
                            primaryButton: .destructive(Text("I understand!")) {
                                networkController.processDeletePoliciesGeneral(selection: selectedPoliciesInt, server: server,  authToken: networkController.authToken, resourceType: ResourceType.policies)
                                print("Delete button - Yes tapped")
                            },
                            secondaryButton: .cancel()
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .shadow(color: .gray, radius: 2, x: 0, y: 2)
                }
                //            }
                
                //  ################################################################################
                //  CLEAR PACKAGES
                //  ################################################################################
                
                //            LazyVGrid(columns: layout.columnsWide, spacing: 20) {
                
                HStack(spacing:20 ){
                    
                    Text("Clear Packages")
                    
                    Button(action: {
                        showingWarningClearPackages = true
                        progress.showProgress()
                        progress.waitForABit()
                    }) {
                        Text("Clear")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .alert(isPresented: $showingWarningClearPackages) {
                        Alert(
                            title: Text("Caution!"),
                            message: Text("This action will clear packages from the polices selected.\n"),             primaryButton: .destructive(Text("I understand!")) {
                                // Code to execute when "Yes" is tapped
                                for eachItem in selectedPoliciesInt {
                                    let currentPolicyID = (String(describing: eachItem ?? 0))
                                    xmlController.removeAllPackagesManual(server: server, authToken: networkController.authToken, policyID: currentPolicyID)
                                    print("Clearing Packages for policy:\(eachItem ?? 0)")
                                }
                                print("Yes tapped")
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
                //            }
                
                //  ################################################################################
                //  CLEAR SCRIPTS
                //  ################################################################################
                
                //            LazyVGrid(columns: layout.columnsWide, spacing: 20) {
                
                HStack(spacing:20 ){
                    
                    Text("Clear Scripts")
                    
                    Button(action: {
                        showingWarningClearScripts = true
                        progress.showProgress()
                        progress.waitForABit()
                    }) {
                        HStack(spacing: 10) {
                            Text("Clear")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .alert(isPresented: $showingWarningClearScripts) {
                        Alert(
                            title: Text("Caution!"),
                            message: Text("This action will clear scripts from the polices selected.\n"),             primaryButton: .destructive(Text("I understand!")) {
                                // Code to execute when "Yes" is tapped
                                for eachItem in selectedPoliciesInt {
                                    let currentPolicyID = (String(describing: eachItem ?? 0))
                                    xmlController.removeAllScriptsManual(server: server, authToken: networkController.authToken, policyID: currentPolicyID)
                                    print("Clearing scripts for policy:\(eachItem ?? 0)")
                                }
                                print("Yes tapped")
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
                
                //  ################################################################################
                //  CLEAR MAINTENANCE
                //  ################################################################################
                
                //            LazyVGrid(columns: layout.columnsWide, spacing: 20) {
                
                HStack(spacing: 10) {
                    
                    Text("Clear Maintenance")
                    Button(action: {
                        
                        showingWarningClearMaintenance = true

                        progress.showProgress()
                        progress.waitForABit()
                        
                        xmlController.removeMaintenanceBatch(selectedPoliciesInt: selectedPoliciesInt, server: server, authToken: networkController.authToken)
                        
                    }) {
                        HStack(spacing: 10) {
                            Text("Clear")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .alert(isPresented: $showingWarningClearMaintenance) {
                        Alert(
                            title: Text("Caution!"),
                            message: Text("This action will clear maintenance from the polices selected.\n"),             primaryButton: .destructive(Text("I understand!")) {
                                // Code to execute when "Yes" is tapped
                                for eachItem in selectedPoliciesInt {
                                    let currentPolicyID = (String(describing: eachItem ?? 0))
                                    xmlController.removeAllScriptsManual(server: server, authToken: networkController.authToken, policyID: currentPolicyID)
                                    print("Clearing maintenance for policy:\(eachItem ?? 0)")
                                }
                                print("Yes tapped")
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
            }
Spacer()
        }
                      .padding()
        //        .frame(minWidth: 300, minHeight: 100, alignment: .leading)
    }
}
//}
