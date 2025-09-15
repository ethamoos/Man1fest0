//
//  PolicyTriggersView.swift
//  Man1fest0
//
//  Created by Amos Deane on 17/06/2025.
//

import SwiftUI

struct PolicyTriggersTabView: View {
    
    var policyID: Int
    var server: String
    var resourceType: ResourceType
    
    @EnvironmentObject var networkController: NetBrain
    
    @EnvironmentObject var progress: Progress
    
    @EnvironmentObject var policyController: PolicyBrain
    
    @EnvironmentObject var xmlController: XmlBrain
    
    @EnvironmentObject var layout: Layout
    @State var trigger_login: Bool

    @State var trigger_checkin: Bool
    @State var trigger_startup: Bool
    @State var trigger_enrollment_complete: Bool

    @State var trigger_other: String = ""
    
    var body: some View {
        
        let currentTrigger_login = networkController.currentDetailedPolicy?.policy.general?.triggerLogin ?? false
        let currentTrigger_checkin = networkController.currentDetailedPolicy?.policy.general?.triggerCheckin ?? false
        let currentTrigger_startup = networkController.currentDetailedPolicy?.policy.general?.triggerStartup ?? false
        let currentTrigger_enrollment_complete = networkController.currentDetailedPolicy?.policy.general?.triggerEnrollmentComplete ?? false
        let currentTrigger_other = networkController.currentDetailedPolicy?.policy.general?.triggerOther ?? "No custom trigger set"
        
        VStack(alignment: .leading) {
            
            LazyVGrid(columns: layout.columnFlexWide, alignment: .leading, spacing: 10) {
                
                //  ##########################################################################
                //              Policy Triggers
                //  ##########################################################################
                
                Button(action: {
                    
                    progress.showProgress()
                    progress.waitForABit()
                    
                    xmlController.setPolicyTriggers(xmlContent: xmlController.currentPolicyAsXML, server: server, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, itemID: policyID, trigger_checkin: trigger_checkin, trigger_enrollment_complete: trigger_enrollment_complete, trigger_login: trigger_login, trigger_startup: trigger_startup, trigger_other: trigger_other)
                    
                    
                    // ##########################################################################
                    //                            DEBUG - POLICY
                    // ##########################################################################
                    
                    networkController.separationLine()
                    print("Setting Triggers")
                    
                }) {
                    Text("Set Triggers")
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                
                Toggle(isOn: $trigger_checkin) {
                    HStack {
                        Text("Checkin:")
                        Text("\(currentTrigger_checkin)")
                    }
                }
                .toggleStyle(.checkbox)
                
                Toggle(isOn: $trigger_login) {
                    HStack {
                        Text("Login:")
                        Text("\(currentTrigger_login)")
                    }
                }
                .toggleStyle(.checkbox)
                
                Toggle(isOn: $trigger_startup) {
                    HStack {
                        Text("Startup:")
                        Text("\(currentTrigger_startup)")
                    }
                }
                .toggleStyle(.checkbox)
                
                Toggle(isOn: $trigger_enrollment_complete) {
                    HStack {
                        Text("Enrollment Complete:")
                        Text("\(currentTrigger_enrollment_complete)")
                    }
                }
                .toggleStyle(.checkbox)
                
                    if currentTrigger_other.isEmpty != true {
                        
                        HStack {
                            Text("Custom Trigger")
                            TextField(currentTrigger_other, text: $trigger_other)
//                            Text("Custom Trigger is:\(currentTrigger_other)")
                                .textSelection(.enabled)
                        }
                        .frame(width: 250)
                        
                        
                    } else {
                        
                        Text("Custom Trigger not configured")
                    }
            }
            Spacer()
        }
        .padding()
        .onAppear() {
            trigger_other = networkController.currentDetailedPolicy?.policy.general?.triggerOther ?? "No custom trigger set"
        }
    }
}
