//
//  IconDetailedView.swift
//  Man1fest0
//
//  Created by Amos Deane on 06/09/2024.
//


import SwiftUI
//import URLImage
import Foundation

struct IconDetailedView: View {
    
    var selectedResourceType: ResourceType
    @State var server: String
//    @State var user: String
//    @State var password: String
    
    @State var iconID: String
    @State var icons: [Icon] = []
    @State var icon = Icon(id: 0, url: "", name: "")
    @State var selectedIcon: Icon?
    
    @State var selection: [Icon] = []
    
    @EnvironmentObject var networkController: NetBrain
    
    var body: some View {
        
        VStack() {
                LazyVGrid(columns: [GridItem(.flexible())]) {
                VStack(alignment: .leading) {
                    HStack(spacing:20) {
                    }
                    if let currentIconUrl = selectedIcon?.url {
//                        URLImage(URL(string:currentIconUrl)!){ image in
//                            image.resizable().frame(width: 50, height: 50)
//                        }
                        AsyncImage(url: URL(string: currentIconUrl)) { image in
                            image.resizable()
                        } placeholder: {
                            Color.red
                        }
                        .frame(width: 128, height: 128)
                        .clipShape(.rect(cornerRadius: 25))
                    }
                    
                    Button(action: { print("Pressing button")
                        handleConnect(server: server)
                    }) {
                        HStack(spacing:20) {
                            Image(systemName: "tortoise")
                            Text("Update")
                        }
                    }
                    .background(Color.blue)
                    .cornerRadius(8)
                    .foregroundColor(Color.white)
                    
//                    Button(action: { print("Downloading icon")
//                        networkController.downloadIcon(jamfURL: server, itemID: iconID, authToken: networkController.authToken)
//                    }) {
//                        HStack(spacing:50) {
//                            Image(systemName: "tortoise")
//                            Text("Download")
//                        }
//                    }
//                    .background(Color.blue)
//                    .cornerRadius(8)
//                    .foregroundColor(Color.white)
                    
                }
                .frame(minWidth: 100, maxWidth: .infinity)
            }
        }
        .frame(minWidth: 100, maxWidth: .infinity, alignment: .leading)
        
        .onAppear {
            print("icon appeared. Running onAppear")
            print("\(selectedResourceType) View appeared - connecting")
            print("Searching for \(selectedResourceType)")
            handleConnect(server: server)
        }
    }
    
    func handleConnect(server: String) {
        print("Handling connection")
//        networkController.getIconDetails(jamfURL: server, itemID: iconID, authToken: networkController.authToken)
    }
}

//struct IconView_Previews: PreviewProvider {
//    static var previews: some View {
//        IconDetailedView()
//    }
//}
