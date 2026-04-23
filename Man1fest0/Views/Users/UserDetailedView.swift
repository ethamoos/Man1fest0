//
//  UserDetailedView.swift
//  PackageTourist
//
//  Created by automated edit on 2026-01-12.
//

import SwiftUI

struct UserDetailedView: View {
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var layout: Layout
    @Environment(\.dismiss) var dismiss
    var userID: String
    var server: String

    @State private var showingDeleteConfirmation: Bool = false
    @State private var isDeleting: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if let user = networkController.userDetail {
                    // Top action row: Open in Browser and Delete
                    HStack {
                        Spacer()

                        // Delete button
                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "trash")
                                Text(isDeleting ? "Deleting..." : "Delete User")
                            }
                        }
                        .help("Permanently delete this user from Jamf Pro")
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .disabled(isDeleting)

                        // Open in Browser button
                        Button(action: {
                            // Build the Jamf Pro UI URL for this user and ask Layout to open/translate it
                            let trimmedServer = server.trimmingCharacters(in: .whitespacesAndNewlines)
                            var base = trimmedServer
                            if base.hasSuffix("/") { base.removeLast() }
                            // Use the numeric Jamf user id from the decoded detail
                            let jamfID = String(describing: user.id)
                            // Typical Jamf Pro UI user detail URL pattern
                            let uiURL = "\(base)/users.html?id=\(jamfID)&o=r"
                            print("Open in Browser - URL: \(uiURL)")
                            // Use the Layout helper to open / translate the URL
                            layout.openURL(urlString: uiURL, requestType: "users")
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "safari")
                                Text("Open in Browser")
                            }
                        }
                        .help("Open this user in the Jamf web interface in your default browser.")
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .padding(.top, 6)

                        Spacer()
                    }
                    .padding()

                    Text(user.name ?? "(no name)")
                        .font(.title)
                        .bold()

                    Text("ID: \(user.id)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if let full = user.full_name, !full.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text("Full name: \(full)")
                    }

                    if let email = user.email ?? user.email_address {
                        Text("Email: \(email)")
                    }

                    if let phone = user.phone_number {
                        Text("Phone: \(phone)")
                    }

                    if let position = user.position {
                        Text("Position: \(position)")
                    }

                    if let managed = user.managed_apple_id, !managed.isEmpty {
                        Text("Managed Apple ID: \(managed)")
                    }

                    Text("Enable custom photo URL: \(user.enable_custom_photo_url == true ? "Yes" : "No")")

                    if let url = user.custom_photo_url, !url.isEmpty {
                        Text("Photo URL: \(url)")
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    if let ldap = user.ldap_server {
                        Text("LDAP server: \(ldap.name ?? "(none)")")
                    }

                    if let ext = user.extension_attributes, !ext.isEmpty {
                        Text("Extension attributes: \(ext.count)")
                    }

                    if let sites = user.sites, !sites.isEmpty {
                        Text("Sites: \(sites.count)")
                    }

                    if let links = user.links {
                        Text("Total VPP codes: \(links.total_vpp_code_count ?? 0)")
                    }

                    if let groups = user.user_groups {
                        Text("User groups size: \(groups.size ?? 0)")
                    }

                } else {
                    Text("Loading user details...")
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("User Detail")
        .onAppear {
            Task {
                do {
                    try await networkController.getDetailUser(userID: userID)
                    print("getDetailUser completed")
                } catch {
                    print("getDetailUser failed: \(error)")
                }
            }
        }
        // Confirmation alert for deletion
        .alert("Delete User?", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                // perform delete
                isDeleting = true
                Task {
                    do {
                        if let user = networkController.userDetail {
                            try await networkController.deleteUser(server: server, itemID: String(user.id), authToken: networkController.authToken)
                            // On success, dismiss this detail view
                            isDeleting = false
                            dismiss()
                        } else {
                            isDeleting = false
                        }
                    } catch {
                        isDeleting = false
                        networkController.publishError(error, title: "Failed to delete user")
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                // nothing
            }
        } message: {
            Text("This will permanently remove the user from Jamf Pro. This action cannot be undone.")
        }
        .alert(isPresented: $networkController.showErrorAlert) {
            // Include any parsed dependency details (e.g. computers preventing deletion) for clearer guidance
            let base = networkController.lastErrorMessage ?? ""
            let deps = networkController.lastErrorDetails.isEmpty ? "" : "\n\nDependent items: " + networkController.lastErrorDetails.joined(separator: ", ")
            return Alert(title: Text(networkController.lastErrorTitle ?? "Error"), message: Text(base + deps), dismissButton: .default(Text("OK")))
        }
    }
}

//#Preview {
//    UserDetailedView(userID: "2705", server: "")
//}
