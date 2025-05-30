//
//  DepartmentsDetailed.swift
//  Man1fest0
//
//  Created by Amos Deane on 28/09/2023.
//

import SwiftUI

struct DepartmentsDetailedView: View {
    
    var server: String
    
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var layout: Layout
    
    @State private var selection: Department? = nil
    
    @State var department: Department
    
    @State private var departments: [ Department ] = []
    
    @State var departmentName = ""

    var body: some View {
        
        VStack(alignment: .leading, spacing: 7.0) {
            
            Text("Department Name:\(String(describing:department.name ))")
            Text("Department ID:\(String(describing:department.id))")
            Text("Jamf ID:\(String(describing:department.jamfId ?? 0))")
//            Spacer()
            
            
            //              ################################################################################
            //              UPDATE NAME
            //              ################################################################################
            
            Divider()
            
            VStack(alignment: .leading) {
                
                VStack(alignment: .leading) {
                    
                    Text("Update name:").fontWeight(.bold)
                    
                    LazyVGrid(columns: layout.fourColumns, spacing: 20) {
                        
                        HStack {
                            
                            TextField(String(describing:department.name ), text: $departmentName)
                            //                                  TextField("Filter", text: $computerGroupFilter)
                            
                            Button(action: {
                                progress.showProgress()
                                progress.waitForABit()
                                networkController.updateDepartmentName(server: server, authToken: networkController.authToken, resourceType: ResourceType.departmentDetailed, departmentID: String(describing:department.jamfId ?? 0), departmentName: departmentName, updatePressed: true)
                                //                            networkController.updateSSName(server: server, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, policyName: policyName, policyID: String(describing: policyID))
                                networkController.separationLine()
                                print("Renaming Department:\(departmentName)")
                                print("departmentID is:\(String(describing:department.jamfId ?? 0))")
                            }) {
                                Text("Rename")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                        }
                        
                        Button(action: {
                            print("Refresh Departments")
                            progress.showProgress()
                            progress.waitForABit()
                            networkController.connect(server: server,resourceType: ResourceType.department, authToken: networkController.authToken)
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.clockwise")
                                Text("Refresh")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    }
                }
            }
            
            
            
            
            
            
            
            if progress.showProgressView == true {
                
                ProgressView {
                    
                    Text("Processing")
                        .padding()
                }
                
            } else {
                Text("")
            }
            
            Button(action: {
                print("Delete")
                progress.showProgress()
                progress.waitForABit()
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "delete.left.fill")
                    Text("Delete")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .shadow(color: .gray, radius: 2, x: 0, y: 2)
            Spacer()
            }
        .padding()
        .textSelection(.enabled)

    }
}

//struct DepartmentsDetailed_Previews: PreviewProvider {
//    static var previews: some View {
//        DepartmentsDetailed()
//    }
//}
