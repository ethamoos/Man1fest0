//
//  PrestagesAssignedView.swift
//  Man1fest0
//
//  Created by Amos Deane on 29/01/2024.
//


import SwiftUI

struct PrestagesAssignedView: View {
    
    //    #################################################################################
    //      All Devices Assigned
    //    #################################################################################
    //    This lists all devices that are assigned to a prestage
    
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var prestageController: PrestageBrain
    @State var searchText = ""
    @State var server: String
    
    var body: some View {
        
        
        
        
        VStack(alignment: .leading) {
            
            if prestageController.allPsScComplete == true && prestageController.serialPrestageAssignment.count > 0 {
                
                NavigationView {
                    
//                    let serialsByPrestage = prestageController.serialPrestageAssignment
                    
                    List (searchResults, id: \.self) { serial in
                        NavigationLink(destination: PrestagesEditView(initialPrestageID:  prestageController.serialPrestageAssignment[serial] ?? "", targetPrestageID: "", serial: serial, server: server, showProgressScreen: false)) {
                            HStack {
                                Image(systemName: "desktopcomputer")
                                Text (serial)
                            }
                        }
                        .foregroundColor(.blue)
                    }
                    .searchable(text: $searchText)
#if os(macOS)
                    .navigationTitle("Devices by Prestage ID")
#endif
                    .frame(minWidth: 400, minHeight: 100, alignment: .leading)
                    Text("\(prestageController.serialPrestageAssignment.count) Devices found")
                    
                    
//                    List (prestageController.allPrestagesScope ?? [], id: \.self) { serial in
//                       
//                            HStack {
//                                Image(systemName: "desktopcomputer")
//                                Text (serial)
//                            }
//                        }
//                        .foregroundColor(.blue)
//                    }
                
                }
                
            } else {
                
                if prestageController.allPsScComplete == false {
                    
                    ProgressView {
                        
                        Text("Loading")
                            .progressViewStyle(.horizontal)
                    }
                } else {
                    Text("No Devices Assigned To A Prestage")
                        .padding()
                }
            }
        }
        .onAppear {
            
            Task {
                try await prestageController.getAllDevicesPrestageScope(server: server, prestageID: prestageController.serialPrestageAssignment[""] ?? "" , authToken: networkController.authToken)
            }
        }
    }
    
        //          ###############################################################
        //          Computed property
        //          ###############################################################
        
        var searchResults: [String] {
            
            let serialsArray = Array (prestageController.serialPrestageAssignment.keys)
//            let prestageIds = Array (prestageController.serialPrestageAssignment.values)
            
            if searchText.isEmpty {
                return serialsArray
            } else {
                return serialsArray.filter { $0.contains(searchText) }
            }
        }
    }
    
    
    
    //struct PrestagesAssignments_Previews: PreviewProvider {
    //    static var previews: some View {
    //        PrestagesAssignments(server: server)
    //    }
    //}
