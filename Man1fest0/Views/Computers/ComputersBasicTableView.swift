//
//  ComputersBasicTableView.swift
//
//  Created by Amos Deane on 28/08/2024.
//

import SwiftUI
import UniformTypeIdentifiers

struct ComputersBasicTableView: View {
    
    @State var server: String

    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var layout: Layout
    @EnvironmentObject var pushController: PushBrain
    @EnvironmentObject var xmlController: XmlBrain
    @EnvironmentObject var extensionAttributeController: EaBrain

    // CSV import state
    @State private var selectedCSVURL: URL? = nil
    @State private var showingFileImporter: Bool = false
    @State private var csvComputerIdentifiers: [String] = [] // raw tokens (could be names, serials, jamfIds, macs)
    @State private var csvLoadError: String? = nil

    // Parsed CSV rows and header/column mapping
    @State private var csvRawRows: [[String]] = [] // all parsed rows including header (if present)
    @State private var csvHeaders: [String] = []
    @State private var csvRows: [[String]] = [] // rows excluding header when csvHasHeader == true
    @State private var csvHasHeader: Bool = true
    @State private var csvSelectedColumnIndex: Int = 0
    @State private var csvRowIncluded: [Bool] = [] // inclusion flags for preview rows
    @State private var csvAvailableColumnCount: Int = 1

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
                                // Run async deletes and refresh once complete
                                Task {
                                    await networkController.processDeleteComputersBasicAsync(selection: selection, server: server, authToken: networkController.authToken, resourceType: ResourceType.computer)
                                }
                                print("Yes tapped - started async delete")
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
                    
                    // Open selected computers in the Jamf web UI
                    Button(action: {
                        guard !selection.isEmpty else { return }
                        progress.showProgress()
                        progress.waitForABit()
                        
                        // Iterate selections and open each computer in the browser
                        for id in selection {
                            let idString = String(describing: id)
                            layout.openURL(urlString: "\(server)/computers.html?id=\(idString)&o=r", requestType: "computers")
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "safari")
                            Text("Open Selection In Browser")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(selection.isEmpty)
                }
                    
                DisclosureGroup("Import CSV") {
                        
                        
                        
                        // CSV Import buttons
                        Button(action: {
                            showingFileImporter = true
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "tray.and.arrow.down")
                                Text("Import CSV")
                            }
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            applyCSVSelection()
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.circle")
                                Text("Select Imported")
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(csvComputerIdentifiers.isEmpty)
                        
                        // Attach the fileImporter to this HStack
                        .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [UTType.commaSeparatedText, UTType.plainText], allowsMultipleSelection: false) { result in
                            switch result {
                            case .success(let urls):
                                if let url = urls.first {
                                    selectedCSVURL = url
                                    do {
                                        try loadCSVFromSelectedURL()
                                        csvLoadError = nil
                                    } catch {
                                        csvLoadError = error.localizedDescription
                                    }
                                }
                            case .failure(let err):
                                csvLoadError = err.localizedDescription
                            }
                        }
                        
                        // Show small status for CSV import
                        if !csvComputerIdentifiers.isEmpty {
                            Text("Imported tokens: \(csvComputerIdentifiers.count) items")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        if let err = csvLoadError {
                            Text(err).foregroundColor(.red).font(.footnote)
                        }
                        
                        // CSV column mapping & preview
                        VStack(alignment: .leading, spacing: 6) {
                            if !csvRawRows.isEmpty {
                                HStack {
                                    Toggle("Has header row", isOn: $csvHasHeader)
                                        .onChange(of: csvHasHeader) { _ in
                                            interpretRawRows()
                                        }
                                    Spacer()
                                    Text("Rows: \(csvRows.count)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                // Column picker (use headers if available)
                                HStack {
                                    Text("Identifier column:")
                                    Picker("Column", selection: $csvSelectedColumnIndex) {
                                        ForEach(0..<max(1, csvAvailableColumnCount), id: \.self) { idx in
                                            if csvHasHeader && idx < csvHeaders.count {
                                                Text(csvHeaders[idx]).tag(idx)
                                            } else {
                                                Text("Column \(idx)").tag(idx)
                                            }
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    
                                    Button("Generate Tokens") {
                                        generateTokensFromSelectedColumn()
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(csvRows.isEmpty)
                                    
                                    Button("Apply Column to Selection") {
                                        generateTokensFromSelectedColumn()
                                        applyCSVSelection()
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(csvRows.isEmpty)
                                }
                                
                                // Preview list with toggles to include/exclude rows — delegated to a small subview to avoid SwiftUI overload ambiguity
                                CSVPreviewView(csvRows: csvRows, csvRowIncluded: $csvRowIncluded, csvSelectedColumnIndex: csvSelectedColumnIndex)
                                    .frame(maxHeight: 200)
                                
                                // Token preview and manual edit/remove
                                if !csvComputerIdentifiers.isEmpty {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text("Token preview (") + Text("\(csvComputerIdentifiers.count)").font(.caption).foregroundColor(.secondary) + Text(")")
                                            Spacer()
                                            Button("Regenerate Tokens") {
                                                generateTokensFromSelectedColumn()
                                            }
                                            .buttonStyle(.bordered)
                                        }
                                        
                                        ScrollView(.vertical, showsIndicators: true) {
                                            LazyVStack(alignment: .leading, spacing: 6) {
                                                ForEach(csvComputerIdentifiers, id: \.self) { token in
                                                    HStack(spacing: 8) {
                                                        Text(token)
                                                            .font(.caption)
                                                            .lineLimit(1)
                                                            .truncationMode(.middle)
                                                        Spacer()
                                                        Button(action: {
                                                            // remove this token
                                                            csvComputerIdentifiers.removeAll(where: { $0 == token })
                                                        }) {
                                                            Image(systemName: "trash")
                                                        }
                                                        .buttonStyle(.plain)
                                                    }
                                                    .padding(.vertical, 2)
                                                }
                                            }
                                            .padding(.vertical, 4)
                                        }
                                        .frame(maxHeight: 140)
                                    }
                                    .padding(.top, 6)
                                }
                            }
                        }
                        
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
//                }
                //                .padding()
                
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
                
                HStack {
                    
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
                    
                }
                
                
                
                
                
                
                
                
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
                
                HStack {
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
                    
                    HStack(spacing: 1) {
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
                  Spacer()
                }
                .padding()
            }
            
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
    
    // MARK: - CSV Import Functions

    /// Load and parse the CSV file from the selected URL.
    /// Supports files from the system file importer (security-scoped) and
    /// accepts rows with one or more columns. Tokens may be computer name,
    /// serial number, Jamf id, or MAC address.
    private func loadCSVFromSelectedURL() throws {
        guard let url = selectedCSVURL else { return }

        // If the URL is security-scoped (from the fileImporter) we must start accessing it
        var didStart = false
        if url.startAccessingSecurityScopedResource() {
            didStart = true
        }
        defer {
            if didStart {
                url.stopAccessingSecurityScopedResource()
            }
        }

        // Read file contents using Data(contentsOf:) to avoid some platform-specific path issues
        let data = try Data(contentsOf: url)
        guard let content = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "CSV", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to decode CSV as UTF-8 text"])
        }

        // Normalize newlines and split into lines
        let normalized = content.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        let lines = normalized.split(separator: "\n").map { String($0) }

        // Parse each line into columns, keep raw rows for preview and mapping
        var rawRows: [[String]] = []
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.isEmpty { continue }

            var columns: [String] = []
            var current = ""
            var insideQuotes = false
            for ch in trimmedLine {
                if ch == Character("\"") {
                    insideQuotes.toggle()
                    continue
                }
                if ch == Character(",") && !insideQuotes {
                    columns.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
                    current = ""
                } else {
                    current.append(ch)
                }
            }
            columns.append(current.trimmingCharacters(in: .whitespacesAndNewlines))

            rawRows.append(columns)
        }

        if rawRows.isEmpty {
            throw NSError(domain: "CSV", code: 2, userInfo: [NSLocalizedDescriptionKey: "CSV file contains no rows"]) 
        }

        // Store raw rows and interpret headers/rows
        csvRawRows = rawRows
        interpretRawRows()
    }

    /// Apply the imported CSV selection to the current selection set.
    /// Matches tokens against computer name, serial number, jamf id (id), or MAC address.
    private func applyCSVSelection() {
        // Clear the current selection
        selection.removeAll()

        let comps = networkController.allComputersBasic.computers

        for comp in comps {
            let name = comp.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let serial = comp.serialNumber.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let mac = comp.macAddress.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().replacingOccurrences(of: ":", with: "").replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: "")
            let idString = String(comp.id)

            for token in csvComputerIdentifiers {
                let t = token.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if t == name || t == serial || t == mac || t == idString {
                    selection.insert(comp.id)
                    break
                }
            }
        }
    }

    // Interpret `csvRawRows` into `csvHeaders` and `csvRows` based on `csvHasHeader`.
    private func interpretRawRows() {
        guard !csvRawRows.isEmpty else { return }
        if csvHasHeader {
            csvHeaders = csvRawRows.first ?? []
            csvRows = Array(csvRawRows.dropFirst())
        } else {
            csvHeaders = []
            csvRows = csvRawRows
        }

        // Initialize inclusion flags for preview
        csvRowIncluded = Array(repeating: true, count: csvRows.count)
        // Determine available columns from headers or longest row
        let maxColsFromRows = csvRows.map { $0.count }.max() ?? 0
        csvAvailableColumnCount = max(csvHeaders.count, maxColsFromRows, 1)

        // Clamp selected column index to available columns
        if csvSelectedColumnIndex >= csvAvailableColumnCount {
            csvSelectedColumnIndex = 0
        }
    }

    // Generate tokens from the selected column index using inclusion flags.
    private func generateTokensFromSelectedColumn() {
        var tokens = Set<String>()

        for (idx, row) in csvRows.enumerated() {
            if idx < csvRowIncluded.count && !csvRowIncluded[idx] { continue }
            guard csvSelectedColumnIndex < row.count else { continue }
            let cell = row[csvSelectedColumnIndex].trimmingCharacters(in: .whitespacesAndNewlines)
            if cell.isEmpty { continue }

            let lower = cell.lowercased()
            tokens.insert(lower)
            let macNormalized = lower.replacingOccurrences(of: ":", with: "").replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: "")
            tokens.insert(macNormalized)
        }

        csvComputerIdentifiers = Array(tokens)
    }

    // (removed CSVRowItem helper) CSV preview is rendered by a dedicated subview below
}


//var body: some View {
//    Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
//}
//
//}

// Small subview to render CSV preview rows separately to avoid ForEach overloads in parent view
private struct CSVPreviewView: View {
    let csvRows: [[String]]
    @Binding var csvRowIncluded: [Bool]
    let csvSelectedColumnIndex: Int

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(alignment: .leading, spacing: 4) {
                ForEach(0..<csvRows.count, id: \.self) { index in
                    let row = csvRows[index]
                    let display: String = csvSelectedColumnIndex < row.count ? row[csvSelectedColumnIndex] : row.joined(separator: ", ")
                    HStack(alignment: .top, spacing: 8) {
                        if index < csvRowIncluded.count {
                            Toggle(isOn: Binding(get: {
                                csvRowIncluded[index]
                            }, set: { newVal in
                                csvRowIncluded[index] = newVal
                            })) {
                                Text(display)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .font(.caption)
                            }
                        }
                        Spacer()
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

//#Preview {
//    ComputersBasicTableView()
//}
