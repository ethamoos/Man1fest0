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
            @State private var selectedCommand = ""
            @State private var selectedEAName = ""
            @State private var eaValue = ""
            @State private var computerName = ""

            @State private var isLoading: Bool = true
            @State private var lastUpdated: Date? = nil
            @State private var showDeleteAlert: Bool = false
            @State private var isDeleting: Bool = false
            @State private var editUsername: String = ""
            @State private var showUpdateUsernameConfirm: Bool = false
            @State private var isUpdatingUsername: Bool = false
            @State private var selectedTab: Int = 0
            @State private var historyLoadedForComputerID: String? = nil
            @State private var showDebugHistory: Bool = false

            @ViewBuilder
            private func generalView(detail: Any) -> some View {
                VStack(alignment: .leading, spacing: 12) {
                    // Reconstruct UI from networkController values
                    let general = networkController.computerDetailedFull?.general
                    let hardware = networkController.computerDetailedFull?.hardware
                    let security = networkController.computerDetailedFull?.security

                    Text("Name: \(general?.name ?? "")")
                    Text("ID: \(general?.id ?? "")")
                    Text("UDID: \(general?.udid ?? "")")
                    Text("Serial: \(general?.serial_number ?? "")")
                    Text("Model: \(general?.model ?? "")")
                    Text("Username: \(general?.username ?? "")")
                    Text("Department: \(general?.department ?? "")")
                    Text("Building: \(general?.building ?? "")")
                    Text("Last checkin: \(general?.report_date_utc ?? "")")

                    let filevaultStatus = hardware?.diskEncryptionConfiguration ?? "Not enabled"
                    let activationLock = security?.activationLock ?? ""

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

            @ViewBuilder
            private func historyView() -> some View {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Button(action: { historyLoadedForComputerID = nil; loadHistoryIfNeeded() }) { HStack(spacing: 8) { Image(systemName: "arrow.clockwise"); Text("Reload history") } }
                            .buttonStyle(.bordered)
                        Spacer()
                        Toggle(isOn: $showDebugHistory) { Text("Show debug").font(.caption) }.toggleStyle(.switch).labelsHidden()
                    }

                    Text("Computer History").font(.title2).fontWeight(.semibold)

                    if let history = networkController.computerHistory {
                        if let gen = history.general { Text("Name: \(gen.name ?? "")"); Text("ID: \(gen.id ?? "")"); Text("Serial: \(gen.serialNumber ?? "")") }
                        if let cmds = history.commands?.completed?.command, !cmds.isEmpty { Divider(); Text("Completed Commands").font(.headline); ForEach(cmds.indices, id: \.self) { i in let cmd = cmds[i]; VStack(alignment: .leading) { Text(cmd.name ?? "").font(.subheadline); Text("Completed: \(cmd.completed ?? "") by \(cmd.username ?? "")").font(.caption).foregroundColor(.secondary) }.padding(.vertical, 4) } }
                        if let policies = history.policyLogs?.policyLog, !policies.isEmpty { Divider(); Text("Policy Logs").font(.headline); ForEach(policies.indices, id: \.self) { i in let pl = policies[i]; VStack(alignment: .leading) { Text(pl.policyName ?? "").font(.subheadline); Text("Status: \(pl.status ?? "")").font(.caption).foregroundColor(.secondary) }.padding(.vertical, 4) } }
                    } else { ProgressView("Loading history...").frame(maxWidth: .infinity, alignment: .center) }

                    if showDebugHistory { Divider(); Text("Full computerHistory object:").font(.caption).foregroundColor(.secondary); ScrollView(.horizontal) { Text(String(describing: networkController.computerHistory)).font(.system(.body, design: .monospaced)).textSelection(.enabled).padding(6) } }
                }
                .onAppear { if selectedTab == 1 { loadHistoryIfNeeded() } }
            }

            private func loadHistoryIfNeeded() {
                print("ComputersDetailedView: History tab selected for computerID: \(self.computerID)")
                if historyLoadedForComputerID != self.computerID {
                    Task { await MainActor.run { networkController.computerHistory = nil } }
                    Task {
                        do {
                            try await networkController.getComputerHistory(server: self.server, computerID: self.computerID)
                            await MainActor.run { historyLoadedForComputerID = self.computerID }
                        } catch {
                            print("Failed to fetch computer history on tab change: \(error)")
                        }
                    }
                } else {
                    print("ComputersDetailedView: history already loaded for id: \(self.computerID)")
                }
            }

            var body: some View {
                Group {
                    if isLoading && networkController.computerDetailedFull == nil && networkController.computerDetailed == nil {
                        ProgressView("Loading computer...").frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let detail = networkController.computerDetailedFull {
                        ScrollView { TabView(selection: $selectedTab) { generalView(detail: detail).padding().tag(0).tabItem { Text("General") }; historyView().padding().tag(1).tabItem { Text("History") } }.onChange(of: selectedTab) { newVal in if newVal == 1 { loadHistoryIfNeeded() } }.tabViewStyle(DefaultTabViewStyle()) }
                    } else if let legacy = networkController.computerDetailed {
                        VStack(alignment: .leading, spacing: 8) { Text("Name: \(legacy.name)"); Text("ID: \(legacy.id)"); Text("Model: \(legacy.model)"); Text("Username: \(legacy.username)"); Text("Department: \(legacy.department)"); if let updated = lastUpdated { Text("Last updated: \(updated.formatted(.dateTime.hour().minute().second()))").font(.caption2).foregroundColor(.secondary) } }.padding()
                    } else if let msg = networkController.lastErrorMessage {
                        VStack(alignment: .leading, spacing: 12) { Text("Failed to load details").font(.headline); Text(msg).font(.subheadline).foregroundColor(.secondary); Text("URL: \(networkController.currentURL)").font(.caption).foregroundColor(.secondary); Text("Response code: \(networkController.currentResponseCode)").font(.caption).foregroundColor(.secondary) }.padding()
                    } else {
                        VStack(alignment: .leading, spacing: 8) { Text("No details"); Text("Current URL: \(networkController.currentURL)").font(.caption).foregroundColor(.secondary); Text("Response code: \(networkController.currentResponseCode)").font(.caption).foregroundColor(.secondary) }.frame(maxWidth: .infinity, maxHeight: .infinity).padding()
                    }
                }
                .alert("Delete computer?", isPresented: $showDeleteAlert) {
                    Button("Delete", role: .destructive) { isDeleting = true; progress.showProgress(); Task { do { try await networkController.deleteComputerAwait(server: self.server, authToken: networkController.authToken, resourceType: ResourceType.computerDetailed, itemID: self.computerID); try await networkController.getComputersBasic(server: self.server, authToken: networkController.authToken) } catch { print("Error deleting computer or refreshing list: \(error)") }; progress.waitForABit(); isDeleting = false } }
                    Button("Cancel", role: .cancel) { }
                } message: { Text("This will permanently remove the selected computer record from the server. Are you sure?") }
                .alert("Update computer username?", isPresented: $showUpdateUsernameConfirm) {
                    Button("Update") { isUpdatingUsername = true; progress.showProgress(); progress.waitForABit(); Task { networkController.updateComputerUsername(server: self.server, authToken: networkController.authToken, resourceType: ResourceType.computerDetailed, computerID: self.computerID, newUsername: editUsername); try? await Task.sleep(nanoseconds: 400_000_000); do { try await networkController.getDetailedComputer(userID: self.computerID); lastUpdated = Date() } catch let error { networkController.publishError(error, title: "Failed to refresh computer") }; progress.endProgress(); isUpdatingUsername = false } }
                    Button("Cancel", role: .cancel) { }
                } message: { Text("This will update the username attribute for this computer on the server. Continue?") }
                .task(id: self.computerID) { isLoading = true; await MainActor.run { networkController.computerDetailedFull = nil; networkController.computerDetailed = nil }; do { try await networkController.getDetailedComputer(userID: self.computerID); await MainActor.run { self.editUsername = networkController.computerDetailedFull?.general?.username ?? networkController.computerDetailed?.username ?? "" }; lastUpdated = Date() } catch let error { print("ComputersDetailedView: getDetailedComputer failed: \(error)") }; try? await Task.sleep(nanoseconds: 100_000_000); isLoading = false }
            }
        }
