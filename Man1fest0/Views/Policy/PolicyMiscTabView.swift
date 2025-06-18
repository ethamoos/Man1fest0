//
//  PolicyMiscTabView.swift
//  Man1fest0
//
//  Created by Amos Deane on 17/06/2025.
//

import SwiftUI

struct PolicyMiscTabView: View {
    
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
    
    @State private var selectedTime = ""
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
//  ##########################################################################
//              Policy Triggers
//  ##########################################################################
            
            Button(action: {
                
                progress.showProgress()
                progress.waitForABit()
                
                xmlController.setPolicyMisc(xmlContent: xmlController.currentPolicyAsXML, server: server, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, itemID: policyID, trigger_checkin: trigger_checkin, trigger_enrollment_complete: trigger_enrollment_complete, trigger_login: trigger_login, trigger_startup: trigger_startup, trigger_other: trigger_other)
                
                
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
            
            LazyVGrid(columns: columns, spacing: 10) {
                
                HStack {
//                    Spacer()
                    Text("Custom Trigger")
                    TextField("", text: $trigger_other)
                        .textSelection(.enabled)
                }
            }
            
            Divider()
            
            Button(action: {
                
                progress.showProgress()
                progress.waitForABit()
                
                Task {
                    try await networkController.flushPolicyLogs(server: server, resourceType: ResourceType.logflush, itemID: String(describing:policyID), authToken: networkController.authToken, time: String(describing: selectedTime))
                }
                
// ##########################################################################
//                            DEBUG - POLICY
// ##########################################################################

                networkController.separationLine()
                print("Setting Triggers")
                
            }) {
                Text("Flush Policy Logs")
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            
            
            
            LazyVGrid(columns: layout.threeColumns, spacing: 10) {
                Picker(selection: $selectedTime, label: Text("Time")) {
                    ForEach(networkController.timePeriod, id: \.self) { time in
                        Text(String(describing: time))
                            .tag(time as String?)
                            .tag(selectedTime as String?)
                    }
                    .onAppear {
                        selectedTime = networkController.timePeriod[0] }
                }
            }
        }
//        Spacer()
        .padding()
    
    }
}
//}
