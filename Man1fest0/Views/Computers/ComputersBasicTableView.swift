//
//  ComputersBasicTableView.swift
//
//  Created by Amos Deane on 28/08/2024.
//

import SwiftUI

struct ComputersBasicTableView: View {
    
    @State var server: String
    
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var layout: Layout
    @EnvironmentObject var pushController: PushBrain
    @EnvironmentObject var xmlController: XmlBrain
    @EnvironmentObject var extensionAttributeController: EaBrain

    var selectedResourceType = ResourceType.computerBasic
    
    @State private var showingWarning = false
    @State private var searchText = ""
    @State private var departmentFilterText = ""
    
    
    //              ##########################################################################
    //              Selections
    //              ##########################################################################
    
//
    
//    @State var selection = Set<ComputerBasicRecord.ID>()
    @State var selection = Set<ComputerBasicRecord.ID>()

//    @State var selectionComp = Set<Computer>()
//    @State var selectionGroup = ComputerGroup(id: 0, name: "", isSmart: false)
    @State  var selectionCategory: Category = Category(jamfId: 0, name: "")
    @State private var selectionDepartmentId: String = ""
   
    @State private var computerGroupFilter: String = ""
    @State private var selectionCompGroup: ComputerGroup? = nil
    @State private var selectedDevice = ""
    @State private var selectedCommand = ""
    
    
    @State private var sortOrder = [KeyPathComparator(\ComputerBasicRecord.id)]
    @State private var newComputerName = ""
    
    @State private var selectedEAName = ""
    @State private var eaValue = ""
    @State private var eaFilterText = ""
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            if networkController.allComputersBasic.computers.count > 0 {

                // Inline refresh button (removed ambiguous .toolbar usage)
                HStack {
                    Button(action: {
                        
                        Task {
                            try await networkController.getComputersBasic(server: server, authToken: networkController.authToken)
                        }
                        
                        progress.showProgress()
                        progress.waitForABit()
                        print("Refresh")
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh")
                        }
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                }

                Table(searchResults, selection: $selection, sortOrder: $sortOrder) {
                    
                    TableColumn("Name", value: \.name)
                    TableColumn("User", value: \.username)
                    TableColumn("ID") {
                        computer in
                        Text(String(computer.id))
                    }
                    TableColumn("Department", value: \.department)
                    TableColumn("Building", value: \.building)
                    TableColumn("Model", value: \.model)
                    TableColumn("Serial", value: \.serialNumber)
                    TableColumn("Checkin", value: \.reportDateUTC)
                }
                .searchable(text: $searchText)
                .onChange(of: sortOrder) { newOrder in
                    // Optionally, sort searchResults if needed
                    // If sorting is required, implement sorting logic here
                }
                
            } else {
                
                ProgressView {
                    Text("Loading data")
                        .font(.title)
                }
                .padding()
                Spacer()
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                Text("\(networkController.allComputersBasic.computers.count) total computers")
                Text("You have:\(selection.count) selections")
            }
            .padding()
            
            Divider()
            
            //              ##########################################################################
            //              DELETE AND PROCESS SELECTION
            //              ##########################################################################
            
            VStack(alignment: .leading, spacing: 10) {
                
                HStack {
                    
                    Button(action: {
                        showingWarning = true
                        progress.showProgress()
                        progress.waitForABit()
                        print("Set showProgressView to true")
                        print(progress.showProgressView)
                        print("Check processingComplete")
                    }) {
                        Text("Delete Selection/s")
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
                                networkController.processDeleteComputersBasic(selection: selection, server: server, authToken: networkController.authToken, resourceType: ResourceType.policies)
                                print("Yes tapped")
                                
                            },
                            secondaryButton: .cancel()
                        )
                    }
                    
                    
                    Button(action: {
                        
                        Task {
                            try await networkController.getComputersBasic(server: server, authToken: networkController.authToken)
                        }
                        
                        print("Refresh")
                        progress.showProgress()
                        progress.waitForABit()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    
                    //              ##########################################################################
                    //              New Computer Name to SELECTION
                    //              ##########################################################################
                    
                    LazyVGrid(columns: layout.columnsFlex, spacing: 20) {
                        
                        HStack {
                            TextField("New Computer Name", text: $newComputerName)
                                .textSelection(.enabled)
                            
                            Button(action: {
                                progress.showProgress()
                                progress.waitForABit()
                                print("Set showProgressView to true")
                                print(progress.showProgressView)
                                print("Check processingComplete")
                                print(String(describing: networkController.processingComplete))
                                print("Running:processDeleteComputers")
                                networkController.processUpdateComputerName(selection: selection, server: server, authToken: networkController.authToken, resourceType: ResourceType.computerDetailed, computerName: newComputerName)
                            }) {
                                Text("Name Selections")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .shadow(color: .gray, radius: 2, x: 0, y: 2)
                    }
                }
                .padding()
                
                Divider()
                
                //              ##########################################################################
                //              Department
                //              ##########################################################################
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 250)), GridItem(.flexible())]) {
                    VStack(alignment: .leading) {
                        HStack {
                            TextField("Filter Departments", text: $departmentFilterText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Button(action: {
                                
                                //  ##########################################################################
                                //  processUpdateComputerDepartment
                                //  ##########################################################################
                                
                                networkController.processUpdateComputerDepartmentBasic(selection: selection, server: server, authToken: networkController.authToken, resourceType: selectedResourceType, department: selectedDepartmentName)
                                progress.showProgress()
                                progress.waitForABit()
                                
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Update")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                        }
                    
                    Picker(selection: $selectionDepartmentId, label: Text("Department:").bold()) {
                        Text("").tag("")
                        ForEach(filteredDepartments, id: \.self) { department in
                            Text(String(describing: department.name)).tag(department.id)
                        }
                    }
                    }

                }
             
                    
                
                //  ##########################################################################
                //  Commands
                //  ##########################################################################
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 250)), GridItem(.flexible())]) {
                        Picker("Commands", selection: $selectedCommand) {
                            ForEach(pushController.flushCommands, id: \.self) {
                                Text(String(describing: $0))
                            }
                        }
                    }
                            
                Button("Flush Commands") {
                    
                    progress.showProgress()
                    progress.waitForABit()
                    
                    Task {
                        await pushController.flushCommandBatch(server: server, authToken: networkController.authToken, selectionComp: selection, selectedCommand: selectedCommand, deviceType: "computers")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .shadow(color: .gray, radius: 2, x: 0, y: 2)

                
                
                
                
                
                
         
            
            
            //              ##########################################################################
            //              Selections
            //              ##########################################################################
            
           
            //              ##########################################################################
            //              Computer Group Picker
            //              ##########################################################################
           
            Divider()
            
            //  ##########################################################################
            //  processUpdateAddComputersToGroup
            //  ##########################################################################
            
    Button(action: {
        
        progress.showProgress()
        progress.waitForABit()
        
        // Call the real update group function and show progress
        guard let compGroup = selectionCompGroup else {
            // No group selected - nothing to do
            return
        }
        
        // Request group members XML then call addMultipleComputersToGroup when the XML is available.
        Task {
            xmlController.getGroupMembersXML(server: server, groupId: compGroup.id, authToken: networkController.authToken)

            // wait for the xmlController to populate computerGroupMembersXML (timeout after ~3s)
            var attempts = 0
            while xmlController.computerGroupMembersXML.isEmpty && attempts < 15 {
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s
                attempts += 1
            }

            if xmlController.computerGroupMembersXML.isEmpty {
                print("Warning: did not receive group members XML in time; proceeding with whatever XML is available")
            } else {
                print("Got groupMembers XML")
            }

            xmlController.addMultipleComputersToGroupOld(xmlContent: xmlController.computerGroupMembersXML,
                                                     computers: selection,
                                                     authToken: networkController.authToken,
                                                     groupId: String(compGroup.id),
                                                     resourceType: ResourceType.computerGroup,
                                                     server: server)
        }
        
    }) {
        HStack(spacing: 10) {
            Image(systemName: "arrow.clockwise")
            Text("Add Selection To Group")
        }
    }
    .buttonStyle(.borderedProminent)
    .tint(.blue)
          
            HStack(spacing: 10) {
                TextField("Filter", text: $computerGroupFilter)
                Picker(selection: $selectionCompGroup, label: Text("Group:").bold()) {
                    // Provide an explicit nil tag so the optional selection has a matching tag
                    Text("Select...").tag(nil as ComputerGroup?)
                    ForEach(networkController.allComputerGroups.filter({ computerGroupFilter.isEmpty ? true : $0.name.contains(computerGroupFilter) }), id: \.self) { group in
                        Text(group.name)
                            .tag(group as ComputerGroup?)
                    }
                }
                .onAppear {
                    if let first = networkController.allComputerGroups.first {
                        selectionCompGroup = first
                    } else {
                        selectionCompGroup = nil
                    }
                }
            }
               
            }
            .padding()
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Update Extension Attribute")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    VStack(alignment: .leading) {
                        TextField("Filter Extension Attributes", text: $eaFilterText)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 300)
                    }
                    
                    Text("Extension Attribute:")
                    Picker("", selection: $selectedEAName) {
                        // Provide an explicit empty-string tag so the selection's initial empty string matches
                        Text("Select...").tag("")
                        ForEach(filteredEAs, id: \.self) { ea in
                            Text(ea.name).tag(ea.name)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                HStack {
                    Text("Value:")
                    TextField("EA Value", text: $eaValue)
                        .textFieldStyle(.roundedBorder)
                }
                
                
                Button(action: {
                    progress.showProgress()
                    progress.waitForABit()
                    Task {
                        do {
                            try await extensionAttributeController.updateComputerEAValueMultipleComputers(
                                server: server,
                                authToken: networkController.authToken,
                                computerIds: selection,
                                extAttName: selectedEAName,
                                updateValue: eaValue
                            )
                        } catch {
                            print("Failed to update EA: \(error)")
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Update EA Value for \(selection.count) computers")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(selectedEAName.isEmpty || selection.isEmpty)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
                       
//        #if os(macOS)
         
            Divider()
            
            //              ##########################################################################
            //              Progress view
            //              ##########################################################################
            
            
            if progress.showProgressView == true {
                
                ProgressView {
                    
                    Text("Processing")
                        .padding()
                }
                
            } else {
                
                Text("")
                
            }
                }
            
        .onAppear {
            
            
              Task {
                  try await networkController.getAllDepartments()
                  try await networkController.getComputersBasic(server: server, authToken: networkController.authToken)
                  try await extensionAttributeController.getComputerExtAttributes(server: server, authToken: networkController.authToken)
                  
                    }
        
            if networkController.allComputerGroups.count <= 1 {
                 Task {
                     try await networkController.getAllGroups(server: server, authToken: networkController.authToken)
                 }
             }
            // Ensure selectionDepartmentId is set to a sensible default when departments are loaded
            if selectionDepartmentId.isEmpty, let firstDept = networkController.departments.first {
                selectionDepartmentId = firstDept.id
            }
         
         }
    }

    // Helper to resolve the selected department's name
    var selectedDepartmentName: String {
        networkController.departments.first(where: { $0.id == selectionDepartmentId })?.name ?? ""
    }

    var searchResults: [ComputerBasicRecord] {
        let allComputers = networkController.allComputersBasic.computers
        let allComputersArray = Array(allComputers)
        let filtered: [ComputerBasicRecord]
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            filtered = allComputersArray
        } else {
            let query = trimmed.lowercased()
            filtered = allComputersArray.filter { record in
                // Convert fields to strings safely and compare lowercase
                let id = String(describing: record.id).lowercased()
                let name = String(describing: record.name).lowercased()
                let user = String(describing: record.username).lowercased()
                let dept = String(describing: record.department).lowercased()
                let bld = String(describing: record.building).lowercased()
                let model = String(describing: record.model).lowercased()
                let serial = String(describing: record.serialNumber).lowercased()
                let checkin = String(describing: record.reportDateUTC).lowercased()

                return id.contains(query)
                    || name.contains(query)
                    || user.contains(query)
                    || dept.contains(query)
                    || bld.contains(query)
                    || model.contains(query)
                    || serial.contains(query)
                    || checkin.contains(query)
            }
        }
        return filtered.sorted(using: sortOrder)
    }
        
    
    var filteredDepartments: [Department] {
        if departmentFilterText.isEmpty {
            return networkController.departments
        } else {
            return networkController.departments.filter { $0.name.lowercased().contains(departmentFilterText.lowercased()) }
        }
    }
    
    var filteredEAs: [ComputerExtensionAttribute] {
        if eaFilterText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return extensionAttributeController.allComputerExtensionAttributesDict.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        } else {
            let eaQuery = eaFilterText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return extensionAttributeController.allComputerExtensionAttributesDict
                .filter { $0.name.lowercased().contains(eaQuery) }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }
}


//var body: some View {
//    Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
//}
//
//}

//#Preview {
//    ComputersBasicTableView()
//}
