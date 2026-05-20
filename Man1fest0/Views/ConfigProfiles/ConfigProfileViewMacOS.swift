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
    
    var searchResults: [ConfigProfileSummary] {
        // Safely unwrap the profiles array
        let profiles = networkController.allConfigProfiles.computerConfigurations ?? []

        // If no search text, return the full sorted list (case-insensitive)
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            return profiles.sorted { $0.name.lowercased() < $1.name.lowercased() }
        }

        // Otherwise filter case-insensitively and return sorted results
        return profiles
            .filter { $0.name.lowercased().contains(query.lowercased()) }
            .sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
}


//struct ConfigProfilesView_Previews: PreviewProvider {
//    static var previews: some View {
//        ConfigProfilesView()
//    }
//}
