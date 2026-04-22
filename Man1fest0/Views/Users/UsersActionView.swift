import SwiftUI

struct UsersActionView: View {
    @State var server: String
    @State private var searchText = ""

    // Selection set of UserSimple ids (stable String ids)
    @State private var selection = Set<String>()

    // Sorting - use the stable String id for sorting to avoid optional keypath complexity
    @State private var sortOrder: [KeyPathComparator<UserSimple>] = [
        .init(\UserSimple.id, order: .forward)
    ]

    // UI state
    @State private var isPerformingAction = false

    // Environment
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var layout: Layout

    var body: some View {
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
                    Table(networkController.allUsers, selection: $selection, sortOrder: $sortOrder) {
                        TableColumn("Name") { user in
                            HStack {
                                Image(systemName: "person.crop.circle")
                                    .foregroundColor(.accentColor)
                                Text(user.name ?? "(no name)")
                            }
                        }
                        TableColumn("Jamf ID") { user in
                            Text(user.jamfId.map { String($0) } ?? "—")
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                    .frame(minWidth: 400, minHeight: 300)
#else
                    // iOS / other: use selectable List with stable ids
                    List(filteredUsers, id: \.id, selection: $selection) { user in
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
        .padding()
        .onAppear {
            Task {
                if networkController.allUsers.isEmpty {
                    try? await networkController.getAllUsers()
                }
            }
        }
    }

    var filteredUsers: [UserSimple] {
        if searchText.isEmpty {
            return networkController.allUsers.sorted { ($0.name ?? "") < ($1.name ?? "") }
        } else {
            return networkController.allUsers.filter { ($0.name ?? "").localizedCaseInsensitiveContains(searchText) }
        }
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
            } catch {
                failures += 1
                print("Failed to delete user \(jid): \(error)")
                networkController.publishError(error, title: "Failed to delete user \(jid)")
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

        // Optionally show summary via published error alert
        if failures > 0 {
            networkController.lastErrorTitle = "Delete completed with errors"
            networkController.lastErrorMessage = "Deleted \(successes) users; \(failures) failed."
            networkController.showErrorAlert = true
        }
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
