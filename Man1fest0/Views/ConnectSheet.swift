//
//  ConnectSheet.swift
//  JamfListApp
//
//  Created by Amos Deane on 15/04/2024.
//

import Foundation
import SwiftUI

struct ConnectSheet: View {
    
    @Binding var show: Bool
    @EnvironmentObject var networkController: NetBrain
    
    @State var saveInKeychain: Bool = false
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var showActivity = false
    
    @AppStorage("server") var server = ""
    @AppStorage("username") var username = ""
    
    // --- Multi-server credential support ---------------------------------
    struct Credential: Identifiable, Codable, Equatable {
        let id: UUID
        var server: String
        var username: String
        var label: String?
    }
    
    @State private var savedCredentials: [Credential] = []
    @State private var selectedCredentialID: UUID? = nil
    private let savedCredentialsKey = "SavedCredentialsList"
    // ---------------------------------------------------------------------
    
    var body: some View {
                
        VStack {
            VStack {
                // Saved credentials picker + actions
                if !savedCredentials.isEmpty {
                    HStack {
                        Label("Saved Servers", systemImage: "tray.full")
                        Picker(selection: Binding(get: {
                            selectedCredentialID
                        }, set: { newValue in
                            selectedCredentialID = newValue
                            if let id = newValue, let cred = savedCredentials.first(where: { $0.id == id }) {
                                selectCredential(cred)
                            }
                        }), label: Text("Saved Servers")) {
                            ForEach(savedCredentials) { cred in
                                Text(cred.server + " (" + cred.username + ")").tag(Optional(cred.id))
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: 300)

                        Button(action: {
                            // delete currently selected
                            if let id = selectedCredentialID, let cred = savedCredentials.first(where: { $0.id == id }) {
                                deleteCredential(cred)
                            }
                        }) {
                            Image(systemName: "trash")
                        }
                        .help("Delete selected saved credential")
                    }
                    .padding(.bottom, 6)
                }

                Form {
                    HStack {
                        Label("", systemImage: "globe")
                        TextField("Server", text: $server)
                            .disableAutocorrection(true)
    #if os(iOS)
                                                    .autocapitalization(.none)
                                                    .textInputAutocapitalization(.never)
    #endif
                    }
                        .frame(width: 400)
                    
                    HStack {
                        Label("", systemImage: "person")
                        TextField("Username", text: $username)
                            .disableAutocorrection(true)
    #if os(iOS)
                                                    .autocapitalization(.none)
                                                    .textInputAutocapitalization(.never)
    #endif
                    }
                    HStack {
                        Label("", systemImage: "ellipsis.rectangle")
                        SecureField("Password", text: $networkController.password)
                            .disableAutocorrection(true)
    #if os(iOS)
                                                    .autocapitalization(.none)
                                                    .textInputAutocapitalization(.never)
    #endif
                    }
                    Toggle("Save in Keychain", isOn: $saveInKeychain)
                }
            }.padding()
            
    #if os(macOS)
            HStack {
                Spacer()
                Button("Cancel") {
                    show = false
                }
                .keyboardShortcut(.escape)
                ////  #######################################################################
                ////  CONNECTION - button on sheet
                ////  #######################################################################
                HStack(spacing:30) {
                    Button("Connect") {
                        Task { await connect() }
                        print("Pressing button")
                        print("networkController.showAlert is set as:\(networkController.showAlert)")
                        print("showAlert is set as:\(showAlert)")
                        alertMessage = "Could not authenticate. Please check the url and authentication details"
                        alertTitle = "Authentication Error"
                    }
                }
            }.padding()
    #else
            
            HStack {
                Button("Cancel") {
                    show = false
                }
                .buttonStyle(.borderedProminent)
//                .tint(.blue)
            }
            
            HStack(spacing:30) {
                Button("Connect") {
                    Task { await connect() }
                    print("Pressing button")
                    print("networkController.showAlert is set as:\(networkController.showAlert)")
                    print("showAlert is set as:\(showAlert)")
                    alertMessage = "Could not authenticate. Please check the url and authentication details"
                    alertTitle = "Authentication Error"
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
    #endif
            
            // Save / update credential button row
            HStack(spacing: 12) {
                Button(action: {
                    saveCurrentCredential()
                }) {
                    Label("Save Credential", systemImage: "key")
                }
                .disabled(server.isEmpty || username.isEmpty || networkController.password.isEmpty)

                Button(action: {
                    // attempt to delete based on current server+username
                    if let cred = savedCredentials.first(where: { $0.server == server && $0.username == username }) {
                        deleteCredential(cred)
                    }
                }) {
                    Label("Delete Credential", systemImage: "trash")
                }
                .disabled(!savedCredentials.contains(where: { $0.server == server && $0.username == username }))

                Spacer()
            }
            .padding([.leading, .trailing, .bottom])
        }
        .onAppear(perform: loadSavedCredentials)
    }

    func connect() async {
        show = false
    #if os(macOS)
        if saveInKeychain {
            try? Keychain.save(password: networkController.password, service: server, account: username)
        }
    #else
        if saveInKeychain {
            try? networkController.updateKC(networkController.password, account: server, service: username)
        }
    #endif
        Task {
            await handleConnect(server: server, username: username, password: networkController.password)
        }
    }
    
    func handleConnect(server: String, username: String, password: String ) async {
        
        print("Running: handleConnect")
        if password.isEmpty {
            print("Try to get password from keychain")
    #if os(macOS)
            guard let pwFromKeychain = try? Keychain.getPassword(service: server, account: username)
            else {
                print("pwFromKeychain failed")
                return
            }
            networkController.password = pwFromKeychain
            print("pwFromKeychain succeeded")
            #else
            guard let pwFromKeychain = try? networkController.getPassword(account: username, service: server)
            else {
                print("pwFromKeychain failed")
                return
            }
            networkController.password = pwFromKeychain
            print("pwFromKeychain succeeded")
    #endif
        }
        networkController.atSeparationLine()
        print("Handling connection - initial connection to Jamf")
        
        do {
            //  #######################################################################
            //  CONNECTION
            //  #######################################################################
            
            try await networkController.getToken(server: server, username: username, password: password)
            
            if networkController.authToken != "" {
                print("Token status is:\(networkController.tokenStatusCode)")
    //                print("Token is:\(networkController.authToken)")
            }
            
        } catch {
            print("Error is:\(error)")
            self.showAlert = true
        }
    }

    // MARK: - Saved credentials helpers
    private func loadSavedCredentials() {
        if let data = UserDefaults.standard.data(forKey: savedCredentialsKey), let creds = try? JSONDecoder().decode([Credential].self, from: data) {
            self.savedCredentials = creds
            // if current server/username match a saved credential, pre-select it and load the password
            if let match = creds.first(where: { $0.server == server && $0.username == username }) {
                selectedCredentialID = match.id
                selectCredential(match)
            } else if let first = creds.first {
                // otherwise pre-select the first saved credential (but don't override server/username)
                selectedCredentialID = first.id
            }
        }
    }

    private func persistSavedCredentials() {
        if let data = try? JSONEncoder().encode(self.savedCredentials) {
            UserDefaults.standard.set(data, forKey: savedCredentialsKey)
        }
    }

    private func saveCurrentCredential() {
        guard !server.isEmpty, !username.isEmpty else { return }

        // Save password to Keychain
    #if os(macOS)
        do {
            try Keychain.save(password: networkController.password, service: server, account: username)
        } catch {
            // If duplicate or other, try update
            try? Keychain.update(password: networkController.password, service: server, account: username)
        }
    #else
        // On iOS, use NetBrain helper that manages the keychain
        networkController.updateKC(networkController.password, account: server, service: username)
    #endif

        // Save metadata to UserDefaults (avoid duplicates)
        if let idx = savedCredentials.firstIndex(where: { $0.server == server && $0.username == username }) {
            savedCredentials[idx].server = server
            savedCredentials[idx].username = username
        } else {
            let cred = Credential(id: UUID(), server: server, username: username, label: nil)
            savedCredentials.append(cred)
            selectedCredentialID = cred.id
        }
        persistSavedCredentials()
    }

    private func deleteCredential(_ cred: Credential) {
        // remove from keychain
    #if os(macOS)
        try? Keychain.delete(service: cred.server, account: cred.username)
    #else
        try? networkController.deleteKC(account: cred.server, service: cred.username)
    #endif
        // remove from list
        savedCredentials.removeAll(where: { $0.id == cred.id })
        if selectedCredentialID == cred.id { selectedCredentialID = nil }
        persistSavedCredentials()
    }

    private func selectCredential(_ cred: Credential) {
        server = cred.server
        username = cred.username
    #if os(macOS)
        if let pw = try? Keychain.getPassword(service: cred.server, account: cred.username) {
            networkController.password = pw
        }
    #else
        if let pw = try? networkController.getPassword(account: cred.username, service: cred.server) {
            networkController.password = pw
        }
    #endif
    }
}




//struct ConnectSheet_Previews: PreviewProvider {
//    static var previews: some View {
//      ConnectSheet(show: .constant(true), controller: JamfController())
//    }
//}
