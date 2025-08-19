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
    
    
    
    
    var body: some View {
        
        Text("Clear Items").bold()
        
        Button(action: {
            
            progress.showProgress()
            progress.waitForABit()
            
//            xmlController.removeMaintenanceBatch(selectedPoliciesInt: selectedPoliciesInt, server: server, authToken: networkController.authToken)
            
        }) {
            HStack(spacing: 10) {
                Text("Update")
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(.blue)
    }
}
