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

                    // Delete selection
                    Button(action: {
                        Task {
                            await performBatchDelete()
                        }
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

                // Always-visible action bar: duplicate the important actions here so they're visible
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
                        Task {
                            await performBatchDelete()
                        }
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .disabled(isPerformingAction || selection.isEmpty)
                }
                .padding(.horizontal)
                .padding(.bottom, 6)

                if !networkController.allUsers.isEmpty {
                    NavigationView {
#if os(macOS)
                        // macOS: use the modern Table with columns and sorting
                        Table(displayedUsers, selection: $selection, sortOrder: $sortOrder) {
                            // Name column uses value-based key path for sorting
                            TableColumn("Name", value: \UserSimple.nameForSort) { user in
                                HStack {
                                    Image(systemName: "person.crop.circle")
                                        .foregroundColor(.accentColor)
                                    Text(user.name ?? "(no name)")
                                }
                            }

                            // Jamf ID column uses jamfIdForSort for numeric sorting
                            TableColumn("Jamf ID", value: \UserSimple.jamfIdForSort) { user in
                                Text(user.jamfId.map { String($0) } ?? "—")
                                    .font(.system(.body, design: .monospaced))
                            }
                        }
                        .frame(minWidth: 400, minHeight: 300)
#else
                        // iOS / other: use selectable List with stable ids
                        // Apply sortOrder to the list presentation on platforms without Table
                        List(displayedUsers, id: \.id, selection: $selection) { user in
                            HStack {
                                Image(systemName: "person.crop.circle")
                                    .foregroundColor(.accentColor)
                                VStack(alignment: .leading) {
                                    Text(user.name ?? "(no name)")
                                    Text(user.jamfId.map { "ID: \($0)" } ?? "ID: —")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
#endif
                        Text("\(networkController.allUsers.count) total users")
                    }
                    .navigationViewStyle(DefaultNavigationViewStyle())
#if os(macOS)
                    // Make actions available in the macOS window toolbar so they're always visible
                    .toolbar {
                        ToolbarItemGroup {
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
                            Task {
                                await performBatchDelete()
                            }
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .disabled(isPerformingAction || selection.isEmpty)
                    }
                }
#endif

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
        }
        .alert(isPresented: $showResultAlert) {
            Alert(title: Text(resultAlertTitle), message: Text(resultAlertMessage), dismissButton: .default(Text("OK")))
        }

        // Semi-opaque overlay with spinner while performing actions
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
        .padding()
        .onAppear {
            Task {
                if networkController.allUsers.isEmpty {
                    try? await networkController.getAllUsers()
                }
            }
        }
    }

    // Combined filtering + sorting helper used by both Table (macOS) and List (other platforms)
    var displayedUsers: [UserSimple] {
        // Apply search filter first
        var list: [UserSimple]
        if searchText.isEmpty {
            list = networkController.allUsers
        } else {
            list = networkController.allUsers.filter { ($0.name ?? "").localizedCaseInsensitiveContains(searchText) }
        }

        // Apply primary sort from sortOrder if present
        if !sortOrder.isEmpty {
            // Use the standard sorted(using:) which understands KeyPathComparator
            list = list.sorted(using: sortOrder)
        } else {
            // Default stable sort by name
            list.sort { $0.nameForSort < $1.nameForSort }
        }

        return list
    }

    // Perform batch delete with confirmation and progress
    @MainActor func performBatchDelete() async {
        // Double-check selection
        guard !selection.isEmpty else { return }

        isPerformingAction = true
        progress.showProgress()
        progress.waitForABit()

        var successes = 0
        var failures = 0
        var failureDetails: [String] = []

        // Convert selected stable ids to jamf numeric ids
        let selectedJamfIDs: [String] = selection.compactMap { stable in
            if stable.hasPrefix("jamf-") {
                return String(stable.split(separator: "-").last ?? "")
            }
            return nil
        }

        for jid in selectedJamfIDs {
            do {
                try await networkController.deleteUser(server: server, itemID: jid, authToken: networkController.authToken)
                successes += 1
            } catch let jamfErr as JamfAPIError {
                failures += 1
                // Provide user-friendly messages for common HTTP status codes
                switch jamfErr {
                case .http(let code):
                    print("Failed to delete user \(jid): http(\(code))")
                    if code == 403 {
                        failureDetails.append("\(jid): Not authorized (403)")
                    } else if code == 404 {
                        failureDetails.append("\(jid): Not found (404) — user may already be removed or you may not have permission")
                    } else {
                        failureDetails.append("\(jid): HTTP \(code)")
                    }
                default:
                    print("Failed to delete user \(jid): \(jamfErr)")
                    failureDetails.append("\(jid): \(String(describing: jamfErr))")
                }
            } catch {
                failures += 1
                print("Failed to delete user \(jid): \(error)")
                failureDetails.append("\(jid): \(error.localizedDescription)")
            }
        }

        // Refresh users list after deletions
        do {
            try await networkController.getAllUsers()
        } catch {
            print("Failed to refresh users after delete: \(error)")
        }

        isPerformingAction = false
        progress.endProgress()

        // Clear selection
        selection.removeAll()

        // Build result alert
        if failures == 0 {
            resultAlertTitle = "Delete completed"
            resultAlertMessage = "Deleted \(successes) user(s)."
        } else {
            resultAlertTitle = "Delete completed with errors"
            // Summarize failures (limit to first 10 to avoid huge alerts)
            let shown = failureDetails.prefix(10).joined(separator: "\n")
            let more = failureDetails.count > 10 ? "\n...and \(failureDetails.count - 10) more" : ""
            resultAlertMessage = "Deleted \(successes) user(s); \(failures) failed.\n\nDetails:\n\(shown)\(more)"
        }
        showResultAlert = true
    }
}

struct UsersActionView_Previews: PreviewProvider {
    static var previews: some View {
        UsersActionView(server: "https://jamf.example.com")
            .environmentObject(NetBrain())
            .environmentObject(Progress())
            .environmentObject(Layout())
    }
}
