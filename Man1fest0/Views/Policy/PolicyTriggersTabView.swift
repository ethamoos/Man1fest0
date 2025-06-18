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
    
    @State private var trigger_checkin = false
    @State private var trigger_enrollment_complete = false
    @State private var trigger_login = false
    @State private var trigger_startup = false
    @State private var trigger_other = ""
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            //  ################################################################################
            //              Policy Triggers
            //  ################################################################################
            
            Button(action: {
                
                progress.showProgress()
                progress.waitForABit()
                
                xmlController.setPolicyTriggers(xmlContent: xmlController.currentPolicyAsXML, server: server, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, itemID: policyID, trigger_checkin: trigger_checkin, trigger_enrollment_complete: trigger_enrollment_complete, trigger_login: trigger_login, trigger_startup: trigger_startup, trigger_other: trigger_other)
                
                
                // ##############################################################################
                //                            DEBUG - POLICY
                // ##############################################################################
                
                networkController.separationLine()
                print("Seting Triggers")
                
                //
            }) {
                Text("Set Triggers")
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            
            Toggle(isOn: $trigger_checkin) {
                Text("Checkin")
            }
            .toggleStyle(.checkbox)
            
            Toggle(isOn: $trigger_login) {
                Text("Login")
            }
            .toggleStyle(.checkbox)
            
            Toggle(isOn: $trigger_startup) {
                Text("Startup")
            }
            .toggleStyle(.checkbox)
            
            Toggle(isOn: $trigger_enrollment_complete) {
                Text("Enrollment Complete")
            }
            .toggleStyle(.checkbox)
            
            HStack {
                Spacer()
//                Label("Custom Trigger", systemImage: "brain.head.profile")
                Text("Custom Trigger")
                TextField("", text: $trigger_other)
                    .textSelection(.enabled)
            }
        }
        //            .background(Color.green)
        .padding()
    }
}
//}
