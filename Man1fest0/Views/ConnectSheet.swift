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
    
    var body: some View {
                
        VStack {
            VStack {
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
        }
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
}






//struct ConnectSheet_Previews: PreviewProvider {
//    static var previews: some View {
//      ConnectSheet(show: .constant(true), controller: JamfController())
//    }
//}


