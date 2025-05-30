//
//  GroupsSmartView.swift
//  Man1fest0
//
//  Created by Amos Deane on 27/05/2025.
//




import SwiftUI

struct GroupsSmartView: View {
    
    var selectedResourceType = ResourceType.computerBasic
    
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var networkController: NetBrain
    
    
    
    @State var server: String
    @State private var showingWarning = false
    
    //  ################################################################################
    //  SEARCHES AND SELECTIONS
    //  ################################################################################
    
    @State private var searchText = ""
    @State private var searchTextComp = ""
    @State var selectionGroup = ComputerGroup(id: 0, name: "", isSmart: false)
    @State var selectionComp = ComputerBasicRecord(id: 0, name: "", managed: false, username: "", model: "", department: "", building: "", macAddress: "", udid: "", serialNumber: "", reportDateUTC: "", reportDateEpoch: 0)
    
    @State var mySelection: String = ""
    
    @State var selection = Set<ComputerGroup>()

    
    //  ########################################################################################
    //  Filters
    //  ########################################################################################
    
    @State var computerGroupFilter = ""
    @State var allLdapServersFilter = ""
    
    
    let columns = [
        GridItem(.fixed (170)),
        GridItem(.fixed (170)),
    ]
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            Section(header: Text("Smart Groups:").bold().padding()) {
                
                NavigationView {
                    
                    if searchResults.count > 0 {
                        
#if os(macOS)
                        
                        
                        List(networkController.allComputerGroups.filter({computerGroupFilter == "" ? true : $0.name.contains(computerGroupFilter)}) , id: \.self,selection: $selection) { group in
                            if group.isSmart == true {
                                Text(String(describing: group.name))
                            }
                        }
                        .foregroundColor(.blue)
                        
                        
                        
                        
                        
#else
                        List(searchResults, id: \.self) { group in
                            if group.isSmart != true {
                                NavigationLink(destination: GroupDetailView( group: group, server: server)) {
                                    Text(String(describing: group.name))
                                }
                            }
                        }
                        .foregroundColor(.blue)
#endif
                    }
                }
            }
            
            VStack() {
                
                
                Button(action: {
                    
                    progress.showProgress()
                    progress.waitForABit()
                    
                    Task {
                        try await networkController.getAllGroups(server: server, authToken: networkController.authToken)
                    }
 
                    
                }) {
#if os(macOS)
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
#else
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.clockwise")
                    }
#endif
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                
                Button(action: {
                    
                    progress.showProgress()
                    progress.waitForABit()
                    showingWarning = true
                    
                  
                    
                }) {
#if os(macOS)
                    HStack(spacing: 10) {
                        Image(systemName: "delete.left")
                        Text("Delete")
                    }
#else
                    HStack(spacing: 10) {
                        Image(systemName: "delete.left")
                    }
#endif
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .shadow(color: .gray, radius: 2, x: 0, y: 2)
                .alert(isPresented: $showingWarning) {
                    Alert(
                        title: Text("Caution!"),
                        message: Text("This action will delete data.\n Always ensure that you have a backup!"),
                        primaryButton: .destructive(Text("I understand!")) {
                            // Code to execute when "Yes" is tapped
                            Task {
                                try await networkController.batchDeleteGroup(selection: selection, server: server, authToken: networkController.authToken, resourceType: ResourceType.computerGroup)
                            }
                            print("Yes tapped")
                        },
                        secondaryButton: .cancel()
                    )
                }
                
            }
            .padding()
        }
        
        Divider()
  
            .onAppear() {
                Task {
                    try await networkController.getAllGroups(server: server, authToken: networkController.authToken)
                }
            }
        
        if progress.showProgressView == true {
            
            ProgressView {
                Text("Loading")
                    .font(.title)
                    .progressViewStyle(.horizontal)
            }
            .padding()
            Spacer()
        }
    }
    
    func runGetGroupMembers(selection: ComputerGroup, authToken: String) async {
        
        let mySelection = String(describing: selection.name)
        
        do {
            try await networkController.getGroupMembers(server: server, name: mySelection)
        } catch {
            print("Error getting GroupMembers")
            print(error)
        }
        networkController.getGroupMembersXML(server: server, groupId: selection.id)
    }
    
    var searchResults: [ComputerGroup] {
        
        if searchText.isEmpty {
            return networkController.allComputerGroups
        } else {
            print("Search ComputerGroup Added - item is:\(searchText)")
            return networkController.allComputerGroups.filter { $0.name.lowercased().contains(searchText.lowercased())}
        }
    }
}

