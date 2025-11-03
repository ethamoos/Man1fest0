//
//  PrestageRemoveDeviceView.swift
//  StagingArea
//
//  Created by Amos Deane on 12/09/2022.
//

import SwiftUI


//    #################################################################################
//      PrestageRemoveDeviceView
//    #################################################################################


struct PrestageRemoveDeviceView: View {
    
    //      Allows the username to remove a device from a prestage
    
    
    @State var currentToken = ""
    
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var prestageController: PrestageBrain
    @EnvironmentObject var progress: Progress
    
    @State var searchText = ""
    @State var server: String
    
    @State var initialPrestageID: String = ""
    
    @State var targetPrestageID: String = ""
    
    @State var serial: String = ""
    
    @State var confirmedSerial: String = ""
    
    @State var serialTextfield: String = ""
    
    //    @State var server: String
    
    @State var showProgressScreen: Bool = false
    
    @State var computerAssignedPreStage: ComputerPreStageScopeAssignment = ComputerPreStageScopeAssignment(serialNumber: "", assignmentDate: "", userAssigned: "")
    
    @State var computerAssignedPreStage2: Any = [""]
    
    @State var selectedPrestageInitial: PreStage = PreStage(keepExistingSiteMembership: (0 != 0), enrollmentSiteId: "", id: "", displayName: "")
    
    @State var selectedPrestageTarget: PreStage = PreStage(keepExistingSiteMembership: (0 != 0), enrollmentSiteId: "", id: "", displayName: "")
    
    @State var computerSelection: String = ""
    
    
    let columns = [
        GridItem(.fixed(300)),
        GridItem(.flexible()),
    ]
    
    
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            if prestageController.allPsScComplete == true && prestageController.serialPrestageAssignment.count > 0 {
                
                //                let serialsByPrestage = prestageController.serialPrestageAssignment
                
                
                //                List (searchResults, id: \.self) { serial in
                //                    NavigationLink(destination: PrestageRemoveDeviceDetailView(initialPrestageID: serialsByPrestage[serial] ?? "", serial: serial, showProgressScreen: false)) {
                //                        HStack {
                //                            Image(systemName: "desktopcomputer")
                //                            Text ("\(serial), ID: \(serialsByPrestage[serial]!)")
                //                        }
                //                    }
//                                    #if os(macOS)
//                .navigationTitle("Devices by Prestage ID")
//#endif
                //
                //                }
                //                .searchable(text: $searchText)
                Text("\(prestageController.serialPrestageAssignment.count) Devices found")
                
                
                
                
            } else {
                
                if prestageController.allPsScComplete == false {
                    
                    ProgressView {
                        
                        Text("Loading")
                            .progressViewStyle(.horizontal)
                    }
                    .padding(.all)
                    
                    
                } else {
                    
                    Text("No Devices Assigned To A Prestage")
                    
                        .padding(.all)
                }
            }
            
        }
        
        .padding(.all)
        #if os(macOS)
                .navigationTitle("Unassign Device from Prestage")
                #endif
    }
    
    
    var searchResults: [String] {
        let serialsByPrestage = prestageController.serialPrestageAssignment
        let serialsArray = Array (serialsByPrestage.keys)
        
        if searchText.isEmpty {
            return serialsArray
        } else {
            return serialsArray.filter { $0.contains(searchText) }
        }
    }
    
    
    func updatePrestage(initialPrestageID: String) {
separationLine()        
        
        print("Running getPrestageCurrentScope - to remove")
        
        Task {
            try await
            prestageController.getPrestageCurrentScope(jamfURL: prestageController.server, prestageID: initialPrestageID, authToken: networkController.authToken)
            print("Running: removing from prestage - main")
            try await prestageController.removeDeviceFromPrestage(server: prestageController.server, removeComputerPrestageID: initialPrestageID, serial: serial, authToken: networkController.authToken, depVersionLock: prestageController.depVersionLock)
            
            print("Running getPrestageCurrentScope")
            try await prestageController.getPrestageCurrentScope(jamfURL: prestageController.server, prestageID: initialPrestageID, authToken: networkController.authToken)
        }
        
    }
    
    struct PrestageRemoveDeviceDetailView: View {
        
        @State var initialPrestageID: String
        
        //    @State var targetPrestageID: String
        
        @State var serial: String
        
        @State var showProgressScreen: Bool = false
        
        @EnvironmentObject var networkController: NetBrain
        @EnvironmentObject var progress: Progress
        @EnvironmentObject var prestageController: PrestageBrain
        
        let columns = [
            GridItem(.fixed(300)),
            GridItem(.flexible(minimum: 50))
        ]
        
        var body: some View {
            
            
            //        let serialsByPrestage = prestageController.serialPrestageAssignment
            //        let serialsArray = Array (serialsByPrestage.keys)
            
            //        LazyVGrid(columns: columns, spacing: 20) {
            
            
            
            VStack() {
                
                LazyVGrid(columns: columns, spacing: 20) {
                    
                    HStack {
                        Label("serial                       ", systemImage: "globe")
                        TextField("serial", text: $serial)
                        
                    }
                    
                }
                
                
                
                
                LazyVGrid(columns: columns, spacing: 20) {
                    HStack {
                        Label("Current Prestage ID", systemImage: "ellipsis.rectangle")
                        
                        TextField("Current Prestage ID", text: $initialPrestageID)
                        
                    }
                }
                
                Button(action: {
                    
                    progress.showProgress()
                    progress.waitForABit()
                    updatePrestage(initialPrestageID: initialPrestageID)
                    
                }) {
                    HStack(spacing:30) {
                        Text("Remove")
                    }
                }
                .padding()
                Spacer()
            }
            .padding()
        }
        
        func updatePrestage(initialPrestageID: String) {
    separationLine()            
            
            Task {
                print("Running getPrestageCurrentScope - to remove")
                try await
                prestageController.getPrestageCurrentScope(jamfURL: prestageController.server, prestageID: initialPrestageID, authToken: networkController.authToken)
                print("Running: removing from prestage - main")
                try await prestageController.removeDeviceFromPrestage(server: prestageController.server, removeComputerPrestageID: initialPrestageID, serial: serial, authToken: networkController.authToken, depVersionLock: prestageController.depVersionLock)
                
                print("Running getPrestageCurrentScope")
                try await prestageController.getPrestageCurrentScope(jamfURL: prestageController.server, prestageID: initialPrestageID, authToken: networkController.authToken)
            }
        }
    }
}
    
    
    //
    //struct PrestageRemoveDeviceView_Previews: PreviewProvider {
    //    static var previews: some View {
    //        PrestageRemoveDeviceView(initialPrestageID: "23", serial: "zzcvzxvcx")
    //    }
    //}
