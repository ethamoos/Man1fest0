//
//  BuildingsView.swift
//  Man1fest0
//
//  Created by Amos Deane on 29/08/2024.
//

import SwiftUI

struct BuildingsView: View {
    
    var server: String
    @State private var searchText = ""
    @State var selection = Set<Building>()
    
 // // @EnvironmentObject var controller: JamfController
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var progress: Progress
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            NavigationView {
        
                
                List(searchResults, id: \.self, selection: $selection) { building in
                    
                    NavigationLink(destination:BuildingsDetailedView(server: server, building: building)) {
                        
                        HStack {
                                                Image(systemName: "building.columns")
                                                Text("\(String(describing: building.name))").font(.system(size: 12.0)).foregroundColor(.blue)

                        }
                        .background(Color.gray.opacity(0.05))
                        .foregroundColor(.blue)
#if os(macOS)
                        .navigationTitle("Buildings")
#endif
                    }
                }
                .searchable(text: $searchText)
#if os(macOS)
                .frame(minWidth: 300, maxWidth: .infinity)
#endif
                Text("\(networkController.buildings.count) total buildings")
            }
            .navigationViewStyle(DefaultNavigationViewStyle())
            
            //              ################################################################################
            //              Toolbar
            //              ################################################################################
            
                    .toolbar {
            
                        Button(action: {
                            progress.showProgress()
                            progress.waitForABit()
                            print("Refresh")
                            Task {
                            try await networkController.getBuildings(server: server, authToken: networkController.authToken)
                            }
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.clockwise")
                                Text("Refresh")
                            }
                        }
                    }
                    .foregroundColor(.blue)
                    .onAppear {
                        Task {
                            try await networkController.getBuildings(server: server, authToken: networkController.authToken)
                        }
                    }
        }
    }
    
    var searchResults: [Building] {
        if searchText.isEmpty {
            // print("Search is empty")
            //            DEBUG
            //            print(networkController.scripts)
            return networkController.buildings
        } else {
            print("Search is currently:\(searchText)")
            //            DEBUG
            //            print(controller.buildings)
            //            return controller.buildings.filter { $0.name?.lowercased().contains(searchText.lowercased())}
            return networkController.buildings
        }
    }
}


//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}


//#Preview {
//    BuildingsView()
//}
