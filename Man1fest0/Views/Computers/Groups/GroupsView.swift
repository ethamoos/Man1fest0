//
//  GroupsView.swift
//  Man1fest0
//
//  Created by Amos Deane on 02/02/2024.
//


import SwiftUI

struct GroupsView: View {
    
    var selectedResourceType = ResourceType.computerBasic
    
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var xmlController: XmlBrain
    
    @State var server: String
    @State private var showingWarning = false

    //  ################################################################################
    //  SEARCHES AND SELECTIONS
    //  ################################################################################

    @State private var searchText = ""
    @State private var searchTextComp = ""
    @State var selectionGroup = ComputerGroup(id: 0, name: "", isSmart: false)
    @State var selectionComp = ComputerBasicRecord(id: 0, name: "", managed: false, username: "", model: "", department: "", building: "", macAddress: "", udid: "", serialNumber: "", reportDateUTC: "", reportDateEpoch: 0)
    // multi-selection for computers (store ComputerBasicRecord.id values)
    @State private var selectedComputerIDs: Set<Int> = []
    
    @State var mySelection: String = ""
        
    let columns = [
        GridItem(.fixed (170)),
        GridItem(.fixed (170)),
    ]
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            // Header
//            HStack(alignment: .center) {
            HStack(alignment: .center) {
                VStack(alignment: .leading) {
                    Text("Groups")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Manage static groups")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
//                Spacer()
                Button(action: {
                    progress.showProgress()
                    progress.waitForABit()
                    Task {
                        try await networkController.getAllGroups(server: server, authToken: networkController.authToken)
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            .padding(.bottom, 6)
            
//            Section(header: Text("Static Groups:").bold().padding()) {
                
                // Filter/search field for Static Groups
                HStack {
                    TextField("Filter", text: $searchText)
#if os(macOS)
                        .textFieldStyle(.plain)
#else
                        .textFieldStyle(.roundedBorder)
#endif
                        .fixedSize(horizontal: false, vertical: true)
                        .padding([.leading, .trailing])
                    
//                    Spacer()
                }
                
                NavigationView {
                    
                    if searchResults.count > 0 {
                        
#if os(macOS)
                        List(searchResults, id: \.self, selection: $selectionGroup) { group in
                            if group.isSmart != true {
                                NavigationLink(destination: GroupDetailView( group: group, server: server)) {
                                    Text(String(describing: group.name))
                                }
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
//            }
            
//            VStack(alignment: .leading) {
//            VStack() {
                
                // Smaller, scrollable multi-select computer list (replaces full ComputerView)
                VStack(alignment: .leading) {
//                    Text("Add/Remove Computers").font(.headline)
                    DisclosureGroup("Add/Remove Computers") {

                    
                    HStack {
                        TextField("Filter computers", text: $searchTextComp)
#if os(macOS)
                            .textFieldStyle(.plain)
#else
                            .textFieldStyle(.roundedBorder)
#endif
                            .frame(minWidth: 200)
                        Spacer()
                    }
                    .padding([.leading, .trailing])
                    
                    // Scrollable, compact list with checkboxes for multi-selection
                    ScrollView(.vertical) {
                        LazyVStack(alignment: .leading, spacing: 6) {
                            ForEach(networkController.allComputersBasic.computers.filter { comp in
                                searchTextComp.isEmpty ? true : comp.name.lowercased().contains(searchTextComp.lowercased())
                            }, id: \ .id) { comp in
                                HStack {
                                    Button(action: {
                                        if selectedComputerIDs.contains(comp.id) {
                                            selectedComputerIDs.remove(comp.id)
                                        } else {
                                            selectedComputerIDs.insert(comp.id)
                                        }
                                    }) {
                                        Image(systemName: selectedComputerIDs.contains(comp.id) ? "checkmark.square.fill" : "square")
                                    }
                                    .buttonStyle(.plain)
                                    
                                    VStack(alignment: .leading) {
                                        Text(comp.name).lineLimit(1)
                                        Text("id: \(comp.id)").font(.caption).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal)
                            }
                        }
                    }
                    .frame(maxHeight: 120)
                    .border(Color.gray.opacity(0.2))
                }
                
                
                    HStack{
                        
                        Button(action: {
                            
                            progress.showProgress()
                            progress.waitForABit()
                            
                            // If the user has selected multiple computers in the list, add each.
                            if !selectedComputerIDs.isEmpty {
                                for cid in selectedComputerIDs {
                                    if let comp = networkController.allComputersBasic.computers.first(where: { $0.id == cid }) {
                                        xmlController.addComputerToGroup(xmlContent: xmlController.computerGroupMembersXML, computerName: comp.name, computerId: String(describing: comp.id), groupId: String(describing: selectionGroup.id), resourceType: ResourceType.computerGroup, server: server, authToken: networkController.authToken)
                                    }
                                }
                                // clear selection after adding
                                selectedComputerIDs.removeAll()
                            } else {
                                // fallback to previously selected single computer
                                xmlController.addComputerToGroup(xmlContent: xmlController.computerGroupMembersXML, computerName: networkController.selectedSimpleComputer.name, computerId: String(describing: networkController.selectedSimpleComputer.id), groupId: String(describing: selectionGroup.id), resourceType: ResourceType.computerGroup, server: server, authToken: networkController.authToken)
                            }
                            
                        }) {
#if os(macOS)
                            HStack(spacing: 10) {
                                Image(systemName: "plus")
                                Text("Add")
                            }
#else
                            HStack(spacing: 10) {
                                Image(systemName: "plus")
                                //                            Text("Add")
                            }
#endif
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        
                        Button(action: {
                            
                            progress.showProgress()
                            progress.waitForABit()
                            
                            Task {
                                try await networkController.getAllGroups(server: server, authToken: networkController.authToken)
                            }
                            
                            Task {
                                await runGetGroupMembers(selection: selectionGroup, authToken: networkController.authToken)
                                
                                
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
                                //                            Text("Refresh")
                            }
#endif
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        
                        Button(action: {
                            
                            progress.showProgress()
                            progress.waitForABit()
                            showingWarning = true
                            // If user selected multiple computers in the compact list, remove each; otherwise fallback to single selected
                            if !selectedComputerIDs.isEmpty {
                                for cid in selectedComputerIDs {
                                    xmlController.removeComputerFromGroup(server: server, authToken: networkController.authToken, resourceType: ResourceType.computerGroup, groupID: String(describing: selectionGroup.id), computerID: cid, computerName: "")
                                }
                                // clear selection after operation
                                selectedComputerIDs.removeAll()
                                // Refresh members after removals
                                Task {
                                    await runGetGroupMembers(selection: selectionGroup, authToken: networkController.authToken)
                                }
                            } else {
                                xmlController.removeComputerFromGroup(server: server, authToken: networkController.authToken, resourceType: ResourceType.computerGroup, groupID: String(describing: selectionGroup.id), computerID: networkController.selectedSimpleComputer.id, computerName: networkController.selectedSimpleComputer.name)
                                // single remove -> refresh
                                Task {
                                    await runGetGroupMembers(selection: selectionGroup, authToken: networkController.authToken)
                                }
                            }
                            
                        }) {
#if os(macOS)
                            HStack(spacing: 10) {
                                Image(systemName: "delete.left")
                                Text("Remove from Group")
                            }
#else
                            HStack(spacing: 10) {
                                Image(systemName: "minus.circle")
                            }
#endif
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .shadow(color: .gray, radius: 2, x: 0, y: 2)
                        .alert(isPresented: $showingWarning) {
                            Alert(title: Text("Caution!"), message: Text("This action will delete data.\n Always ensure that you have a backup!"), dismissButton: .default(Text("I understand!")))
                        }
                        
                        Button(action: {
                            progress.showProgress()
                            progress.waitForABit()
                            showingWarning = true
                            Task {
                                try await networkController.deleteGroup(server: server, resourceType: ResourceType.computerGroup, itemID: String(describing: selectionGroup.id), authToken: networkController.authToken)
                            }
                            
                        }) {
#if os(macOS)
                            HStack(spacing: 10) {
                                Image(systemName: "delete.left")
                                Text("Delete Group")
                            }
#else
                            HStack(spacing: 10) {
                                Image(systemName: "delete.left")
                                //                                Text("Delete")
                            }
#endif
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .shadow(color: .gray, radius: 2, x: 0, y: 2)
                        .alert(isPresented: $showingWarning) {
                            Alert(title: Text("Caution!"), message: Text("This action will delete data.\n Always ensure that you have a backup!"), dismissButton: .default(Text("I understand!")))
                        }
                    }
//                    Spacer()
                }
                .padding()
                //            }
                
                Divider()
                
               
//            }
        }
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
        xmlController.getGroupMembersXML(server: server, groupId: selection.id, authToken: networkController.authToken)
    }
    
    var searchResults: [ComputerGroup] {
        
        if searchText.isEmpty {
            return networkController.allComputerGroups
        } else {
            print("Search ComputerGroup Added - item is:\(searchText)")
            return networkController.allComputerGroups.filter { $0.name.lowercased().contains(searchText.lowercased())}
        }
    }
    
    var searchResultsComputers: [ComputerBasicRecord] {
        
        let allComputers = networkController.allComputersBasic.computers
        let allComputersArray = Array (allComputers)
        
        if searchTextComp.isEmpty {
            print("searchResultsComputers is empty")
            return networkController.allComputersBasic.computers
        } else {
            print("Search Added")
            return allComputersArray.filter { $0.name.contains(searchTextComp) }
        }
    }
}
