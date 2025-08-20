//
//  GroupDetailView.swift
//  Man1fest0
//
//  Created by Amos Deane on 15/02/2024.
//

import SwiftUI

struct GroupDetailView: View {
    
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var xmlController: XmlBrain
    
//    @State var selection: ComputerGroup
    @State var group: ComputerGroup
    @State var server: String
//    var username: String
//    var password: String
    
    var body: some View {
        
        //        Divider()
        VStack(alignment: .leading) {
            
            if networkController.compGroupComputers.count >= 1 {
                
                Section(header: Text("Group Members for group:\(group.name)").bold()) {
                    
                    Spacer()
                    
                    List( networkController.compGroupComputers, id: \.self ) { computer in
                        Text(String(describing: computer.name))
                    }
                }
                
            } else {
                Text("No members found")
            }
            
            Spacer()
        
                .onAppear {
                    
                    Task {
                        await runGetGroupMembers(selection: group, authToken: networkController.authToken)
                    }
                }
        }
        .padding()
        .textSelection(.enabled)
    }
    
    func runGetGroupMembers(selection: ComputerGroup, authToken: String) async {
        
        let mySelection = String(describing: selection.name)
        
        do {
            try await networkController.getGroupMembers(server: server, name: mySelection)
        } catch {
            print("Error getting GroupMembers")
            print(error)
        }
        
        xmlController.getGroupMembersXML    (server: server, groupId: selection.id)
        
    }
}



//
//#Preview {
//    GroupDetailView()
//}
