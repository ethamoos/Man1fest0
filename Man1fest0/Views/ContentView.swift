//
//  ContentView.swift
//
//  Created by Amos Deane on 22/03/2024.
//

import SwiftUI

struct ContentView: View {
    
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
            )
        }
        .alert(isPresented: $networkController.showAlert,
               content: {
            progress.showCustomAlert(alertTitle: networkController.alertTitle, alertMessage: networkController.alertMessage )
        })
        .task {
            
            await networkController.load()
            
            Task {
                
                try await networkController.getAllPackages(server: server)
                
                try await networkController.getAllPolicies(server: server,authToken: networkController.authToken)
                
            }
        }
    }
}
