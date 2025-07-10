//
//  Untitled 2.swift
//  Man1fest0
//
//  Created by Amos Deane on 30/01/2025.
//

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
    @State private var selection = ConfigurationProfiles.ConfigurationProfile(name: "")
    
    @State var server: String
    
    
    var body: some View {
        
        NavigationView {
            
            if networkController.allConfigProfiles.computerConfigurations?.count ?? 0 > 0 {
                
                List(searchResults, id: \.self, selection: $selection) { config in
                    NavigationLink(destination: ConfigProfileViewMacOSDetail(selection: selection, server: server)) {
                        HStack {
                            Image(systemName: "gear")
                            Text(config.name )
                        }
                            .searchable(text: $searchText)
                    }
                }
                .searchable(text: $searchText)
#if os(macOS)
                        .frame(minWidth: 400, maxWidth: .infinity)
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
