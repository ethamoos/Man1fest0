//
//  PrestagesEditView.swift
//  Man1fest0
//  
//  Created by Amos Deane on 29/01/2024.
//

import SwiftUI



//    #################################################################################
//      PrestageEditView
//    #################################################################################



struct PrestagesEditView: View {
    
    //      Allows the username to edit a device's prestage assigned
    
    @EnvironmentObject var prestageController: PrestageBrain
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var layout: Layout

    // Allows dismissing / navigating back
    @Environment(\.dismiss) private var dismiss

    
    @State var initialPrestageID: String
    
    @State var currentPrestage: PreStage = PreStage(keepExistingSiteMembership: false, enrollmentSiteId: "", id: "", displayName: "")
    
    @State var currentPrestageName = ""

    @State var targetPrestageID: String
    
    @State var serial: String
    
    @State var confirmedSerial: String = ""
    
    @State var serialTextfield: String = ""
    
    @State var server: String
    
    @State var showProgressScreen: Bool
    
    @State var searchText = ""
    
    @State private var showingWarning = false
    
    @State var computerAssignedPreStage: ComputerPreStageScopeAssignment = ComputerPreStageScopeAssignment(serialNumber: "", assignmentDate: "", userAssigned: "")
    
    @State var computerAssignedPreStage2: Any = [""]
    
    //    #################################################################################
    //    Selections
    //    #################################################################################
    
    @State var selectedPrestageInitial: PreStage = PreStage(keepExistingSiteMembership: (0 != 0), enrollmentSiteId: "", id: "", displayName: "")
    
    @State var selectedPrestageTarget: PreStage = PreStage(keepExistingSiteMembership: (0 != 0), enrollmentSiteId: "", id: "", displayName: "")
    
    @State var computerSelection: String = ""
    
    //    #################################################################################
    //    Picker filters / selections
    //    #################################################################################
    
    /// Serial selected in the "Add Unassigned Device" section
    @State private var unassignedSerial: String = ""
    
    /// Filter text for the "Add Unassigned Device" serial picker (matches serial or computer name)
    @State private var unassignedFilter: String = ""
    
    /// Only show computers that are not currently assigned to any prestage
    @State private var showOnlyUnassigned: Bool = false
    
    /// Filter text for the current prestage pickers (matches serial, prestage ID or prestage name)
    @State private var assignmentFilter: String = ""
    
    /// Target prestage for the "Add Unassigned Device" section.
    /// Kept separate from `selectedPrestageTarget` (used by "Update Assigned Prestage") so the two pickers move independently.
    @State private var addTargetPrestage: PreStage = PreStage(keepExistingSiteMembership: false, enrollmentSiteId: "", id: "", displayName: "")
    
    //    Unassign Device section - independent selection
    
    /// Serial selected for removal in the "Unassign Device" section
    @State private var removeSerial: String = ""
    
    /// Filter text for the "Unassign Device" picker (matches serial, prestage ID or prestage name)
    @State private var removeFilter: String = ""
    
    /// Shows the confirmation alert before removing a device from its prestage
    @State private var showingRemoveConfirmation = false
    
    var body: some View {
        
        
        let serialsPrestageName = Array (prestageController.serialPrestageAssignment.keys)
        
        VStack(alignment: .leading) {
            
            VStack{
                Button(action: { dismiss() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .buttonStyle(.bordered)
            } .padding()
            
                VStack(alignment: .leading, spacing: 12) {
                    // Back button + header
                    HStack(alignment: .center) {
                      

                        VStack(alignment: .leading) {
                            Text("Update Assigned Prestage").font(.title2).fontWeight(.semibold)
                            Text("Move or remove a device from a prestage").font(.subheadline).foregroundColor(.secondary)
                        }
                        Spacer()
                    }

                    // Group: Serial and current prestage
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            // Width capped so the field doesn't expand across the whole row
                            TextField("Filter by serial, prestage name or ID", text: $assignmentFilter)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(minWidth: 180, maxWidth: 280)
                            if !assignmentFilter.isEmpty {
                                Button(action: { assignmentFilter = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                }
                                .buttonStyle(.borderless)
                            }
                            Text("\(filteredAssignments.count) of \(assignmentEntries.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            // Absorbs spare width so controls stay grouped on the left
                            Spacer()
                        }

                        HStack {
                            Label("Serial", systemImage: "barcode.viewfinder")
                            Picker(selection: assignedSerialBinding, label: EmptyView()) {
                                Text("").tag("")
                                ForEach(assignedSerialOptions, id: \.self) { item in
                                    Text(item).tag(item)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: 320) // Cap picker width
                            Spacer()
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Current Prestage Name:").fontWeight(.bold)
                                Picker(selection: currentPrestageNameBinding, label: EmptyView()) {
                                    Text("").tag("")
                                    ForEach(assignedPrestageNameOptions, id: \.self) { item in
                                        Text(item).tag(item)
                                    }
                                }
                                .pickerStyle(.menu)
                            }

                            VStack(alignment: .leading) {
                                Text("Current Prestage ID:").fontWeight(.bold)
                                Picker(selection: currentPrestageIDBinding, label: EmptyView()) {
                                    Text("").tag("")
                                    ForEach(assignedPrestageIDOptions, id: \.self) { item in
                                        Text(item).tag(item)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.windowBackgroundColor)).shadow(radius: 1))

                    // Target picker
                    VStack(alignment: .leading) {
                        Text("Target Prestage:").fontWeight(.bold)
                        Picker(selection: $selectedPrestageTarget, label: Text("Target Prestage:")) {
                            Text("").tag(PreStage(keepExistingSiteMembership: false, enrollmentSiteId: "", id: "", displayName: ""))
                            ForEach(prestageController.allPrestages, id: \.self) { prestage in
                                Text("\(prestage.displayName) (ID: \(prestage.id))")
                                    .tag(prestage)
                            }
                        }
                        .pickerStyle(.menu)
                        .onAppear {
                            if prestageController.allPrestages.isEmpty != true {
                                print("Setting allPrestages picker default")
                                print("currentPrestageID is set as:\(self.initialPrestageID)")
                            }
                        }

                    // Update button
                    HStack {
//                        Spacer()
                        Button(action: {
                            // use selectedPrestageTarget.id safely
                            let targetID = selectedPrestageTarget.id
                            updatePrestage(initialPrestageID: initialPrestageID, authToken: networkController.authToken)
                            progress.showProgress()
                            progress.waitForABit()
                            print("Selecting prestage:\($selectedPrestageInitial)")
                            print("Printing serialPrestageAssignment :\(prestageController.serialPrestageAssignment)")
                            print("Printing serialsPrestageName :\(serialsPrestageName)")
                        }) {
                            Text("Update")
                                .frame(minWidth: 100)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    }
                    }
                    .padding(.vertical)

                    if progress.showProgressView == true {
                        ProgressView {
                            Text("Loading")
                                .font(.title)
                                .progressViewStyle(.horizontal)
                        }
                        .padding()
                    }
                }
                .padding()

                Divider()

                // Add Unassigned Device - split into its own property to keep body type-checking fast
                addUnassignedDeviceSection

                Divider()

                // Unassign Device - split into its own property to keep body type-checking fast
                unassignDeviceSection

            Spacer()
        }
        .padding(.top)
        .padding(.bottom)
        .onAppear() {
            getCurrentPrestageName(initialPrestageID: initialPrestageID)
            getCurrentPrestage(targetPrestageID: initialPrestageID, authToken: networkController.authToken)
            currentPrestageName = self.currentPrestage.displayName
            if !serial.isEmpty {
                selectAssignedSerial(serial)
            } else if !initialPrestageID.isEmpty {
                selectPrestageID(initialPrestageID)
            }
            // Load the basic computer list (with serial numbers) if needed for the unassigned picker
            if networkController.allComputersBasic.computers.isEmpty && !networkController.authToken.isEmpty {
                Task {
                    try? await networkController.getComputersBasic(server: server, authToken: networkController.authToken)
                }
            }
        }
        .onChange(of: prestageController.serialPrestageAssignment) { _ in
            // Re-synchronise once assignments are (re)loaded
            if !serial.isEmpty { selectAssignedSerial(serial) }
        }
        .onChange(of: prestageController.allPrestages) { _ in
            currentPrestageName = prestageName(for: initialPrestageID)
        }
        .onDisappear() {
            // Ensure global editor state is cleared when the view is dismissed
            prestageController.isPrestageEditorActive = false
            prestageController.activePrestageEditorSerial = nil
            prestageController.activePrestageEditorInitialID = nil
        }
    }
    
    var searchResults: [String] {
        
        //        let serialPrestageAssignment = prestageController.serialPrestageAssignment
        let serialsArray = Array (prestageController.serialPrestageAssignment.keys)
        
        if searchText.isEmpty {
            return serialsArray
        } else {
            return serialsArray.filter { $0.contains(searchText) }
        }
    }
    
    func getCurrentPrestageName(initialPrestageID: String) {
        
        print("Running: getCurrentPrestageName")
        for eachPrestage in prestageController.allPrestages {
            
            print("Prestage is:\(eachPrestage.id)")
            
            if eachPrestage.id == initialPrestageID {
                print("We have a match")
                self.currentPrestage = eachPrestage
            }
        }
    }
    
    func updatePrestage(initialPrestageID: String, authToken: String) {
        prestageController.separationLine()
        
        Task {
            try await prestageController.getPrestageCurrentScope(jamfURL: prestageController.server, prestageID: initialPrestageID, authToken: authToken)
            
            try await prestageController.removeDeviceFromPrestage(server: prestageController.server, removeComputerPrestageID: initialPrestageID, serial: serial, authToken: authToken, depVersionLock: prestageController.depVersionLock)
            
            try await prestageController.getPrestageCurrentScope(jamfURL: prestageController.server, prestageID: initialPrestageID, authToken: authToken)
        }
    }
    
    func getCurrentPrestage(targetPrestageID: String, authToken: String) {
        prestageController.separationLine()
        print("Running: showPrestage")
        
        Task {
            try await prestageController.getPrestageCurrentScope(jamfURL: prestageController.server, prestageID: targetPrestageID, authToken: authToken)
        }
    }
    
    
    func showPrestage(targetPrestageID: String, serial: String, authToken: String) {
        prestageController.separationLine()
        print("Running: showPrestage")
        
        Task {
            try await prestageController.getPrestageCurrentScope(jamfURL: prestageController.server, prestageID: targetPrestageID, authToken: authToken)
            
            print("Running: adding to prestage - main")
            try await prestageController.addDeviceToPrestage(server: prestageController.server, prestageID: targetPrestageID, serial: serial, authToken: authToken, depVersionLock: prestageController.depVersionLock)
        }
    }
    
    //    #################################################################################
    //    Current prestage pickers - synchronised selection
    //    #################################################################################
    
    struct AssignmentEntry: Hashable {
        let serial: String
        let prestageID: String
        let prestageName: String
    }
    
    /// All serial -> prestage assignments, with the prestage name resolved
    var assignmentEntries: [AssignmentEntry] {
        prestageController.serialPrestageAssignment
            .map { AssignmentEntry(serial: $0.key, prestageID: $0.value, prestageName: prestageName(for: $0.value)) }
            .sorted { $0.serial.localizedStandardCompare($1.serial) == .orderedAscending }
    }
    
    /// Assignments matching the filter text (serial, prestage ID or name)
    var filteredAssignments: [AssignmentEntry] {
        let filter = assignmentFilter.trimmingCharacters(in: .whitespaces)
        guard !filter.isEmpty else { return assignmentEntries }
        return assignmentEntries.filter {
            $0.serial.localizedCaseInsensitiveContains(filter) ||
            $0.prestageID.localizedCaseInsensitiveContains(filter) ||
            $0.prestageName.localizedCaseInsensitiveContains(filter)
        }
    }
    
    var assignedSerialOptions: [String] {
        withCurrent(serial, in: filteredAssignments.map(\.serial))
    }
    
    var assignedPrestageIDOptions: [String] {
        let ids = uniqueOrdered(filteredAssignments.map(\.prestageID))
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        return withCurrent(initialPrestageID, in: ids)
    }
    
    var assignedPrestageNameOptions: [String] {
        let names = uniqueOrdered(filteredAssignments.map(\.prestageName).filter { !$0.isEmpty })
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        return withCurrent(currentPrestageName, in: names)
    }
    
    var assignedSerialBinding: Binding<String> {
        Binding(get: { serial }, set: { selectAssignedSerial($0) })
    }
    
    var currentPrestageIDBinding: Binding<String> {
        Binding(get: { initialPrestageID }, set: { selectPrestageID($0) })
    }
    
    var currentPrestageNameBinding: Binding<String> {
        Binding(get: { currentPrestageName }, set: { selectPrestageName($0) })
    }
    
    /// Selecting a serial updates the prestage ID and name
    func selectAssignedSerial(_ newSerial: String) {
        serial = newSerial
        guard !newSerial.isEmpty else { return }
        if let id = prestageController.serialPrestageAssignment[newSerial] {
            initialPrestageID = id
            currentPrestageName = prestageName(for: id)
            getCurrentPrestageName(initialPrestageID: id)
        }
    }
    
    /// Selecting a prestage ID updates the name and, if needed, the serial
    func selectPrestageID(_ newID: String) {
        initialPrestageID = newID
        currentPrestageName = prestageName(for: newID)
        getCurrentPrestageName(initialPrestageID: newID)
        guard !newID.isEmpty else { return }
        // Keep the serial if it already belongs to this prestage, otherwise pick the first matching serial
        if prestageController.serialPrestageAssignment[serial] != newID {
            serial = (filteredAssignments.first { $0.prestageID == newID }
                      ?? assignmentEntries.first { $0.prestageID == newID })?.serial ?? ""
        }
    }
    
    /// Selecting a prestage name updates the ID and, if needed, the serial
    func selectPrestageName(_ newName: String) {
        currentPrestageName = newName
        guard !newName.isEmpty else { return }
        if let id = (filteredAssignments.first { $0.prestageName == newName }
                     ?? assignmentEntries.first { $0.prestageName == newName })?.prestageID
            ?? prestageController.allPrestages.first(where: { $0.displayName == newName })?.id {
            selectPrestageID(id)
        }
    }
    
    func prestageName(for id: String) -> String {
        prestageController.allPrestages.first(where: { $0.id == id })?.displayName ?? ""
    }
    
    private func uniqueOrdered(_ items: [String]) -> [String] {
        var seen = Set<String>()
        return items.filter { seen.insert($0).inserted }
    }
    
    /// Ensures the current selection is always present in a picker's options (avoids invalid picker tags when filtering)
    private func withCurrent(_ current: String, in options: [String]) -> [String] {
        guard !current.isEmpty, !options.contains(current) else { return options }
        return [current] + options
    }
    
    //    #################################################################################
    //    Unassigned device picker
    //    #################################################################################
    
    /// "Add Unassigned Device" section - separate from body to avoid type-checker timeouts
    var addUnassignedDeviceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Unassigned Device").font(.title2).fontWeight(.semibold)
            Text("Add a device not assigned to a pre-stage").font(.subheadline).foregroundColor(.secondary)
            
            unassignedFilterRow
            unassignedSerialPickerRow
            
            HStack {
                Text("Target Prestage:")
                // Uses its own selection (addTargetPrestage) - independent of the Update section's picker
                Picker(selection: $addTargetPrestage, label: EmptyView()) {
                    Text("").tag(PreStage(keepExistingSiteMembership: false, enrollmentSiteId: "", id: "", displayName: ""))
                    ForEach(prestageController.allPrestages, id: \.self) { prestage in
                        Text("\(prestage.displayName) (ID: \(prestage.id))").tag(prestage)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 360)
                Spacer()
            }
            
            Button(action: {
                progress.showProgress()
                progress.waitForABit()
                showPrestage(targetPrestageID: addTargetPrestage.id, serial: unassignedSerial, authToken: networkController.authToken)
            }) {
                Text("Add")
            }
            .disabled(unassignedSerial.isEmpty || addTargetPrestage.id.isEmpty)
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.windowBackgroundColor)).shadow(radius: 1))
    }
    
    /// Filter row for the unassigned serial picker
    var unassignedFilterRow: some View {
        HStack {
            Image(systemName: "line.3.horizontal.decrease.circle")
            // Width capped so the "Unassigned only" toggle sits next to the field
            TextField("Filter by serial or computer name", text: $unassignedFilter)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(minWidth: 180, maxWidth: 280)
            if !unassignedFilter.isEmpty {
                Button(action: { unassignedFilter = "" }) {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.borderless)
            }
            Toggle("Unassigned only", isOn: $showOnlyUnassigned)
                .toggleStyle(.checkbox)
            Text("\(filteredUnassignedComputers.count) of \(networkController.allComputersBasic.computers.count)")
                .font(.caption)
                .foregroundColor(.secondary)
            // Absorbs spare width so controls stay grouped on the left
            Spacer()
        }
    }
    
    /// Serial picker for the unassigned device
    var unassignedSerialPickerRow: some View {
        HStack {
            Label("Serial", systemImage: "barcode.viewfinder")
            Picker(selection: $unassignedSerial, label: EmptyView()) {
                Text("").tag("")
                // Keep the current selection available even if it is filtered out
                if !unassignedSerial.isEmpty && !filteredUnassignedComputers.contains(where: { $0.serialNumber == unassignedSerial }) {
                    Text(unassignedSerial).tag(unassignedSerial)
                }
                ForEach(filteredUnassignedComputers, id: \.id) { computer in
                    Text("\(computer.serialNumber)  (\(computer.name))").tag(computer.serialNumber)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: 360) // Cap picker width
            Spacer()
        }
    }
    
    var filteredUnassignedComputers: [ComputerBasicRecord] {
        let filter = unassignedFilter.trimmingCharacters(in: .whitespaces)
        return networkController.allComputersBasic.computers
            .filter { !$0.serialNumber.isEmpty }
            .filter { !showOnlyUnassigned || prestageController.serialPrestageAssignment[$0.serialNumber] == nil }
            .filter { filter.isEmpty || $0.serialNumber.localizedCaseInsensitiveContains(filter) || $0.name.localizedCaseInsensitiveContains(filter) }
            .sorted { $0.serialNumber.localizedStandardCompare($1.serialNumber) == .orderedAscending }
    }
    
    //    #################################################################################
    //    Unassign device - dedicated selection and removal
    //    #################################################################################
    
    /// Assignments matching the Unassign Device filter (serial, prestage ID or name)
    var filteredRemoveEntries: [AssignmentEntry] {
        let filter = removeFilter.trimmingCharacters(in: .whitespaces)
        guard !filter.isEmpty else { return assignmentEntries }
        return assignmentEntries.filter {
            $0.serial.localizedCaseInsensitiveContains(filter) ||
            $0.prestageID.localizedCaseInsensitiveContains(filter) ||
            $0.prestageName.localizedCaseInsensitiveContains(filter)
        }
    }
    
    /// Prestage the selected removal device is currently assigned to
    var removePrestageID: String {
        prestageController.serialPrestageAssignment[removeSerial] ?? ""
    }
    
    /// "Unassign Device" section - separate from body to avoid type-checker timeouts
    @ViewBuilder
    var unassignDeviceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Unassign Device").font(.title2).fontWeight(.semibold)
            Text("Remove a device from the prestage it is currently assigned to").font(.subheadline).foregroundColor(.secondary)
            
            if prestageController.allPsScComplete == true && prestageController.serialPrestageAssignment.count > 0 {
                removeFilterRow
                removeDevicePickerRow
                
                if !removeSerial.isEmpty {
                    Text("Will be removed from: \(prestageName(for: removePrestageID)) (ID: \(removePrestageID))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button(action: {
                    showingRemoveConfirmation = true
                }) {
                    Text("Remove")
                }
                .disabled(removeSerial.isEmpty || removePrestageID.isEmpty)
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .alert(isPresented: $showingRemoveConfirmation) {
                    Alert(
                        title: Text("Remove Device?"),
                        message: Text("Remove \(removeSerial) from prestage \(prestageName(for: removePrestageID)) (ID: \(removePrestageID))?"),
                        primaryButton: .destructive(Text("Remove")) {
                            removeDevice(serial: removeSerial, prestageID: removePrestageID, authToken: networkController.authToken)
                        },
                        secondaryButton: .cancel()
                    )
                }
            } else if prestageController.allPsScComplete == false {
                ProgressView {
                    Text("Loading")
                        .progressViewStyle(.horizontal)
                }
            } else {
                Text("No Devices Assigned To A Prestage")
            }
        }
        .padding()
    }
    
    /// Filter row for the removal picker (independent of the other sections)
    var removeFilterRow: some View {
        HStack {
            Image(systemName: "line.3.horizontal.decrease.circle")
            TextField("Filter by serial, prestage name or ID", text: $removeFilter)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(minWidth: 180, maxWidth: 280)
            if !removeFilter.isEmpty {
                Button(action: { removeFilter = "" }) {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.borderless)
            }
            Text("\(filteredRemoveEntries.count) of \(assignmentEntries.count)")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
    
    /// Device picker - selecting a serial determines the prestage ID to remove it from
    var removeDevicePickerRow: some View {
        HStack {
            Label("Device", systemImage: "barcode.viewfinder")
            Picker(selection: $removeSerial, label: EmptyView()) {
                Text("").tag("")
                // Keep the current selection available even if it is filtered out
                if !removeSerial.isEmpty && !filteredRemoveEntries.contains(where: { $0.serial == removeSerial }) {
                    Text(removeSerial).tag(removeSerial)
                }
                ForEach(filteredRemoveEntries, id: \.serial) { entry in
                    Text(removeEntryLabel(entry)).tag(entry.serial)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: 420)
            Spacer()
        }
    }
    
    func removeEntryLabel(_ entry: AssignmentEntry) -> String {
        let name = entry.prestageName.isEmpty ? "Unknown" : entry.prestageName
        return "\(entry.serial)  –  \(name) (ID: \(entry.prestageID))"
    }
    
    /// Removes a single device from its prestage, then refreshes the assignment list.
    /// Replaces the previous use of updatePrestage(...) for removal.
    func removeDevice(serial: String, prestageID: String, authToken: String) {
        guard !serial.isEmpty, !prestageID.isEmpty else { return }
        prestageController.separationLine()
        print("Running: removeDevice - serial:\(serial) prestageID:\(prestageID)")
        progress.showProgress()
        
        Task {
            do {
                // Fetch current scope first so depVersionLock is up to date
                try await prestageController.getPrestageCurrentScope(jamfURL: prestageController.server, prestageID: prestageID, authToken: authToken)
                
                try await prestageController.removeDeviceFromPrestage(server: prestageController.server, removeComputerPrestageID: prestageID, serial: serial, authToken: authToken, depVersionLock: prestageController.depVersionLock)
                
                // Refresh the serial -> prestage map so pickers reflect the removal
                try await prestageController.getAllDevicesPrestageScope(server: server, prestageID: prestageID, authToken: authToken)
                
                await MainActor.run {
                    removeSerial = ""
                    progress.endProgress()
                }
            } catch {
                print("removeDevice failed: \(error)")
                await MainActor.run { progress.endProgress() }
            }
        }
    }
    
    func updatePrestage(initialPrestageID: String, targetPrestageID: String) {
        
        if computerSelection != "" {
            confirmedSerial = computerSelection
            print("computerSelection picker has a value - using this")
        } else {
            print("computerSelection has no value - using passed value")
            confirmedSerial = serial
        }
        
        prestageController.separationLine()
        
        Task {
            
            print("Running getPrestageCurrentScope - to remove")
            try await prestageController.getPrestageCurrentScope(jamfURL: prestageController.server, prestageID: initialPrestageID, authToken: networkController.authToken)
            
            print("Removing device from current prestage")
            try await prestageController.removeDeviceFromPrestage(server: prestageController.server, removeComputerPrestageID: initialPrestageID, serial: confirmedSerial, authToken: networkController.authToken, depVersionLock: prestageController.depVersionLock)
            
            print("Running getPrestageCurrentScope for target prestage - to add")
            try await prestageController.getPrestageCurrentScope(jamfURL: prestageController.server, prestageID: targetPrestageID, authToken: networkController.authToken)
            
            print("Running: adding to prestage - main")
            try await prestageController.addDeviceToPrestage(server: prestageController.server, prestageID: targetPrestageID, serial: confirmedSerial, authToken: networkController.authToken, depVersionLock: prestageController.depVersionLock)
            
            print("Finished")
            try await prestageController.getAllDevicesPrestageScope(server: server, prestageID: targetPrestageID, authToken: networkController.authToken)
            
            showProgressScreen = false
        }
    }
}



//}
//struct PrestageEditView_Previews: PreviewProvider {
//    static var previews: some View {
// //    }
//}
//    }
//}
//    }
//}