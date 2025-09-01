//
//   IconsView.swift.
//  Man1fest0
//
//  Created by Amos Deane on 05/09/2024.
//

import SwiftUI
//import URLImage

struct  IconsView: View {
    
    
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var xmlController: XmlBrain
    
    @State var server: String
    //    @State var icons: [Icon] = []
    @State var selectedIcon: Icon = Icon(id: 0, url: "", name: "")
    
    
    var body: some View {
        
        VStack {
            //
            if networkController.allIconsDetailed.count > 0 {
                
                NavigationView {
                    List(networkController.allIconsDetailed, id: \.self, selection: $selectedIcon) { icon in
                        NavigationLink(destination: IconDetailedView( server: server, selectedIcon: selectedIcon )) {
                            
                            HStack {
                                Image(systemName: "photo.circle")
                                Text(icon.name ).font(.system(size: 12.0)).foregroundColor(.black)
                            }
                        }
                        .cornerRadius(8)
                        .frame(minWidth: 300, maxWidth: .infinity, alignment: .leading)
                        
                    }
                    Text("\(networkController.allIconsDetailed.count) total icons")
                }
                .navigationViewStyle(DefaultNavigationViewStyle())
            } else {
                ProgressView {
                    Text("Loading")
                        .font(.title)
                    //                    .progressViewStyle(.horizontal)
                }
                .padding()
                Spacer()
            }
        }
        
        .onAppear() {
            if networkController.allIconsDetailed.count <= 1 {
                print("getAllIconsDetailed is:\(networkController.allIconsDetailed.count) - running")
                networkController.getAllIconsDetailed(server: server, authToken: networkController.authToken, loopTotal: 1000)
            } else {
                print("getAllIconsDetailed has already run")
                print("getAllIconsDetailed is:\(networkController.allIconsDetailed.count) - running")
            }
        }
    }
}
