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
    //    private var selectedPolicyjamfIDs: Set<General>
    var selectedPoliciesInt: [Int?]
    
    //    private var policyID: String
    
    @State private var showingWarningClearPackages = false
    @State private var showingWarningClearScripts = false
    @State private var showingWarningDelete = false

    
    
    var body: some View {
        
        
        VStack(alignment: .leading) {
            
//            LazyVGrid(columns: layout.columnsFlexMedium, spacing: 20) {
//            LazyVGrid(columns: layout.fourColumnsAdaptive, spacing: 20) {
            LazyVGrid(columns: layout.columnsAdaptive, spacing: 20) {
                
                HStack {
                    
                    //  ################################################################################
                    //              DELETE
                    //  ################################################################################
                    
                    Button(action: {
                        showingWarningDelete = true
                        progress.showProgressView = true
                        print("Set showProgressView to true")
                        print(progress.showProgressView)
                        progress.waitForABit()
                        print("Check processingComplete")
                        print(String(describing: networkController.processingComplete))
                    }) {
                        Text("Delete Policies")
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
                    
                    Button(action: {
                        showingWarningClearPackages = true
                        progress.showProgress()
                        progress.waitForABit()
                    }) {
                        HStack(spacing: 10) {
                            Text("Clear Packages")
                        }
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
            }
            
            LazyVGrid(columns: layout.columnsAdaptive, spacing: 20) {
                    
                    HStack {

                    Button(action: {
                        showingWarningClearScripts = true
                        progress.showProgress()
                        progress.waitForABit()
                    }) {
                        HStack(spacing: 10) {
                            Text("Clear Scripts")
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
                    
//                    Button(action: {
//                        
//                        progress.showProgress()
//                        progress.waitForABit()
//                        
//                        //            xmlController.removeMaintenanceBatch(selectedPoliciesInt: selectedPoliciesInt, server: server, authToken: networkController.authToken)
//                        
//                    }) {
//                        HStack(spacing: 10) {
//                            Text("Update")
//                        }
//                    }
//                    .buttonStyle(.borderedProminent)
//                    .tint(.blue)
                    
                    
                    Button(action: {
                        
                        progress.showProgress()
                        progress.waitForABit()
                        
                        xmlController.removeMaintenanceBatch(selectedPoliciesInt: selectedPoliciesInt, server: server, authToken: networkController.authToken)
                        
                    }) {
                        HStack(spacing: 10) {
                            Text("Clear Maintenance")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }
            Spacer()
        }
    }
}
