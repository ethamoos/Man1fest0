import SwiftUI

struct UsersActionView: View {
    @State var server: String
    @State private var searchText = ""
    
    // Selection set of UserSimple ids (stable String ids)
    @State private var selection = Set<String>()
    
    // Sorting - use the stable String id for sorting to avoid optional keypath complexity
    @State private var sortOrder: [KeyPathComparator<UserSimple>] = [
        // Default sort by name (ascending)
        .init(\UserSimple.nameForSort, order: .forward)
    ]
    
    // UI state
    @State private var isPerformingAction = false
    @State private var showResultAlert = false
    @State private var resultAlertTitle = ""
    @State private var resultAlertMessage = ""
// <<<<<<< InProgEnhancedUsers
    @State private var showDeleteConfirmation = false

// =======
    
// >>>>>>> main
    // Environment
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var layout: Layout
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                // Header
                HStack(alignment: .center) {
                    VStack(alignment: .leading) {
                        Text("Users")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Browse and manage users")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    // Refresh
                    Button(action: {
                        progress.showProgress()
                        progress.waitForABit()
                        Task {
                            do {
                                try await networkController.getAllUsers()
                            } catch {
                                networkController.publishError(error, title: "Failed to refresh users")
                            }
                        }
                    }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .disabled(isPerformingAction)
                    
                    // Open selected in Jamf Web UI
                    Button(action: {
                        guard !selection.isEmpty else { return }
                        progress.showProgress()
                        progress.waitForABit()
                        for id in selection {
                            // convert stable id back to jamf numeric id if possible
                            if id.hasPrefix("jamf-"), let jid = id.split(separator: "-").last {
                                layout.openURL(urlString: "\(server)/users.html?id=\(jid)&o=r", requestType: "users")
                            }
                        }
                    }) {
                        Label("Open in Browser", systemImage: "safari")
                    }
                    .buttonStyle(.bordered)
                    .disabled(isPerformingAction || selection.isEmpty)
// <<<<<<< InProgEnhancedUsers

                    // Delete selection (show confirmation first)
// =======
                    
//                     // Delete selection
// >>>>>>> main
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Label("Delete Selection", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .disabled(isPerformingAction || selection.isEmpty)
                }
                .padding(.bottom, 6)
                .padding(.horizontal)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.02)))
// <<<<<<< InProgEnhancedUsers

                // Secondary action bar
// =======
                
//                 // Always-visible action bar: duplicate the important actions here so they're visible
// >>>>>>> main
                HStack(spacing: 10) {
                    Spacer()
                    
                    Button(action: {
                        progress.showProgress()
                        progress.waitForABit()
                        Task {
                            do {
                                try await networkController.getAllUsers()
                            } catch {
                                networkController.publishError(error, title: "Failed to refresh users")
                            }
                        }
                    }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .disabled(isPerformingAction)
                    
                    Button(action: {
                        guard !selection.isEmpty else { return }
                        progress.showProgress()
                        progress.waitForABit()
                        for id in selection {
                            if id.hasPrefix("jamf-"), let jid = id.split(separator: "-").last {
                                layout.openURL(urlString: "\(server)/users.html?id=\(jid)&o=r", requestType: "users")
                            }
                        }
                    }) {
                        Label("Open in Browser", systemImage: "safari")
                    }
                    .buttonStyle(.bordered)
                    .disabled(isPerformingAction || selection.isEmpty)
                    
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .disabled(isPerformingAction || selection.isEmpty)
                }
                .padding(.horizontal)
                .padding(.bottom, 6)

                // Content area
                if !networkController.allUsers.isEmpty {
                    NavigationView {
    #if os(macOS)
                        Table(displayedUsers, selection: $selection, sortOrder: $sortOrder) {
                            TableColumn("Name", value: \UserSimple.nameForSort) { user in
                                HStack {
                                    Image(systemName: "person.crop.circle")
                                    Text(user.name ?? "(no name)")
                                }
                            }
                            TableColumn("Jamf ID", value: \UserSimple.jamfIdForSort) { user in
                                Text(user.jamfId.map { String($0) } ?? "—")
                                    .font(.system(.body, design: .monospaced))
                            }
                        }
                        .frame(minWidth: 400, minHeight: 300)
    #else
                        List(displayedUsers, id: \.id, selection: $selection) { user in
                            HStack {
                                Image(systemName: "person.crop.circle")
                                VStack(alignment: .leading) {
                                    Text(user.name ?? "(no name)")
                                    Text(user.jamfId.map { "ID: \\($0)" } ?? "ID: —")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
    #endif
                    }
                    .navigationViewStyle(DefaultNavigationViewStyle())
    #if os(macOS)
                    .toolbar {
                        ToolbarItemGroup {
                            Button(action: {
                                progress.showProgress()
                                progress.waitForABit()
                                Task {
                                    do { try await networkController.getAllUsers() } catch { networkController.publishError(error, title: "Failed to refresh users") }
                                }
                            }) {
                                Label("Refresh", systemImage: "arrow.clockwise")
                            }

                            Button(action: {
                                guard !selection.isEmpty else { return }
                                progress.showProgress()
                                progress.waitForABit()
                                for id in selection {
                                    if id.hasPrefix("jamf-"), let jid = id.split(separator: "-").last {
                                        layout.openURL(urlString: "\(server)/users.html?id=\(jid)&o=r", requestType: "users")
                                    }
                                }
                            }) {
                                Label("Open in Browser", systemImage: "safari")
                            }

                            Button(action: {
                                showDeleteConfirmation = true
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
    #endif

                    // footer
                    Text("\(networkController.allUsers.count) total users")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 6)
                } else {
                    ProgressView {
                        Text("Loading users")
                            .font(.title)
                            .progressViewStyle(.horizontal)
                    }
                    .padding()
                    Spacer()
                }

                // Overlay spinner while performing actions
                if isPerformingAction {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView("Performing action…")
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                        Text("Working...")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                    .padding(20)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.6)))
                }
            }
            .padding()
        }
        .alert(isPresented: $showResultAlert) {
            Alert(title: Text(resultAlertTitle), message: Text(resultAlertMessage), dismissButton: .default(Text("OK")))
        }
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Confirm Delete"),
                message: Text("Are you sure you want to delete the selected user(s)? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    Task { await performBatchDelete() }
                },
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            Task {
                if networkController.allUsers.isEmpty {
                    try? await networkController.getAllUsers()
                }
            }
        }
    } // end body

    // Combined filtering + sorting helper used by both Table (macOS) and List (other platforms)
    var displayedUsers: [UserSimple] {
        var list: [UserSimple]
        if searchText.isEmpty {
            list = networkController.allUsers
        } else {
            list = networkController.allUsers.filter { ($0.name ?? "").localizedCaseInsensitiveContains(searchText) }
        }

        if !sortOrder.isEmpty {
            list = list.sorted(using: sortOrder)
        } else {
            list.sort { $0.nameForSort < $1.nameForSort }
        }
        
        return list
    }
    
    // Perform batch delete with confirmation and progress
    @MainActor func performBatchDelete() async {
        guard !selection.isEmpty else { return }
        
        isPerformingAction = true
        progress.showProgress()
        progress.waitForABit()
        
        var successes = 0
        var failures = 0
        var failureDetails: [String] = []

        let selectedJamfIDs: [String] = selection.compactMap { stable in
            if stable.hasPrefix("jamf-") { return String(stable.split(separator: "-").last ?? "") }
            return nil
        }
        
        for jid in selectedJamfIDs {
            do {
                try await networkController.deleteUser(server: server, itemID: jid, authToken: networkController.authToken)
                successes += 1
            } catch let jamfErr as JamfAPIError {
                failures += 1
                switch jamfErr {
                case .http(let code):
                    if code == 403 {
                        failureDetails.append("\(jid): Not authorized (403)")
                    } else if code == 404 {
                        failureDetails.append("\(jid): Not found (404)")
                    } else if code == 400 {
                        // Bad Request - likely dependencies preventing delete. Include parsed details from NetBrain if available.
                        if !networkController.lastErrorDetails.isEmpty {
                            let deps = networkController.lastErrorDetails.joined(separator: ", ")
                            failureDetails.append("\(jid): Cannot delete - dependent items: \(deps)")
                        } else {
                            failureDetails.append("\(jid): Bad Request (400)")
                        }
                    } else {
                        failureDetails.append("\(jid): HTTP \(code)")
                    }
                default:
                    failureDetails.append("\(jid): \(String(describing: jamfErr))")
                }
            } catch {
                failures += 1
                // If NetBrain parsed dependency details from last response, include them for context
                if !networkController.lastErrorDetails.isEmpty {
                    let deps = networkController.lastErrorDetails.joined(separator: ", ")
                    failureDetails.append("\(jid): \(error.localizedDescription) - dependent items: \(deps)")
                } else {
                    failureDetails.append("\(jid): \(error.localizedDescription)")
                }
            }
        }

        // Refresh the list after attempted deletes
        do { try await networkController.getAllUsers() } catch { }

        isPerformingAction = false
        progress.endProgress()

        selection.removeAll()

        if failures == 0 {
            resultAlertTitle = "Delete completed"
            resultAlertMessage = "Deleted \(successes) user(s)."
        } else {
            resultAlertTitle = "Delete completed with errors"
            let shown = failureDetails.prefix(10).joined(separator: "\n")
            let more = failureDetails.count > 10 ? "\n...and \(failureDetails.count - 10) more" : ""
            resultAlertMessage = shown + more
        }
        showResultAlert = true
    }

}
