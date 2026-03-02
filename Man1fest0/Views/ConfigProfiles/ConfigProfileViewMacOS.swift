//
//  ConfigProfilesView.swift
//  PackageTourist
//
//  Created by Amos Deane on 21/11/2023.
//

import SwiftUI

struct ConfigProfileViewMacOS: View {
    
    @EnvironmentObject var networkController: NetBrain
    @State private var searchText = ""
    
    @State var server: String
    
    
    var body: some View {
        
        NavigationView {
            
            if networkController.allConfigProfiles.computerConfigurations?.count ?? 0 > 0 {
                
                // Use List without selection and pass the tapped `config` to the detail view.
                List(searchResults, id: \.id) { config in
                    NavigationLink(destination: ConfigProfileViewMacOSDetail(selection: config, server: server)) {
                        HStack {
                            Image(systemName: "gear")
                            Text(config.name )
                        }
                    }
                }
                .searchable(text: $searchText)
#if os(macOS)
                        .frame(minWidth: 300, maxWidth: .infinity)
#endif
                //                Button(action: {
                //                    print("Deleting:\($selection)")
                //                }) {
                //                    HStack(spacing: 10) {
                //                        Image(systemName: "trash")
                //                        Text("Delete")
                //                    }
                //                    .padding()
                //                }
                //                //    }
                
//                .padding()
                .textSelection(.enabled)
            }
        }
        .onAppear {
            print("Fetching config profiles")
            Task {
                try await networkController.getOSXConfigProfiles(server: server, authToken: networkController.authToken)
            }
        }
    }
    
    var searchResults: [ConfigurationProfiles.ConfigurationProfile] {
        if searchText.isEmpty {
            return networkController.allConfigProfiles.computerConfigurations!.sorted { $0.name < $1.name }
        } else {
            print("Search is currently:\(searchText)")
            return networkController.allConfigProfiles.computerConfigurations!.filter {$0.name.contains(searchText) }
        }
    }
}


//struct ConfigProfilesView_Previews: PreviewProvider {
//    static var previews: some View {
//        ConfigProfilesView()
//    }
//}
