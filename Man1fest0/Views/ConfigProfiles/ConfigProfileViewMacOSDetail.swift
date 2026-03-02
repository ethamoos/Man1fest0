//
//  ConfigProfileDetailView.swift
//  Man1fest0
//
//  Created by Amos Deane on 28/11/2023.
//

import SwiftUI

struct ConfigProfileViewMacOSDetail: View {
    
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var pushController: PushBrain
    @EnvironmentObject var layout: Layout

    @State var selection: ConfigurationProfiles.ConfigurationProfile
    @State private var selectedDevice = ""
    @State private var selectedCommand = ""

    @State var server: String
    
//    @State var deviceTypes = [ "computer", "mobile" ]
//    @State var flushCommands = [ "Pending", "Failed", "Pending+Failed" ]
    
    @State private var showingWarning = false
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            Section(header: Text("Config Profile Detail").bold()) {
              
                    Text("Name:\t\(selection.name)")
                    Text("ID:\t\(String(describing: selection.jamfId ?? 0))")
            }

//            LazyVGrid(columns: layout.columnsFlex) {
//                Picker("Devices", selection: $selectedDevice) {
//                    ForEach(pushController.deviceTypes, id: \.self) {
//                        Text(String(describing: $0))
//                    }
//                }
//            }
//            
//            LazyVGrid(columns: layout.columnsFlex) {
//                Picker("Commands", selection: $selectedCommand) {
//                    ForEach(pushController.flushCommands, id: \.self) {
//                        Text(String(describing: $0))
//                    }
//                }
//            }
//            
//            Button("Flush Commands") {
//                
//                progress.showProgress()
//                progress.waitForABit()
//                
//                Task {
//                   try await pushController.flushCommands(deviceId: selection.jamfId!, deviceType: selectedDevice, command: selectedCommand, authToken: networkController.authToken, server: server )
//                }
//            }
//            .buttonStyle(.borderedProminent)
//            .tint(.blue)
//            .shadow(color: .gray, radius: 2, x: 0, y: 2)
            
            Button(action: {
                progress.showProgress()
                progress.waitForABit()
                showingWarning = true
                print("Deleting:\($selection)")
                networkController.deleteConfigProfile(server: server, authToken: networkController.authToken, resourceType: ResourceType.configProfileDetailedMacOS, itemID: String(describing: selection.jamfId))
                print("Deleting ConfigProfile:\(String(describing: selection.jamfId ?? 0))")
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "trash")
                    Text("Delete Profile")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .shadow(color: .gray, radius: 2, x: 0, y: 2)
        }
  
        .padding(20)
        Spacer()
    }
    
}
    //struct ConfigProfileDetailView_Previews: PreviewProvider {
    //    static var previews: some View {
    //        ConfigProfileDetailView()
    //    }
    //}
