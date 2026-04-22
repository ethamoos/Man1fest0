//
//  UsersView.swift
//  PackageTourist
//
//  Created by automated edit on 2026-01-12.
//

import SwiftUI

struct UsersView: View {
    
    @EnvironmentObject var networkController: NetBrain

    @State private var searchText: String = ""
    @State var server: String

    var body: some View {
        Group {
            if networkController.allUsers.count > 0 {
                // On macOS putting a searchable on both the master/detail views can cause
                // NSToolbar to attempt to insert duplicate search items (crash). Apply
                // the searchable modifier only on non-macOS platforms and include
                // navigationTitle in both branches to keep the view modifier chain valid.
#if os(macOS)
                List(searchResults) { (user: UserSimple) in
                    NavigationLink(destination: UserDetailedView(userID: String(describing: user.jamfId ?? 0), server: server)) {
                        HStack {
                            Image(systemName: "person")
                            Text(user.name ?? "(no name)")
                        }
                        .foregroundColor(.primary)
                    }
                }
                .navigationTitle("Jamf Users")
#else
                List(searchResults) { (user: UserSimple) in
                    NavigationLink(destination: UserDetailedView(userID: String(describing: user.jamfId ?? 0), server: server)) {
                        HStack {
                            Image(systemName: "person")
                            Text(user.name ?? "(no name)")
                        }
                        .foregroundColor(.primary)
                    }
                }
                .searchable(text: $searchText)
                .navigationTitle("Jamf Users")
#endif
            } else {
                VStack {
                    Text("No users loaded")
                    Button("Refresh") {
                        Task {
                            do {
                                try await networkController.getAllUsers()
                            } catch {
                                // networkController publishes the error; nothing more needed here
                                print("getAllUsers failed: \(error)")
                            }
                        }
                    }
                }
            }
        }
        .alert(isPresented: $networkController.showErrorAlert) {
            Alert(title: Text(networkController.lastErrorTitle ?? "Error"), message: Text(networkController.lastErrorMessage ?? ""), dismissButton: .default(Text("OK")) )
        }
        .onAppear() {
            
            Task {
                do {
                    try await networkController.getAllUsers()
                }
            }
        }
    }

    var searchResults: [UserSimple] {
        if searchText.isEmpty {
            return networkController.allUsers
        } else {
            let lowered = searchText.lowercased()
            return networkController.allUsers.filter { ( $0.name ?? "" ).lowercased().contains(lowered) }
        }
    }
}

//#Preview {
//    UsersView(server: "")
//}
