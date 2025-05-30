//
//  ContentView2.swift
//  JamfListApp
//
//  Created by Amos Deane on 22/03/2024.
//

import SwiftUI

struct ContentView: View {
    
//    // @EnvironmentObject var controller: JamfController
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var progress: Progress

    //  #######################################################################
    //  Login
    //  #######################################################################
    
    var server: String { UserDefaults.standard.string(forKey: "server") ?? "" }
    var username: String { UserDefaults.standard.string(forKey: "username") ?? "" }
    var password: String = ""
    
    var body: some View {
        
        NavigationView {
            if networkController.isLoading {
                VStack {
                    ProgressView()
                    Text("Loading…").foregroundColor(Color.gray)
                }
            } else {
                if #available(macOS 13.3, *) {
                    OptionsView()
                } else {
                    // Fallback on earlier versions
                }
            }
            Text("Select an Item")
                .foregroundColor(Color.gray)
        }
        .sheet(isPresented: $networkController.needsCredentials) {
            ConnectSheet(
                show: $networkController.needsCredentials
//                controller: networkController
            )
        }
        .alert(isPresented: $networkController.showAlert,
               content: {
            progress.showCustomAlert(alertTitle: networkController.alertTitle, alertMessage: networkController.alertMessage )
        })
        .task {
            
            await networkController.load()
            
            await handleConnect(server: server, username: username, password: networkController.password)
            
            Task {
                
                try await networkController.getAllPackages(server: server)
                
                try await networkController.getAllPolicies(server: server)
                
            }
        }
    }
    
    func handleConnect(server: String, username: String, password: String ) async {
        
        if password.isEmpty {
            print("Try to get password from keychain")
            guard let pwFromKeychain = try? Keychain.getPassword(service: server, account: username)
            else {
                print("pwFromKeychain failed")
                return
            }
            networkController.password = pwFromKeychain
            print("pwFromKeychain succeeded")
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
            }
            
        } catch {
            print("Error")
            print(error)
            print("Token status is:\(networkController.tokenStatusCode)")
        }
    }
}
