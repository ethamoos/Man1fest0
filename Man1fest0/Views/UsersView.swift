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
                List(searchResults, id: \.id) { (user: UserSimple) in
                    NavigationLink(destination: UserDetailedView(userID: String(describing: user.jamfId ?? 0), server: server)) {
                        HStack {
                            Image(systemName: "person")
                            Text(user.name ?? "(no name)")
                        }
                        .foregroundColor(.primary)
                    }
                }
                .navigationTitle("Jamf Users")
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
