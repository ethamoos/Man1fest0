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
    @EnvironmentObject var layout: Layout
    
//    @State var selection: ComputerGroup
    @State var group: ComputerGroup
    @State var server: String
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            if networkController.compGroupComputers.count >= 1 {
                
                Section(header: Text("Group Members for group:\(group.name)").bold()) {
                    
                    Spacer()
                    
                    List( networkController.compGroupComputers, id: \.self ) { computer in
                        Text(String(describing: computer.name))
                    }
                }

                // Open in Browser button (matches style used in ScriptsDetailView & ComputerExtAttDetailView)
                HStack {
                    Spacer()
                    Button(action: {
                        let trimmedServer = server.trimmingCharacters(in: .whitespacesAndNewlines)
                        var base = trimmedServer
                        if base.hasSuffix("/") { base.removeLast() }
                        // Construct Jamf UI URL for this group
                        let uiURL =
                        "\(base)/staticComputerGroups.html?id=\(group.id)&o=r"
                        print("Opening group UI URL: \(uiURL)")
                        layout.openURL(urlString: uiURL)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "safari")
                            Text("Open in Browser")
                        }
                    }
                    .help("Open this group in the Jamf web interface in your default browser.")
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .padding(.top, 6)
                    Spacer()
                }
                .padding()
                .textSelection(.enabled)
                
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
        xmlController.getGroupMembersXML(server: server, groupId: selection.id, authToken: networkController.authToken)
    }
}



//
//#Preview {
//    GroupDetailView()
//}
