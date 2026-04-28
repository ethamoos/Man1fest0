import SwiftUI

struct ComputersDetailedView: View {
    // Accept server and computerID as regular inputs so parent changes propagate
    let server: String
    let computerID: String
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var layout: Layout
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var pushController: PushBrain
    @EnvironmentObject var extensionAttributeController: EaBrain
    @EnvironmentObject var prestageController: PrestageBrain

    // Local UI state for buttons copied from ComputersBasicDetailedView
    @State private var selectedCommand = ""
    @State private var selectedEAName = ""
    @State private var eaValue = ""
    @State private var computerName = ""

    // Use the published full decoded ComputerFull from NetBrain directly
    @State private var isLoading: Bool = true
    @State private var lastUpdated: Date? = nil
    @State private var showDeleteAlert: Bool = false
    @State private var isDeleting: Bool = false
    @State private var editUsername: String = ""
    @State private var showUpdateUsernameConfirm: Bool = false
    @State private var isUpdatingUsername: Bool = false

    var body: some View {
        Group {
            if isLoading && networkController.computerDetailedFull == nil && networkController.computerDetailed == nil {
                ProgressView("Loading computer...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else if let detail = networkController.computerDetailedFull {
                // Preferred detailed model
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        

                        let general = detail.general
                        let hardware = detail.hardware
                        let security = detail.security

                        Text("Name: \(general?.name ?? "")")
                        Text("ID: \(general?.id ?? "")")
                        Text("UDID: \(general?.udid ?? "")")
                        Text("Serial: \(general?.serial_number ?? "")")
                        Text("Model: \(general?.model ?? "")")
                        Text("Username: \(general?.username ?? "")")
                        Text("Department: \(general?.department ?? "")")
                        Text("Building: \(general?.building ?? "")")
                        Text("Last checkin: \(general?.report_date_utc ?? "")")

                        // Avoid nested quotes by using locals for defaults
                        let filevaultStatus = hardware?.diskEncryptionConfiguration ?? "Not enabled"
                        let activationLock = security?.activationLock ?? ""

                        Text("Hardware model: \(hardware?.model ?? "")")
                        Text("Filevault Status: \(filevaultStatus)")
                        Text("Activation Lock Status: \(activationLock)")
                        
                        // Show assigned prestage if available
                        let serialNumber = general?.serial_number ?? ""
                        if let prestageId = prestageController.allPrestagesScope?.serialsByPrestageID[serialNumber] ?? prestageController.serialPrestageAssignment[serialNumber] {
                            let prestageName = prestageController.allPrestages.first(where: { $0.id == prestageId })?.displayName ?? "(id:\(prestageId))"
                            // Open PrestagesEditView as a sheet via PrestageBrain state so parent can control presentation
                            Button(action: {
                                prestageController.activePrestageEditorInitialID = prestageId
                                prestageController.activePrestageEditorSerial = serialNumber
                                prestageController.isPrestageEditorActive = true
                            }) {
                                Text("Prestage: \(prestageName)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        // Top action row (Delete button + Open in Browser)
                        HStack {
                            Spacer()
                            Button(role: .destructive) {
                                showDeleteAlert = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "trash")
                                    Text("Delete Selection")
                                }
                            }
                            .disabled(isDeleting)
                            .help("Delete this computer record from the server")

                            Button(action: {
                                progress.showProgress()
                                progress.waitForABit()
                                layout.openURL(urlString: "\(server)/computers.html?id=\(computerID)&o=r", requestType: "computers")
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "safari")
                                    Text("Open In Browser")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                            .help("Open this computer in the Jamf web UI")
                        }

                        Divider()

                        // --- Additional actions copied from ComputersBasicDetailedView ---
                        // Rename field + button
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                TextField("New name", text: $computerName)
                                    .textSelection(.enabled)
                                Button(action: {
                                    progress.showProgress()
                                    progress.waitForABit()
                                    networkController.updateComputerName(server: server, authToken: networkController.authToken, resourceType: ResourceType.computerDetailed, computerName: computerName, computerID: computerID)
                                    networkController.separationLine()
                                    print("Renaming computerName:\(computerName)")
                                    print("computerID is:\(computerID)")
                                }) {
                                    Text("Rename")
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.blue)
                            }
                        }

                        // Username update field + button
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                TextField("Username", text: $editUsername)
                                    .textSelection(.enabled)
                                    .frame(minWidth: 180)
                                Button(action: {
                                    // show confirmation alert
                                    showUpdateUsernameConfirm = true
                                }) {
                                    Text("Update Username")
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.blue)
                                .disabled(editUsername.isEmpty)
                            }
                        }
                        // Overlay a small activity indicator while updating username
                        .overlay(
                            Group {
                                if isUpdatingUsername {
                                    ProgressView("Updating...")
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .padding(8)
                                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(.windowBackgroundColor).opacity(0.85)))
                                }
                            }
                        )

                        // Picker for commands + Flush button
                        HStack(alignment: .center, spacing: 12) {
                            Picker("Commands", selection: $selectedCommand) {
                                ForEach(pushController.flushCommands, id: \.self) { cmd in
                                    Text(String(describing: cmd))
                                }
                            }
                            .pickerStyle(.menu)

                            Button("Flush Commands") {
                                progress.showProgress()
                                progress.waitForABit()
                                if let compInt = Int(computerID) {
                                    Task {
                                        do {
                                            try await pushController.flushCommands(targetId: compInt, deviceType: "computers", command: selectedCommand, authToken: networkController.authToken, server: server)
                                        } catch {
                                            print("flushCommands failed: \(error)")
                                        }
                                    }
                                } else {
                                    print("Invalid computerID for flushCommands: \(computerID)")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                            .shadow(color: .gray, radius: 2, x: 0, y: 2)
                        }

                        // Extension Attribute Update Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Update Extension Attribute")
                                .font(.headline)
                                .foregroundColor(.primary)

                            HStack {
                                Text("Extension Attribute:")
                                Picker("", selection: $selectedEAName) {
                                    Text("Select...").tag("")
                                    ForEach(extensionAttributeController.allComputerExtensionAttributesDict, id: \.self) { ea in
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
                                if let compInt = Int(computerID) {
                                    Task {
                                        do {
                                            try await extensionAttributeController.updateComputerEAValue(server: server, authToken: networkController.authToken, computerId: compInt, extAttName: selectedEAName, updateValue: eaValue)
                                        } catch {
                                            print("Failed to update EA: \(error)")
                                        }
                                    }
                                } else {
                                    print("Invalid computerID for updateComputerEAValue: \(computerID)")
                                }
                            }) {
                                HStack {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                    Text("Update EA Value")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                            .disabled(selectedEAName.isEmpty)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        // --- End copied actions ---

                        if let updated = lastUpdated {
                            Text("Last updated: \(updated.formatted(.dateTime.hour().minute().second()))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

       
                    }
                    .padding()
                }

            } else if let legacy = networkController.computerDetailed {
                // Legacy fallback (lightweight record)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name: \(legacy.name)")
                    Text("ID: \(legacy.id)")
                    Text("Model: \(legacy.model)")
                    Text("Username: \(legacy.username)")
                    Text("Department: \(legacy.department)")
                    if let updated = lastUpdated {
                        Text("Last updated: \(updated.formatted(.dateTime.hour().minute().second()))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()

            } else if let msg = networkController.lastErrorMessage {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Failed to load details")
                        .font(.headline)
                    Text(msg)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("URL: \(networkController.currentURL)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Response code: \(networkController.currentResponseCode)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()

            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No details")
                    Text("Current URL: \(networkController.currentURL)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Response code: \(networkController.currentResponseCode)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
        .alert("Delete computer?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                isDeleting = true
                progress.showProgress()
                Task {
                    // Use the async await variant so we only refresh after delete completes

                    do {
                        try await networkController.deleteComputerAwait(server: server, authToken: networkController.authToken, resourceType: ResourceType.computerDetailed, itemID: computerID)
                        // Refresh the basic list to reflect deletion
                        try await networkController.getComputersBasic(server: server, authToken: networkController.authToken)
                    } catch {
                        print("Error deleting computer or refreshing list: \(error)")
                    }
                    progress.waitForABit()
                    isDeleting = false
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently remove the selected computer record from the server. Are you sure?")
        }
        // Confirmation for username update
        .alert("Update computer username?", isPresented: $showUpdateUsernameConfirm) {
            Button("Update", role: .none) {
                isUpdatingUsername = true
                progress.showProgress()
                progress.waitForABit()

                Task {
                    // perform the update (non-async function)
                    networkController.updateComputerUsername(server: server, authToken: networkController.authToken, resourceType: ResourceType.computerDetailed, computerID: computerID, newUsername: editUsername)
                    // small delay to let server process, then refresh detailed record
                    try? await Task.sleep(nanoseconds: 400_000_000)
                    do {
                        try await networkController.getDetailedComputer(userID: computerID)
                        lastUpdated = Date()
                    } catch {
                        print("Failed refreshing detail after username update: \(error)")
                        networkController.publishError(error, title: "Failed to refresh computer")
                    }
                    progress.endProgress()
                    isUpdatingUsername = false
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will update the username attribute for this computer on the server. Continue?")
        }
        .task(id: computerID) {
            print("ComputersDetailedView.task starting for computerID: \(computerID)")
            isLoading = true
            await MainActor.run {
                networkController.computerDetailedFull = nil
                networkController.computerDetailed = nil
            }
            do {
                try await networkController.getDetailedComputer(userID: computerID)
                // Populate editable username from fetched detail
                await MainActor.run {
                    self.editUsername = networkController.computerDetailedFull?.general?.username ?? networkController.computerDetailed?.username ?? ""
                }
                lastUpdated = Date()
                print("ComputersDetailedView.task completed fetch for computerID: \(computerID)")
            } catch {
                print("ComputersDetailedView: getDetailedComputer failed: \(error)")
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
            isLoading = false
            print("ComputersDetailedView.task finished for computerID: \(computerID), isLoading=\(isLoading)")
        }
    }
}
