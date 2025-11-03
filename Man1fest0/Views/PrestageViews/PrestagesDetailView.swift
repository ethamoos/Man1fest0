//
//  PrestagesDetailView.swift
//  Man1fest0
//
//  Created by Amos Deane on 29/01/2024.
//

import SwiftUI

struct PrestagesDetailView: View {
    
    //    This shows prestage detail
    
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var prestageController: PrestageBrain
    @State var searchText = ""
    var prestage: PreStage
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            VStack(alignment: .leading) {
                Text(prestage.displayName)
                Text("ID:\(prestage.id)")
            }
            .padding()
            .foregroundColor(.blue)
            
            NavigationView {
                
                VStack {
                    
                    if let prestageMembers = prestageController.selectedPrestageScope {
                        
                        if prestageMembers.assignments.count > 0 {
                            
                            List {
                                ForEach(prestageMembers.assignments, id: \.self) { prestageAssignment in
                                    NavigationLink(destination: PrestageDetailView2(prestageAssignment: prestageAssignment)) {
                                        HStack {
                                            Image(systemName: "desktopcomputer")
                                            Text(prestageAssignment.serialNumber)
                                        }
                                    }
                                }
                            }
                            .foregroundColor(.blue)
                            
                        } else {
                            
                            Text("No devices assigned to this prestage")
                            Spacer()
                        }
                    }
                }
                .frame(minWidth: 400, minHeight: 100, alignment: .leading)
                .padding()
            }
        }
        
        .onAppear {
            Task {
                await showPrestage(prestageID: String(describing:prestage.id), authToken: networkController.authToken)
            }
        }
    }
    
    func showPrestage(prestageID: String, authToken: String) async {
        separationLine()
        print("Running: showPrestage")
        
        Task {
            try await prestageController.getPrestageCurrentScope(jamfURL: prestageController.server, prestageID: prestageID, authToken: networkController.authToken)
        }
    }
}


//struct PrestageDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        PrestageDetailView(prestage)
//    }
//}
