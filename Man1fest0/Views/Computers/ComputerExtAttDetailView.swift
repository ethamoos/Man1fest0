//
//
//  ComputerExtAttDetailView.swift
//
//  Created by Amos Deane on 05/02/2025.
//
//
//
//
import SwiftUI

struct ComputerExtAttDetailView: View {
    
    
    var computerEA: ComputerExtensionAttribute
    
    var server: String
    
    @State private var showingWarningDelete = false

    @EnvironmentObject var progress: Progress
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var extensionAttributeController: EaBrain
    
    var body: some View {
        
        @State var currentCompExtAttDet: ComputerExtensionAttributeDetailed = extensionAttributeController.computerExtensionAttributeDetailed
        
        VStack(alignment: .leading) {
  
            Button(action: {
            
                progress.showProgress()
                progress.waitForABit()
                showingWarningDelete = true

            }) {
                HStack {
                    HStack(spacing: 10) {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                }
                .foregroundColor(.blue)
            }
            .alert(isPresented: $showingWarningDelete) {
                Alert(
                    title: Text("Caution!"),
                    message: Text("This action will delete data.\n Always ensure that you have a backup!"),
                    primaryButton: .destructive(Text("I understand!")) {
                        // Code to execute when "Yes" is tapped
                        Task {
                           try await extensionAttributeController.deleteComputerEA(server: server, resourceType: ResourceType.computerExtensionAttribute, itemID: String(describing: computerEA.id), authToken: networkController.authToken)
                        }
                        print("Delete button - Yes tapped")
                        
                    },
                    secondaryButton: .cancel()
                )
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .shadow(color: .gray, radius: 2, x: 0, y: 2)

            
            
            
            
            
            
            Section(header: Text("Script Detail").bold()) {
                VStack(alignment: .leading) {
                    Text("Name:\t\t\(computerEA.name)")
                    Text("ID:\t\t\t\(String(computerEA.id))")
                    Text("Status:\t\t\(currentCompExtAttDet.enabled)")

                }
            }
            
            if currentCompExtAttDet.description != "" {
                Divider()
                Section(header: Text("Description").bold()) {
                    Text(currentCompExtAttDet.description)
                }
            }
       
            
            if currentCompExtAttDet.dataType != "" {
                Divider()
//                            Text("Data Type:\t\(currentCompExtAttDet.dataType)")

                Section(header: Text("Data Type").bold()) {
                    Text(currentCompExtAttDet.dataType)
                }
            }
                   
            if currentCompExtAttDet.inventoryDisplay != "" {
                Divider()
                
//                            Text("Inventory Display:\t\(currentCompExtAttDet.inventoryDisplay)")
                //            Text("Input Type:\(currentCompExtAttDet.inputType.type)")

                
                
                Section(header: Text("Inventory Display").bold()) {
                    Text(currentCompExtAttDet.inventoryDisplay)
                }
            }
                   
            if currentCompExtAttDet.inputType.type != "" {
                Divider()
                
//                            Text("Input Type:\t\(currentCompExtAttDet.inputType.type)")

                Section(header: Text("Input Type").bold()) {
                    Text(currentCompExtAttDet.inputType.type)
                }
            }
                       
            if currentCompExtAttDet.inputType.platform != "" {
                Divider()
//                            Text("Platform Type:\t\(currentCompExtAttDet.inputType.platform)")

                Section(header: Text("Platform Type").bold()) {
                    Text(currentCompExtAttDet.inputType.platform)
                }
            }
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading) {
                    Section(header: Text("Script:\n").bold()) {
                        Text(currentCompExtAttDet.inputType.script)
                    }
                }
            }
            
            
            
            
            //            Text("Name:\(computerEA.name)")
            //            Text("ID:\(String(computerEA.id))")
            //            Text("Status:\(currentCompExtAttDet.enabled)")
            //            Text("Description:\(currentCompExtAttDet.description)")
            //            Text("Data Type:\(currentCompExtAttDet.dataType)")
            //            Text("Inventory Display:\(currentCompExtAttDet.inventoryDisplay)")
            //            Text("Input Type:\(currentCompExtAttDet.inputType.type)")
            //            Text("Platform Type:\(currentCompExtAttDet.inputType.platform)")
            //            Text("Script:\(currentCompExtAttDet.inputType.script)")
            //
            
        }
        //        .multilineTextAlignment(.leading)
        .padding()
        .onAppear {
            print("ComputerExtAttributeView appeared. Running onAppear")
            
            Task {
                
                //  #######################################################################
                //            getComputerExtAttributes
                //  #######################################################################
                
                try await extensionAttributeController.getComputerExtAttributeDetailed(server: server, authToken: networkController.authToken, compExtAttId: String(describing: computerEA.id))
            }
        }
    }
}
