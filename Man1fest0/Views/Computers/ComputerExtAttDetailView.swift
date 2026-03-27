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
    @EnvironmentObject var layout: Layout

    // Local state for editable fields
    @State private var currentCompExtAttDet: ComputerExtensionAttributeDetailed = ComputerExtensionAttributeDetailed(id: 0, name: "", enabled: true, description: "", dataType: "", inputType: InputType(type: "", platform: "", script: ""), inventoryDisplay: "")
    @State private var eaName: String = ""
    @State private var eaDescription: String = ""
    @State private var eaScriptBody: String = ""
    @State private var isUpdating: Bool = false
    @State private var showUpdateError: Bool = false
    @State private var updateErrorMessage: String = ""
    
     var body: some View {
        VStack(alignment: .leading) {

            // Delete button
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

            // Open in Browser button (match PolicyDetailView / ScriptsDetailView style)
            HStack {
                Spacer()
                Button(action: {
                    let trimmedServer = server.trimmingCharacters(in: .whitespacesAndNewlines)
                    var base = trimmedServer
                    if base.hasSuffix("/") { base.removeLast() }
                    // Jamf UI path for extension attributes
                    let eaID = computerEA.id
                    let uiURL = "\(base)/view/settings/computer-management/computer-extension-attributes/\(eaID)"
                    print("Opening extension attribute UI URL: \(uiURL)")
                    layout.openURL(urlString: uiURL)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "safari")
                        Text("Open in Browser")
                    }
                }
                .help("Open this extension attribute in the Jamf web interface in your default browser.")
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .padding(.top, 6)
                Spacer()
            }
            .padding()
            .textSelection(.enabled)

            // Script Detail / Editable fields
            Section(header: Text("Extension Attribute").bold()) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Name:")
                        TextField("Name", text: $eaName)
                            .textFieldStyle(.roundedBorder)
                    }
                    HStack {
                        Text("ID:")
                        Text(String(computerEA.id))
                    }

                    HStack(alignment: .top) {
                        VStack(alignment: .leading) {
                            Text("Description:")
                            TextEditor(text: $eaDescription)
                                .frame(minHeight: 80)
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.2)))
                        }
                    }

                    VStack(alignment: .leading) {
                        Text("Script:")
                        TextEditor(text: $eaScriptBody)
                            .frame(minHeight: 160)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.2)))
                    }

                    HStack(spacing: 12) {
                        Button(action: {
                            // Run update
                            Task {
                                await MainActor.run { isUpdating = true }
                                do {
                                    try await extensionAttributeController.updateComputerExtensionAttributeScript(server: server, authToken: networkController.authToken, extAtId: String(computerEA.id), extAtName: eaName.isEmpty ? computerEA.name : eaName, enabled: currentCompExtAttDet.enabled, description: eaDescription, scriptBody: eaScriptBody)
                                    // refresh
                                    try await extensionAttributeController.getComputerExtAttributeDetailed(server: server, authToken: networkController.authToken, compExtAttId: String(describing: computerEA.id))
                                    await MainActor.run {
                                        currentCompExtAttDet = extensionAttributeController.computerExtensionAttributeDetailed
                                        eaName = currentCompExtAttDet.name
                                        eaDescription = currentCompExtAttDet.description
                                        eaScriptBody = currentCompExtAttDet.inputType.script
                                    }
                                } catch {
                                    print("Failed to update EA script: \(error)")
                                    await MainActor.run {
                                        updateErrorMessage = String(describing: error)
                                        showUpdateError = true
                                    }
                                }
                                await MainActor.run { isUpdating = false }
                            }
                        }) {
                            if isUpdating {
                                ProgressView()
                            } else {
                                Text("Update")
                            }
                        }
                        .buttonStyle(.borderedProminent)

                        Button(action: {
                            // reload details
                            Task {
                                do {
                                    try await extensionAttributeController.getComputerExtAttributeDetailed(server: server, authToken: networkController.authToken, compExtAttId: String(describing: computerEA.id))
                                    await MainActor.run {
                                        currentCompExtAttDet = extensionAttributeController.computerExtensionAttributeDetailed
                                        eaName = currentCompExtAttDet.name
                                        eaDescription = currentCompExtAttDet.description
                                        eaScriptBody = currentCompExtAttDet.inputType.script
                                    }
                                } catch {
                                    print("Failed to reload EA detail: \(error)")
                                }
                            }
                        }) {
                            Text("Reload")
                        }
                    }
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
        .multilineTextAlignment(.leading)
        .padding()
        .onAppear {
            print("ComputerExtAttributeView appeared. Running onAppear")
            // initialize local copy from controller and populate editable fields
            currentCompExtAttDet = extensionAttributeController.computerExtensionAttributeDetailed
            eaName = currentCompExtAttDet.name.isEmpty ? computerEA.name : currentCompExtAttDet.name
            eaDescription = currentCompExtAttDet.description
            eaScriptBody = currentCompExtAttDet.inputType.script
            Task {
                do {
                    try await extensionAttributeController.getComputerExtAttributeDetailed(server: server, authToken: networkController.authToken, compExtAttId: String(describing: computerEA.id))
                    await MainActor.run {
                        currentCompExtAttDet = extensionAttributeController.computerExtensionAttributeDetailed
                        eaName = currentCompExtAttDet.name
                        eaDescription = currentCompExtAttDet.description
                        eaScriptBody = currentCompExtAttDet.inputType.script
                    }
                } catch {
                    print("Failed to load computer EA detail: \(error)")
                }
            }
        }
        .alert(isPresented: $showUpdateError) {
            Alert(title: Text("Update failed"), message: Text(updateErrorMessage), dismissButton: .default(Text("OK")))
        }
     }
 }
