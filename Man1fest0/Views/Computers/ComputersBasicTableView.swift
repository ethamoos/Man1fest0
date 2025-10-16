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
    
    var selectedResourceType = ResourceType.computerBasic
    
    @State private var showingWarning = false
    @State private var searchText = ""
    @State private var departmentFilterText = ""
    
    @State var selection = Set<ComputerBasicRecord.ID>()
    @State var selectionComp = Set<Computer>()
    @State  var selectionCategory: Category = Category(jamfId: 0, name: "")
    @State  var selectionDepartment: Department = Department(jamfId: 0, name: "")
    @State private var selectedDevice = ""
    @State private var selectedCommand = ""
    
    @State private var sortOrder = [KeyPathComparator(\ComputerBasicRecord.id)]
    @State private var newComputerName = ""
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            if networkController.allComputersBasic.computers.count > 0 {
                
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
                .toolbar {
                    
                    Button(action: {
                        handleConnect(resourceType: ResourceType.computerBasic)
                        progress.showProgress()
                        progress.waitForABit()
                        print("Refresh")
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh")
                        }
                    }
                }
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
                        handleConnect(resourceType: ResourceType.computerBasic)
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
                        TextField("Filter Departments", text: $departmentFilterText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Picker(selection: $selectionDepartment, label: Text("Department:").bold()) {
                            Text("").tag(Department(jamfId: 0, name: ""))
                            ForEach(filteredDepartments, id: \.self) { department in
                                Text(String(describing: department.name)).tag(department)
                            }
                        }
                    }
                    Button(action: {
                            
                            //  ##########################################################################
                            //  processUpdateComputerDepartment
                            //  ##########################################################################
                            
                            networkController.processUpdateComputerDepartmentBasic(selection: selection, server: server, authToken: networkController.authToken, resourceType: selectedResourceType, department: selectionDepartment.name)
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
                    
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 250)), GridItem(.flexible())]) {
//                    LazyVGrid(columns: layout.columnsFlex, spacing: 20) {
                    
//                    LazyVGrid(columns: layout.columnsFlex) {
                        Picker("Commands", selection: $selectedCommand) {
                            ForEach(pushController.flushCommands, id: \.self) {
                                Text(String(describing: $0))
                            }
                        }
                    }
//                }
                            
                Button("Flush Commands") {
                    
                    progress.showProgress()
                    progress.waitForABit()
                    
                    Task {
                        try await pushController.flushCommandBatch( server: server, authToken: networkController.authToken, selectionComp: selection, selectedCommand: selectedCommand, deviceType: "computers")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .shadow(color: .gray, radius: 2, x: 0, y: 2)
                //                        }
//            }
//                }
            }
            .padding()
            
            
            //              ##########################################################################
            //              Selections
            //              ##########################################################################
            
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
            
            //                Task {
            //                    try await networkController.getToken(server: server)
            //                }
            networkController.connect(server: server,resourceType: ResourceType.department, authToken: networkController.authToken)
            handleConnect(resourceType: ResourceType.computerBasic)
//                }
        }
    }
    
    var searchResults: [ComputerBasicRecord] {
        let allComputers = networkController.allComputersBasic.computers
        let allComputersArray = Array(allComputers)
        let filtered: [ComputerBasicRecord]
        if searchText.isEmpty {
            filtered = allComputersArray
        } else {
            filtered = allComputersArray.filter { $0.name.lowercased().contains(searchText.lowercased()) }
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
    
    //}
    
    //        .frame(minWidth: 200, minHeight: 100, alignment: .leading)
    
    //}
    
    func handleConnect(resourceType: ResourceType) {
        print("Running handleConnect. resourceType is set as:\(resourceType)")
        
        Task {
            
            do {
                try await networkController.getComputersBasic(server: server, authToken: networkController.authToken)
            } catch {
                print("Error fetching basic computers")
                print(error)
            }
        }
        
    }
}



//var body: some View {
//    Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
//}
//}

//#Preview {
//    ComputersBasicTableView()
//}
