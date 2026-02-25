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
            HStack {
                VStack(alignment: .leading) {
                    Text("Prestage Assignments").font(.title).fontWeight(.semibold)
                    Text("Devices grouped by prestage ID").font(.subheadline).foregroundColor(.secondary)
                }
                Spacer()
                Text("\(prestageController.serialPrestageAssignment.count) Devices").font(.subheadline).foregroundColor(.secondary)
            }
            .padding([.top, .horizontal])
            
            if prestageController.allPsScComplete == true && prestageController.serialPrestageAssignment.count > 0 {
                NavigationView {
                    VStack {
                        VStack {
                            List (searchResults, id: \.self) { serial in
                                NavigationLink(destination: PrestagesEditView(initialPrestageID:  prestageController.serialPrestageAssignment[serial] ?? "", targetPrestageID: "", serial: serial, server: server, showProgressScreen: false)) {
                                    HStack {
                                        Image(systemName: "desktopcomputer")
                                        Text (serial).lineLimit(1)
                                    }
                                }
                                .foregroundColor(.blue)
                            }
                            .searchable(text: $searchText)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(NSColor.windowBackgroundColor)).shadow(radius: 1))
                        .frame(minWidth: 400, minHeight: 120, alignment: .leading)

                    }
#if os(macOS)
                    .navigationTitle("Devices by Prestage ID")
#endif
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
    
    
    
    //struct PrestagesAssignments_Previews: PreviewProvider {
    //    static var previews: some View {
    //        PrestagesAssignments(server: server)
    //    }
    //}

}
