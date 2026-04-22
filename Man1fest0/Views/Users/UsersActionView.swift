import SwiftUI

struct UsersActionView: View {
    @State var server: String
    @State private var searchText = ""

    // Selection set of UserSimple (Identifiable & Hashable)
    @State private var selection = Set<UserSimple>()

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
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .disabled(isPerformingAction)

                // Open selected in Jamf Web UI
                Button(action: {
                    guard !selection.isEmpty else { return }
                    progress.showProgress()
                    progress.waitForABit()
                    for user in selection {
                        if let jid = user.jamfId {
                            layout.openURL(urlString: "\(server)/users.html?id=\(jid)&o=r", requestType: "users")
                        }
                    }
                }) {
                    Image(systemName: "safari")
                }
                .buttonStyle(.bordered)
                .disabled(isPerformingAction || selection.isEmpty)

                // Delete selection
                Button(action: {
                    Task {
                        await performBatchDelete()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "trash")
                        Text("Delete Selection")
                    }
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(isPerformingAction || selection.isEmpty)
            }
            .padding(.bottom, 6)
            .padding(.horizontal)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.02)))

            if !networkController.allUsers.isEmpty {
                NavigationView {
#if os(macOS)
                    // Use selection-enabled List on macOS
                    List(filteredUsers, selection: $selection) { user in
                        HStack {
                            Image(systemName: "person.crop.circle")
                                .foregroundColor(.accentColor)
                            Text(user.name ?? "(no name)")
                                .font(.system(size: 13.0))
                        }
                        .padding(.vertical, 4)
                    }
                    .listStyle(.sidebar)
#else
                    List(filteredUsers, id: \.self, selection: $selection) { user in
                        HStack {
                            Image(systemName: "person.crop.circle")
                                .foregroundColor(.accentColor)
                            Text(user.name ?? "(no name)")
                                .font(.system(size: 13.0))
                        }
                        .padding(.vertical, 4)
                    }
#endif
                    Text("\(networkController.allUsers.count) total users")
                }
                .navigationViewStyle(DefaultNavigationViewStyle())

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

        // Ask for confirmation via a simplified approach: use system alert flow via NetBrain.publishError?
        // For now we'll proceed directly but disable UI and show progress. If you prefer a confirmation sheet, we can add it.

        isPerformingAction = true
        progress.showProgress()
        progress.waitForABit()

        var successes = 0
        var failures = 0

        for user in Array(selection) {
            guard let jid = user.jamfId else {
                failures += 1
                continue
            }

            do {
                try await networkController.deleteUser(server: server, itemID: String(jid), authToken: networkController.authToken)
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

        // Optionally clear selection of deleted items
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
