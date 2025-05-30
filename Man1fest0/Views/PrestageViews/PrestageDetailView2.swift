//
//  PrestagesDetailView2.swift
//  Man1fest0
//
//  Created by Amos Deane on 29/01/2024.
//

import SwiftUI


struct PrestageDetailView2: View {
    
    //      Show the details of a specific prestage

    @EnvironmentObject var prestageController: PrestageBrain
    
    @State var prestageAssignment: ComputerPreStageScopeAssignment
    
        var body: some View {
        
        VStack(alignment: .leading) {
            
            if prestageController.selectedPrestageScope != nil {
                
                Text("Serial:\t\t\t\(prestageAssignment.serialNumber)")
                Text("Assigned by:\t\t\(prestageAssignment.userAssigned)")
                Text("Assigned on:\t\t\(prestageAssignment.assignmentDate)")
                Spacer()
            }
        }
        .frame(minWidth: 400, alignment: .leading)
        .padding(.all)
        .foregroundColor(.blue)
    }
}

//struct PrestagesAssignmentsDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        PrestagesAssignmentsDetailView()
//    }
//}
