//
//  BuildingsDetailedView.swift
//  Man1fest0
//
//  Created by Amos Deane on 27/01/2025.
//


import SwiftUI

struct BuildingsDetailedView: View {
    
    var server: String
    
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var layout: Layout
    
    @State private var selection: Building? = nil
    
    @State var building: Building
    
    @State private var buildings: [ Building ] = []
    
    @State var buildingName = ""

    var body: some View {
        
        VStack(alignment: .leading, spacing: 7.0) {
            
            Text("Department Name:\(String(describing:building.name ))")
            Text("Department ID:\(String(describing:building.id))")
//            Text("Jamf ID:\(String(describing:building.jamfId ?? 0))")
//            Spacer()
            
            
            //              ################################################################################
            //              UPDATE NAME
            //              ################################################################################
            
            Divider()
            
            VStack(alignment: .leading) {
                
                VStack(alignment: .leading) {
                    
                    Text("Update name:").fontWeight(.bold)
                    
                    LazyVGrid(columns: layout.fourColumns, spacing: 20) {
                        
                        HStack {
                            
                            TextField(String(describing:building.name ), text: $buildingName)
                            //                                  TextField("Filter", text: $computerGroupFilter)
                            
                            Button(action: {
                                progress.showProgress()
                                progress.waitForABit()
                                networkController.updateBuildingName(server: server, authToken: networkController.authToken, resourceType: ResourceType.buildingDetailed, buildingID: String(describing:building.id), buildingName: buildingName, updatePressed: true)
                                //                            networkController.updateSSName(server: server, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, policyName: policyName, policyID: String(describing: policyID))
                                networkController.separationLine()
                                print("Renaming Department:\(buildingName)")
                                print("buildingID is:\(String(describing:building.id))")
                            }) {
                                Text("Rename")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                        }
                        
                        Button(action: {
                            print("Refresh Buildings")
                            progress.showProgress()
                            progress.waitForABit()
                            Task {
                                try await networkController.getBuildings(server: server, authToken: networkController.authToken)
                            }
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.clockwise")
                                Text("Refresh")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    }
                }
                .textSelection(.enabled)
            }
            
            
            
            
            
            
            
            if progress.showProgressView == true {
                
                ProgressView {
                    
                    Text("Processing")
                        .padding()
                }
                
            } else {
                Text("")
            }
            
            Button(action: {
                print("Delete")
                progress.showProgress()
                progress.waitForABit()
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "delete.left.fill")
                    Text("Delete")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .shadow(color: .gray, radius: 2, x: 0, y: 2)
            Spacer()
            }
        .padding()
        .textSelection(.enabled)

    }
}

//struct BuildingsDetailed_Previews: PreviewProvider {
//    static var previews: some View {
//        BuildingsDetailed()
//    }
//}
