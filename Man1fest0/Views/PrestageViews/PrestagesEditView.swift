//
//  PrestagesEditView.swift
//  Man1fest0
//
//  Created by Amos Deane on 29/01/2024.
//

import SwiftUI



//    #################################################################################
//      PrestageEditView
//    #################################################################################



struct PrestagesEditView: View {
    
    //      Allows the username to edit a device's prestage assigned
    
    @EnvironmentObject var prestageController: PrestageBrain
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var layout: Layout

    
    @State var initialPrestageID: String
    
    @State var currentPrestage: PreStage = PreStage(keepExistingSiteMembership: false, enrollmentSiteId: "", id: "", displayName: "")
    
    @State var currentPrestageName = ""

    @State var targetPrestageID: String
    
    @State var serial: String
    
    @State var confirmedSerial: String = ""
    
    @State var serialTextfield: String = ""
    
    @State var server: String
    
    @State var showProgressScreen: Bool
    
    @State var searchText = ""
    
    @State private var showingWarning = false
    
    @State var computerAssignedPreStage: ComputerPreStageScopeAssignment = ComputerPreStageScopeAssignment(serialNumber: "", assignmentDate: "", userAssigned: "")
    
    @State var computerAssignedPreStage2: Any = [""]
    
    //    #################################################################################
    //    Selections
    //    #################################################################################
    
    @State var selectedPrestageInitial: PreStage = PreStage(keepExistingSiteMembership: (0 != 0), enrollmentSiteId: "", id: "", displayName: "")
    
    @State var selectedPrestageTarget: PreStage = PreStage(keepExistingSiteMembership: (0 != 0), enrollmentSiteId: "", id: "", displayName: "")
    
    @State var computerSelection: String = ""
    
    var body: some View {
        
        
        let serialsPrestageName = Array (prestageController.serialPrestageAssignment.keys)
        
        
        
        //        Objective is to map the serial number to the computer name
        
        //        let selectedComputersSerialNames: [String?] = networkController.allComputersBasic.computers.filter {
        //            prestageController.serialPrestageAssignment[serial]!.contains($0.serialNumber) }
        //            .map(\.name)
        
        //    case serialNumber = "serial_number"
        
        VStack(alignment: .leading) {
            
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Update Assigned Prestage").font(.title2).fontWeight(.semibold)
                            Text("Move or remove a device from a prestage").font(.subheadline).foregroundColor(.secondary)
                        }
                        Spacer()
                    }

                    // Group: Serial and current prestage
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("Serial", systemImage: "barcode.viewfinder")
                            TextField("serial", text: $serial)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Current Prestage Name:").fontWeight(.bold)
                                TextField("Name", text: $currentPrestageName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }

                            VStack(alignment: .leading) {
                                Text("Current Prestage ID:").fontWeight(.bold)
                                TextField("ID", text: $initialPrestageID)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.windowBackgroundColor)).shadow(radius: 1))

                    // Target picker
                    VStack(alignment: .leading) {
                        Text("Target Prestage:").fontWeight(.bold)
                        Picker(selection: $selectedPrestageTarget, label: Text("Target Prestage:")) {
                            Text("").tag(PreStage(keepExistingSiteMembership: false, enrollmentSiteId: "", id: "", displayName: ""))
                            ForEach(prestageController.allPrestages, id: \.self) { prestage in
                                Text("\(prestage.displayName) (ID: \(prestage.id))")
                                    .tag(prestage)
                            }
                        }
                        .pickerStyle(.menu)
                        .onAppear {
                            if prestageController.allPrestages.isEmpty != true {
                                print("Setting allPrestages picker default")
                                print("currentPrestageID is set as:\(self.initialPrestageID)")
                            }
                        }
                    }
                    .padding(.vertical)

                    // Update button
                    HStack {
                        Spacer()
                        Button(action: {
                            // use selectedPrestageTarget.id safely
                            let targetID = selectedPrestageTarget.id
                            updatePrestage(initialPrestageID: initialPrestageID, authToken: networkController.authToken)
                            progress.showProgress()
                            progress.waitForABit()
                            print("Selecting prestage:\($selectedPrestageInitial)")
                            print("Printing serialPrestageAssignment :\(prestageController.serialPrestageAssignment)")
                            print("Printing serialsPrestageName :\(serialsPrestageName)")
                        }) {
                            Text("Update")
                                .frame(minWidth: 100)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    }

                    if progress.showProgressView == true {
                        ProgressView {
                            Text("Loading")
                                .font(.title)
                                .progressViewStyle(.horizontal)
                        }
                        .padding()
                    }
                }
                .padding()

                Divider()

                // Add Unassigned Device
                VStack(alignment: .leading, spacing: 12) {
                    Text("Add Unassigned Device").font(.headline)

                    HStack {
                        Label("Serial", systemImage: "barcode.viewfinder")
                        TextField("serial", text: $serial)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    HStack {
                        Text("Target Prestage:")
                        Picker(selection: $selectedPrestageTarget, label: Text("Target Prestage:")) {
                            Text("").tag(PreStage(keepExistingSiteMembership: false, enrollmentSiteId: "", id: "", displayName: ""))
                            ForEach(prestageController.allPrestages, id: \.self) { prestage in
                                Text(String(describing: prestage.displayName)).tag(prestage)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    Button(action: {
                        progress.showProgress()
                        progress.waitForABit()
                        let targetID = selectedPrestageTarget.id
                        showPrestage(targetPrestageID: targetID, authToken: networkController.authToken)
                    }) {
                        HStack(spacing:30) {
                            Text("Add")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.windowBackgroundColor)).shadow(radius: 1))

                Divider()

                // Unassign Device
                VStack(alignment: .leading, spacing: 12) {
                    Text("Unassign Device").font(.headline)

                    if prestageController.allPsScComplete == true && prestageController.serialPrestageAssignment.count > 0 {

                        Button(action: {
                            updatePrestage(initialPrestageID: initialPrestageID, authToken: networkController.authToken)
                        }) {
                            Text("Remove")
                        }
                        .alert(isPresented: $showingWarning) {
                            Alert(title: Text("Caution!"), message: Text("This action will delete data.\n Always ensure that you have a backup!"), dismissButton: .default(Text("I understand!")))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)

                    } else {
                        if prestageController.allPsScComplete == false {
                            ProgressView {
                                Text("Loading")
                                    .progressViewStyle(.horizontal)
                            }
                        } else {
                            Text("No Devices Assigned To A Prestage")
                        }
                    }
                }
                .padding()

            Spacer()
        }
        .padding(.top)
        .padding(.bottom)
        .onAppear() {
            getCurrentPrestageName(initialPrestageID: initialPrestageID)
            getCurrentPrestage(targetPrestageID: initialPrestageID, authToken: networkController.authToken)
            currentPrestageName = self.currentPrestage.displayName
        }
    }
    
    var searchResults: [String] {
        
        //        let serialPrestageAssignment = prestageController.serialPrestageAssignment
        let serialsArray = Array (prestageController.serialPrestageAssignment.keys)
        
        if searchText.isEmpty {
            return serialsArray
        } else {
            return serialsArray.filter { $0.contains(searchText) }
        }
    }
    
    func getCurrentPrestageName(initialPrestageID: String) {
        
        print("Running: getCurrentPrestageName")
        for eachPrestage in prestageController.allPrestages {
            
            print("Prestage is:\(eachPrestage.id)")
            
            if eachPrestage.id == initialPrestageID {
                print("We have a match")
                self.currentPrestage = eachPrestage
            }
        }
    }
    
    
    func updatePrestage(initialPrestageID: String, authToken: String) {
        prestageController.separationLine()
        
        Task {
            try await prestageController.getPrestageCurrentScope(jamfURL: prestageController.server, prestageID: initialPrestageID, authToken: authToken)
            
            try await prestageController.removeDeviceFromPrestage(server: prestageController.server, removeComputerPrestageID: initialPrestageID, serial: serial, authToken: authToken, depVersionLock: prestageController.depVersionLock)
            
            try await prestageController.getPrestageCurrentScope(jamfURL: prestageController.server, prestageID: initialPrestageID, authToken: authToken)
        }
    }
    
    func getCurrentPrestage(targetPrestageID: String, authToken: String) {
        prestageController.separationLine()
        print("Running: showPrestage")
        
        Task {
            try await prestageController.getPrestageCurrentScope(jamfURL: prestageController.server, prestageID: targetPrestageID, authToken: authToken)
        }
    }
    
    
    func showPrestage(targetPrestageID: String, authToken: String) {
        prestageController.separationLine()
        print("Running: showPrestage")
        
        Task {
            try await prestageController.getPrestageCurrentScope(jamfURL: prestageController.server, prestageID: targetPrestageID, authToken: authToken)
            
            print("Running: adding to prestage - main")
            try await prestageController.addDeviceToPrestage(server: prestageController.server, prestageID: targetPrestageID, serial: serial, authToken: authToken, depVersionLock: prestageController.depVersionLock)
        }
    }
    
    func updatePrestage(initialPrestageID: String, targetPrestageID: String) {
        
        if computerSelection != "" {
            
            confirmedSerial = computerSelection
            
            print("computerSelection picker has a value - using this")
        } else {
            print("computerSelection has no value - using passed value")
            confirmedSerial = serial
        }
        
        prestageController.separationLine()
        
        Task {
            
            print("Running getPrestageCurrentScope - to remove")
            try await prestageController.getPrestageCurrentScope(jamfURL: prestageController.server, prestageID: initialPrestageID, authToken: networkController.authToken)
            
            
            print("Removing device from current prestage")
            try await prestageController.removeDeviceFromPrestage(server: prestageController.server, removeComputerPrestageID: initialPrestageID, serial: confirmedSerial, authToken: networkController.authToken, depVersionLock: prestageController.depVersionLock)
            
            
            print("Running getPrestageCurrentScope for target prestage - to add")
            try await prestageController.getPrestageCurrentScope(jamfURL: prestageController.server, prestageID: targetPrestageID, authToken: networkController.authToken)
            
            
            print("Running: adding to prestage - main")
            try await prestageController.addDeviceToPrestage(server: prestageController.server, prestageID: targetPrestageID, serial: confirmedSerial, authToken: networkController.authToken, depVersionLock: prestageController.depVersionLock)
            
            print("Finished")
            try await prestageController.getAllDevicesPrestageScope(server: server, prestageID: targetPrestageID, authToken: networkController.authToken)
            
            showProgressScreen = false
        }
    }
}



//}
//struct PrestageEditView_Previews: PreviewProvider {
//    static var previews: some View {
//        PrestageEditView()
//    }
//}
