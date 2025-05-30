//
//  ComputerDetail.swift
//  Man1fest0
//
//  Created by Amos Deane on 29/03/2023.
//

import SwiftUI




struct ComputersBasicDetailedView: View {
    
    var server: String
    
    @EnvironmentObject var networkController: NetBrain
    
    @EnvironmentObject var layout: Layout
    
    @EnvironmentObject var progress: Progress
    
    @EnvironmentObject var pushController: PushBrain

//  Selections
    @State private var selectedDevice = ""

    @State private var selectedCommand = ""
    
    @State var computer: ComputerBasicRecord
        
    @State var computerName = ""

    @State private var showingWarning = false
    
    
#if os(macOS)
    
    @Binding var selection: ComputerBasicRecord
    
#endif
    
    var body: some View {
        
        LazyVGrid(columns: layout.columnsFlexAdaptive, spacing: 20) {
            
            VStack(alignment: .leading, spacing: 20) {
                //            Text(package.udid ?? "")
                Text("Computer Name:\t\t\(computer.name)")
                Text("Computer UDID:\t\t\(computer.udid)")
                Text("Computer ID:\t\t\t\(computer.id)")
                Text("Primary username:\t\(computer.username)")
                Text("Department:\t\t\t\(computer.department)")
                Text("Building:\t\t\t\t\(computer.building)")
                Text("Computer Model:\t\t\(String(computer.model))")
                Text("Last checkin:\t\t\t\(String(computer.reportDateUTC))")
                //            Text("Last checkin2:\(String(computer.reportDateEpoch))")
                Text("Serial Number:\t\t\(computer.serialNumber )")
                
                Button(action: {
                    print("Delete")
                    showingWarning = true
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "delete.left.fill")
                        Text("Delete")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .shadow(color: .gray, radius: 2, x: 0, y: 2)
                .alert(isPresented: $showingWarning) {
                    Alert(title: Text("Caution!"), message: Text("This action will delete data.\n Always ensure that you have a backup!"), dismissButton: .default(Text("I understand!")))
                }
                
                .navigationViewStyle(DefaultNavigationViewStyle())
                
                HStack {
                    
                    TextField(String(describing:computer.name ), text: $computerName)
                        .textSelection(.enabled)
                    Button(action: {
                        progress.showProgress()
                        progress.waitForABit()
                        networkController.updateComputerName(server: server, authToken: networkController.authToken, resourceType: ResourceType.computerDetailed, computerName: computerName, computerID: String(describing:computer.id))
                        
                        networkController.separationLine()
                        print("Renaming computerName:\(computerName)")
                        print("computerID is:\(String(describing:computer.id))")
                    }) {
                        Text("Rename")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
                    
//                    LazyVGrid(columns: layout.columnsFlex) {
//                        Picker("Devices", selection: $selectedDevice) {
//                            ForEach(pushController.deviceTypes, id: \.self) {
//                                Text(String(describing: $0))
//                            }
//                        }
//                    }
                    
                    LazyVGrid(columns: layout.columnsFlexAdaptive) {
                        Picker("Commands", selection: $selectedCommand) {
                            ForEach(pushController.flushCommands, id: \.self) {
                                Text(String(describing: $0))
                            }
                        }
                    }
                    
                    Button("Flush Commands") {
                        
                        progress.showProgress()
                        progress.waitForABit()
                        
                        Task {
                           try await pushController.flushCommands(targetId: computer.id, deviceType: "computers", command: selectedCommand, authToken: networkController.authToken, server: server )
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .shadow(color: .gray, radius: 2, x: 0, y: 2)
//                }
                
                Spacer()
                
            }
            .textSelection(.enabled)

            .padding()
            Spacer()

            .onAppear {
                
                    networkController.refreshDepartments()

            }
        }
    }
}

//struct ComputerDetailedView_Previews: PreviewProvider {
//    static var previews: some View {
//        ComputerDetail()
//    }
//}
