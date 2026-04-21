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
    var userID: String
    var server: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if let user = networkController.userDetail {
                    // Top action row: Open in Browser
                    HStack {
                        Spacer()
                        Button(action: {
                            // Build the JSSResource URL for the user and ask Layout to open/translate it

                            
                            let trimmedServer = server.trimmingCharacters(in: .whitespacesAndNewlines)
                            var base = trimmedServer
                            if base.hasSuffix("/") { base.removeLast() }
                            // Construct a UI path using the API resource name; this mirrors the pattern used for scripts
//                            let profileID = selection.jamfId ?? 0
            
                            let uiURL = "\(base)/users.html?id=\(user.id)&o=r"
                            layout.openURL(urlString: uiURL)
                            print("Open in Browser - URL: \(uiURL)")
                            
                            
                            
                            
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
        .alert(isPresented: $networkController.showErrorAlert) {
            Alert(title: Text(networkController.lastErrorTitle ?? "Error"), message: Text(networkController.lastErrorMessage ?? ""), dismissButton: .default(Text("OK")) )
        }
    }
}

//#Preview {
//    UserDetailedView(userID: "2705", server: "")
//}
