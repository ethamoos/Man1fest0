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
    
    
    @EnvironmentObject var extensionAttributeController: EaBrain


    
    
    

//  Selections
    @State private var selectedDevice = ""

    @State private var selectedCommand = ""
    
    @State private var selectedEAName = ""
    
    @State private var eaValue = ""

    
    @State var computer: ComputerBasicRecord
        
    @State var computerName = ""

    @State private var showingWarning = false
    
    // New fields to update an extension attribute on this computer
    @State private var updateExtAttName: String = ""
    @State private var updateExtAttValue: String = ""
    
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
                
                
                Button("Open In Browser") {
                        
                        progress.showProgress()
                        progress.waitForABit()
                    layout.openURL(urlString: "\(server)/computers.html?id=\(computer.id)&o=r", requestType: "computers")

                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .shadow(color: .gray, radius: 2, x: 0, y: 2)


                // Extension Attribute Update Section - Simple VStack instead of GroupBox
                               VStack(alignment: .leading, spacing: 12) {
                                   Text("Update Extension Attribute")
                                       .font(.headline)
                                       .foregroundColor(.primary)
                                   
//                                   Disable debug text
//                                   Text("DEBUG: \(extensionAttributeController.allComputerExtensionAttributesDict.count) EAs loaded")
//                                       .foregroundColor(.red)
//                                       .font(.caption)
//                                       .padding(5)
//                                       .background(Color.yellow.opacity(0.3))
                                   
                                   HStack {
                                       Text("Extension Attribute:")
                                       Picker("", selection: $selectedEAName) {
                                           Text("Select...").tag("")
                                           ForEach(extensionAttributeController.allComputerExtensionAttributesDict, id: \.self) { ea in
                                               Text(ea.name).tag(ea.name)
                                           }
                                       }
                                       .pickerStyle(.menu)
                                   }
                                   
                                   HStack {
                                       Text("Value:")
                                       TextField("EA Value", text: $eaValue)
                                           .textFieldStyle(.roundedBorder)
                                   }
                                   
                                    Button(action: {
                                        progress.showProgress()
                                        progress.waitForABit()
                                        Task {
                                            do {
                                                try await extensionAttributeController.updateComputerEAValue(
                                                    server: server,
                                                    authToken: networkController.authToken,
                                                    computerId: computer.id,
                                                    extAttName: selectedEAName,
                                                    updateValue: eaValue
                                                )
                                            } catch {
                                                print("Failed to update EA: \(error)")
                                            }
                                        }
                                    }) {
                                       HStack {
                                           Image(systemName: "arrow.triangle.2.circlepath")
                                           Text("Update EA Value")
                                       }
                                   }
                                   .buttonStyle(.borderedProminent)
                                   .tint(.blue)
                                   .disabled(selectedEAName.isEmpty)
                               }
                               .padding()
                               .background(Color.gray.opacity(0.1))
                               .cornerRadius(8)
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
