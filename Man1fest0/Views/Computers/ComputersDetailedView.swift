import SwiftUI

struct ComputersDetailedView: View {
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var layout: Layout
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var pushController: PushBrain
    @EnvironmentObject var extensionAttributeController: EaBrain
    @EnvironmentObject var prestageController: PrestageBrain
    
    // Required inputs passed in when this view is created
    var server: String
    var computerID: String
    
    // Local UI state
    @State private var selectedCommand: String = ""
    @State private var selectedEAName: String = ""
    @State private var eaValue: String = ""
    @State private var computerName: String = ""
    
    @State private var isLoading: Bool = true
    @State private var lastUpdated: Date? = nil
    @State private var showDeleteAlert: Bool = false
    @State private var isDeleting: Bool = false
    @State private var editUsername: String = ""
    @State private var showUpdateUsernameConfirm: Bool = false
    @State private var isUpdatingUsername: Bool = false
    @State private var selectedTab: Int = 0
    @State private var historyInnerTab: Int = 0
    @State private var historyLoadedForComputerID: String? = nil
    @State private var showDebugHistory: Bool = false
    @State private var showRawHistory: Bool = false
    
    // Main subviews split to help the compiler
    @ViewBuilder
    private func generalView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Reconstruct UI from networkController values
            let general = networkController.computerDetailedFull?.general
            let hardware = networkController.computerDetailedFull?.hardware
            let security = networkController.computerDetailedFull?.security
            
            // Prefer values from the full decoded model but fall back to the lightweight
            // `computerDetailed` record that is also populated by the network controller.
            let nameVal = networkController.computerDetailedFull?.general?.name ?? networkController.computerDetailed?.name ?? ""
            let idVal = networkController.computerDetailedFull?.general?.id ?? String(networkController.computerDetailed?.id ?? 0)
            let ip_address = networkController.computerDetailedFull?.general?.ip_address ?? ""
            let udidVal = networkController.computerDetailedFull?.general?.udid ?? networkController.computerDetailed?.udid ?? ""
            let serialVal = networkController.computerDetailedFull?.general?.serial_number ?? networkController.computerDetailed?.serialNumber ?? ""
            // model may be available under Hardware.model in some responses; prefer that, then general.model, then lightweight record
            let modelVal = networkController.computerDetailedFull?.hardware?.model ?? networkController.computerDetailedFull?.general?.model ?? networkController.computerDetailed?.model ?? ""
            // Prefer values from the Location node when available (some Jamf responses put
            // username/department/building under <location> rather than <general>).
            let usernameVal = networkController.computerDetailedFull?.location?.username
                ?? networkController.computerDetailedFull?.general?.username
                ?? networkController.computerDetailed?.username
                ?? ""
            let departmentVal = networkController.computerDetailedFull?.location?.department
                ?? networkController.computerDetailed?.department
                ?? ""
            let buildingVal = networkController.computerDetailedFull?.location?.building
                ?? networkController.computerDetailed?.building
                ?? ""
            let reportDateVal = networkController.computerDetailedFull?.general?.report_date_utc ?? networkController.computerDetailed?.reportDateUTC ?? ""

            Text("Name: \(nameVal)")
            Text("ID: \(idVal)")
            Text("UDID: \(udidVal)")
            Text("Serial: \(serialVal)")
            Text("IP Adress: \(ip_address)")
            Text("Model: \(modelVal)")
            Text("Username: \(usernameVal)")
            Text("Department: \(departmentVal)")
            Text("Building: \(buildingVal)")
            Text("Last checkin: \(reportDateVal)")
            
            let filevaultStatus = hardware?.diskEncryptionConfiguration ?? "Not enabled"
            let activationLock = security?.activationLock ?? false
            
            Text("Hardware model: \(hardware?.model ?? "")")
            Text("Filevault Status: \(filevaultStatus)")
            Text("Activation Lock Status: \(activationLock)")
            
            let serialNumber = general?.serial_number ?? ""
            if let prestageId = prestageController.allPrestagesScope?.serialsByPrestageID[serialNumber] ?? prestageController.serialPrestageAssignment[serialNumber] {
                let prestageName = prestageController.allPrestages.first(where: { $0.id == prestageId })?.displayName ?? "(id:\(prestageId))"
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
            
            
            HStack {
                Spacer()
                Button(role: .destructive) { showDeleteAlert = true } label: {
                    HStack(spacing: 8) { Image(systemName: "trash"); Text("Delete Selection") }
                }
                .disabled(isDeleting)
                
                Button(action: { progress.showProgress(); progress.waitForABit(); layout.openURL(urlString: "\(self.server)/computers.html?id=\(self.computerID)&o=r", requestType: "computers") }) { HStack(spacing: 8) { Image(systemName: "safari"); Text("Open In Browser") } }
                    .buttonStyle(.borderedProminent).tint(.green)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    TextField("New name", text: $computerName).textSelection(.enabled)
                    Button(action: { progress.showProgress(); progress.waitForABit(); networkController.updateComputerName(server: self.server, authToken: networkController.authToken, resourceType: ResourceType.computerDetailed, computerName: computerName, computerID: self.computerID); networkController.separationLine() }) { Text("Rename") }
                        .buttonStyle(.borderedProminent).tint(.blue)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    TextField("Username", text: $editUsername).textSelection(.enabled).frame(minWidth: 180)
                    Button(action: { showUpdateUsernameConfirm = true }) { Text("Update Username") }
                        .buttonStyle(.borderedProminent).tint(.blue).disabled(editUsername.isEmpty)
                }
            }
            .overlay(Group { if isUpdatingUsername { ProgressView("Updating...").progressViewStyle(CircularProgressViewStyle()).padding(8).background(RoundedRectangle(cornerRadius: 8).fill(Color(.windowBackgroundColor).opacity(0.85))) } })
            
            HStack(alignment: .center, spacing: 12) {
                Picker("Commands", selection: $selectedCommand) { ForEach(pushController.flushCommands, id: \.self) { cmd in Text(String(describing: cmd)) } }.pickerStyle(.menu)
                Button("Flush Commands") { progress.showProgress(); progress.waitForABit(); if let compInt = Int(self.computerID) { Task { try? await pushController.flushCommands(targetId: compInt, deviceType: "computers", command: selectedCommand, authToken: networkController.authToken, server: self.server) } } }
                    .buttonStyle(.borderedProminent).tint(.blue).shadow(color: .gray, radius: 2, x: 0, y: 2)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Update Extension Attribute").font(.headline).foregroundColor(.primary)
                HStack { Text("Extension Attribute:"); Picker("", selection: $selectedEAName) { Text("Select...").tag(""); ForEach(extensionAttributeController.allComputerExtensionAttributesDict, id: \.self) { ea in Text(ea.name).tag(ea.name) } }.pickerStyle(.menu) }
                HStack { Text("Value:"); TextField("EA Value", text: $eaValue).textFieldStyle(.roundedBorder) }
                Button(action: { progress.showProgress(); progress.waitForABit(); if let compInt = Int(self.computerID) { Task { try? await extensionAttributeController.updateComputerEAValue(server: self.server, authToken: networkController.authToken, computerId: compInt, extAttName: selectedEAName, updateValue: eaValue) } } }) { HStack { Image(systemName: "arrow.triangle.2.circlepath"); Text("Update EA Value") } }
                    .buttonStyle(.borderedProminent).tint(.blue).disabled(selectedEAName.isEmpty)
            }
            .padding().background(Color.gray.opacity(0.1)).cornerRadius(8)
            
            if let updated = lastUpdated { Text("Last updated: \(updated.formatted(.dateTime.hour().minute().second()))").font(.caption2).foregroundColor(.secondary) }
        }
    }

    // Helpers moved out of historyView to avoid nested function/result-builder issues
    private func formatEpoch(_ epoch: Int64?) -> String {
        guard let e = epoch else { return "" }
        let date = Date(timeIntervalSince1970: TimeInterval(e) / 1000.0)
        return date.formatted(.dateTime.year().month().day().hour().minute())
    }
    @ViewBuilder
    private func policiesView(_ policies: [PolicyLog]) -> some View {
        if policies.isEmpty {
            Text("No policy logs")
                .foregroundColor(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(policies.indices, id: \.self) { i in
                    let pl = policies[i]
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(pl.policyName ?? "(unknown)")
                                .font(.subheadline)
                            Text(pl.status ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(pl.dateCompleted ?? (formatEpoch(pl.dateCompletedEpoch)))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            if let user = pl.username, !user.isEmpty {
                                Text(user)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    Divider()
                }
            }
        }
    }

    @ViewBuilder
    private func commandsView(_ cmds: Commands) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let completed = cmds.completed, !completed.isEmpty {
                Text("Completed Commands").font(.headline)
                ForEach(completed.indices, id: \.self) { i in
                    let cmd = completed[i]
                    VStack(alignment: .leading) {
                        Text(cmd.name ?? "")
                            .font(.subheadline)
                        Text("Completed: \(cmd.completed ?? "") by \(cmd.username ?? "")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            if let pending = cmds.pending, !pending.isEmpty {
                Text("Pending Commands").font(.headline)
                ForEach(pending.indices, id: \.self) { i in
                    let p = pending[i]
                    VStack(alignment: .leading) {
                        Text(p.name ?? "")
                            .font(.subheadline)
                        Text(p.status ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            if let failed = cmds.failed, !failed.isEmpty {
                Text("Failed Commands").font(.headline)
                ForEach(failed.indices, id: \.self) { i in
                    let f = failed[i]
                    VStack(alignment: .leading) {
                        Text(f.name ?? "")
                            .font(.subheadline)
                        Text(f.status ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func macAppsView(_ apps: MACAppStoreApplications) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Installed: \(apps.installed?.count ?? 0), Pending: \(apps.pending?.count ?? 0), Failed: \(apps.failed?.count ?? 0)")
                .font(.caption)
                .foregroundColor(.secondary)
            if let installed = apps.installed, !installed.isEmpty {
                Divider()
                Text("Installed Apps").font(.headline)
                ForEach(installed.indices, id: \.self) { i in
                    let a = installed[i]
                    HStack {
                        VStack(alignment: .leading) {
                            Text(a.name ?? "")
                            Text(a.version ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(a.sizeMB ?? "")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func locationsView(_ locs: [CHLocation]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(locs.indices, id: \.self) { i in
                let l = locs[i]
                VStack(alignment: .leading) {
                    Text(l.fullName ?? l.username ?? "(unknown)")
                        .font(.subheadline)
                    Text(l.dateTime ?? (formatEpoch(l.dateTimeEpoch)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Divider()
            }
        }
    }

    @ViewBuilder
    private func auditsView(_ audits: [Any]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if audits.isEmpty {
                Text("No audit entries").foregroundColor(.secondary)
            } else {
                ForEach(audits.indices, id: \.self) { i in
                    let a = audits[i]
                    if let dict = a as? [String: Any] {
                        VStack(alignment: .leading) {
                            Text((dict["event"] as? String) ?? "(event)")
                                .font(.subheadline)
                            Text((dict["username"] as? String) ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if let epoch = dict["date_time_epoch"] as? Int64 {
                                Text(formatEpoch(epoch)).font(.caption2).foregroundColor(.secondary)
                            } else if let epoch = dict["date_time_epoch"] as? Int {
                                Text(formatEpoch(Int64(epoch))).font(.caption2).foregroundColor(.secondary)
                            }
                        }
                    } else {
                        Text(String(describing: a))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Divider()
                }
            }
        }
    }

    @ViewBuilder
    private func historyView() -> some View {
            // Small debug summary so we can confirm the model is being observed by the view.
            VStack(alignment: .leading, spacing: 4) {
                Text("Debug: computerHistory present: \(networkController.computerHistory != nil ? "yes" : "no")")
                    .font(.caption2).foregroundColor(.secondary)
                Text("Commands - completed: \(networkController.computerHistory?.commands?.completed?.count ?? 0), pending: \(networkController.computerHistory?.commands?.pending?.count ?? 0), failed: \(networkController.computerHistory?.commands?.failed?.count ?? 0)")
                    .font(.caption2).foregroundColor(.secondary)
                Text("User locations: \(networkController.computerHistory?.userLocation?.location?.count ?? 0)")
                    .font(.caption2).foregroundColor(.secondary)
            }

            HStack(alignment: .center) {
                Text("Computer History")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: {
                    Task {
                        do {
                            try await networkController.getComputerHistory(computerID: computerID)
                        } catch {
                            print("Failed to load computer history: \(error)")
                        }
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("Reload")
                    }
                }
                Button(action: { showRawHistory.toggle() }) {
                    Text(showRawHistory ? "Hide Raw" : "Show Raw")
                }
                .help("Toggle raw JSON response preview")
            }
            
            // Raw JSON preview (monospaced) helpful when decoding fails
            if showRawHistory, let raw = networkController.lastComputerHistoryRaw {
                ScrollView {
                    Text(raw)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(8)
                }
                .frame(maxHeight: 220)
                .background(Color(.windowBackgroundColor).opacity(0.03))
                .cornerRadius(6)
            }
            
            if let history = networkController.computerHistory {
                // inner segmented picker for history types
                Picker(selection: $historyInnerTab, label: Text("")) {
                    Text("All").tag(0)
                    Text("Policies").tag(1)
                    Text("Commands").tag(2)
                    Text("Mac Apps").tag(3)
                    Text("Locations").tag(4)
                    Text("Audits").tag(5)
                }
                .pickerStyle(.segmented)
                .padding([.vertical])

                Group {
                    switch historyInnerTab {
                    case 0:
                        // All: show all sections
                        if let gen = history.general {
                            Divider()
                            Text("General").font(.headline)
                            Text("Name: \(gen.name ?? "")")
                            Text("ID: \(gen.id.map(String.init) ?? "")")
                            Text("Serial: \(gen.serialNumber ?? "")")
                        }
                        if let locs = history.userLocation?.location, !locs.isEmpty {
                            Divider(); Text("User Location").font(.headline); locationsView(locs)
                        }
                        if let cmds = history.commands { Divider(); commandsView(cmds) }
                        if let policies = history.policyLogs?.policyLog { Divider(); policiesView(policies) }
                        if let apps = history.macAppStoreApplications { Divider(); macAppsView(apps) }
                        if let audits = history.audits { Divider(); auditsView(audits) }

                    case 1:
                        if let policies = history.policyLogs?.policyLog { policiesView(policies) } else { Text("No policy logs").foregroundColor(.secondary) }
                    case 2:
                        if let cmds = history.commands { commandsView(cmds) } else { Text("No commands").foregroundColor(.secondary) }
                    case 3:
                        if let apps = history.macAppStoreApplications { macAppsView(apps) } else { Text("No Mac App Store data").foregroundColor(.secondary) }
                    case 4:
                        if let locs = history.userLocation?.location { locationsView(locs) } else { Text("No user locations").foregroundColor(.secondary) }
                    case 5:
                        if let audits = history.audits { auditsView(audits) } else { Text("No audits").foregroundColor(.secondary) }
                    default:
                        Text("")
                    }
                }
                .animation(.default, value: historyInnerTab)
            } else {
                ProgressView("Loading history...")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }

    var body: some View {
        Group {
            if isLoading && networkController.computerDetailedFull == nil && networkController.computerDetailed == nil {
                ProgressView("Loading computer...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else if let detail = networkController.computerDetailedFull {
                // Preferred detailed model
                // Use a segmented Picker + conditional content instead of TabView to avoid
                // macOS TabView selection issues (ScrollView consuming events).
                VStack(alignment: .leading, spacing: 0) {
                    Picker(selection: $selectedTab, label: Text("")) {
                        Text("General").tag(0)
                        Text("History").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding([.top, .horizontal])

                    Group {
                        if selectedTab == 0 {
                            ScrollView {
                                generalView()
                                    .padding()
                            }
                        } else {
                            ScrollView {
                                historyView()
                                    .padding()
                                    .onAppear {
                                        // Fetch history when the History tab becomes visible
                                        if networkController.computerHistory == nil || networkController.computerHistory?.general?.idString != computerID {
                                            Task {
                                                do {
                                                    try await networkController.getComputerHistory(computerID: computerID)
                                                } catch {
                                                    print("Failed to load computer history on appear: \(error)")
                                                }
                                            }
                                        }
                                    }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .onReceive(networkController.$computerDetailedFull) { newDetail in
                    print("ComputersDetailedView: computerDetailedFull changed -> \(String(describing: newDetail?.general?.name))")
                }
                .onReceive(networkController.$computerHistory) { newHistory in
                    print("ComputersDetailedView: computerHistory changed -> present=\(newHistory != nil)")
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
                    Text("Failed to load details").font(.headline)
                    Text(msg).font(.subheadline).foregroundColor(.secondary)
                    Text("URL: \(networkController.currentURL)").font(.caption).foregroundColor(.secondary)
                    Text("Response code: \(networkController.currentResponseCode)").font(.caption).foregroundColor(.secondary)
                }
                .padding()
                
            } else {
                VStack(alignment: .leading, spacing: 8) { Text("No details"); Text("Current URL: \(networkController.currentURL)").font(.caption).foregroundColor(.secondary); Text("Response code: \(networkController.currentResponseCode)").font(.caption).foregroundColor(.secondary) }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            }
        }
        .alert("Delete computer?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                isDeleting = true
                progress.showProgress()
                Task {
                    do {
                        try await networkController.deleteComputerAwait(server: self.server, authToken: networkController.authToken, resourceType: ResourceType.computerDetailed, itemID: self.computerID)
                        try await networkController.getComputersBasic(server: self.server, authToken: networkController.authToken)
                    } catch {
                        print("Error deleting computer or refreshing list: \(error)")
                    }
                    progress.waitForABit()
                    isDeleting = false
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: { Text("This will permanently remove the selected computer record from the server. Are you sure?") }
            .alert("Update computer username?", isPresented: $showUpdateUsernameConfirm) {
                Button("Update") {
                    isUpdatingUsername = true
                    progress.showProgress()
                    progress.waitForABit()
                    Task {
                        networkController.updateComputerUsername(server: self.server, authToken: networkController.authToken, resourceType: ResourceType.computerDetailed, computerID: self.computerID, newUsername: editUsername)
                        try? await Task.sleep(nanoseconds: 400_000_000)
                        do {
                            try await networkController.getDetailedComputer(userID: self.computerID)
                            lastUpdated = Date()
                        } catch let error {
                            networkController.publishError(error, title: "Failed to refresh computer")
                        }
                        progress.endProgress()
                        isUpdatingUsername = false
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: { Text("This will update the username attribute for this computer on the server. Continue?") }
            .task(id: self.computerID) {
                isLoading = true
                await MainActor.run { networkController.computerDetailedFull = nil; networkController.computerDetailed = nil }
                do {
                    try await networkController.getDetailedComputer(userID: self.computerID)
                    await MainActor.run { self.editUsername = networkController.computerDetailedFull?.general?.username ?? networkController.computerDetailed?.username ?? "" }
                    lastUpdated = Date()
                } catch let error {
                    print("ComputersDetailedView: getDetailedComputer failed: \(error)")
                }
                try? await Task.sleep(nanoseconds: 100_000_000)
                isLoading = false
            }
        }
    }
