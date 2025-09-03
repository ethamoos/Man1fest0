//
//  IconDetailedView.swift
//  Man1fest0
//
//  Created by Amos Deane on 06/09/2024.
//


import SwiftUI

struct IconDetailedView: View {
    
    @State var server: String
//    @State var iconID: String
//    @State var icons: [Icon] = []
//    @State var icon = Icon(id: 0, url: "", name: "")
    @State var selectedIcon: Icon?
    @State private var exporting = false

    @EnvironmentObject var networkController: NetBrain
    
    var body: some View {
        
        VStack() {
            LazyVGrid(columns: [GridItem(.flexible())]) {
                VStack(alignment: .leading) {
                    HStack(spacing:20) {
                    }
                    if let currentIconUrl = selectedIcon?.url {
                        AsyncImage(url: URL(string: currentIconUrl)) { image in
                            image.resizable()
                        } placeholder: {
                            Color.red
                        }
                        .frame(width: 128, height: 128)
                        .clipShape(.rect(cornerRadius: 25))
                        Text("File name is:\(String(describing: selectedIcon?.name ?? ""))")
                        Text("Url is:\(String(describing: selectedIcon?.url ?? ""))")
                        Text("ID is:\(String(describing: selectedIcon?.id ?? 0))")
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
                    
                    Button(action: { print("Downloading icon")
                        networkController.downloadIcon(jamfURL: server, itemID: String(describing: selectedIcon?.id ?? 0), authToken: networkController.authToken)
                    }) {
                        HStack(spacing:50) {
                            Image(systemName: "tortoise")
                            Text("Download")
                        }
                    }
                    .background(Color.blue)
                    .cornerRadius(8)
                    .foregroundColor(Color.white)
                    
                    
    //              ################################################################################
    //              DOWNLOAD OPTION
    //              ################################################################################

    #if os(macOS)
                    
                    Button("Export") {
                        exporting = true
                        networkController.separationLine()
//                        print("Printing text to export:\(text)")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.yellow)
                    .shadow(color: .gray, radius: 2, x: 0, y: 2)
                    
//                    .fileExporter(
//                        isPresented: $exporting,
//                        document: document,
//                        contentType: .xml
//                    ) { result in
//                        switch result {
//                        case .success(let file):
//                            print("Printing file to export:\(file)")
//                        case .failure(let error):
//                            print(error)
//                        }
//                    }
#endif

                    
                    
                    
                    
                    
                    
                }
                .frame(minWidth: 100, maxWidth: .infinity)
            }
        }
        .frame(minWidth: 100, maxWidth: .infinity, alignment: .leading)
        
        .onAppear {
            print("Icon detailed view appeared. Running onAppear")
//            print("selectedIcon is set as:\(String(describing: selectedIcon ?? 0))")
            handleConnect(server: server)
        }
    }
    
    func handleConnect(server: String) {
        print("Handling connection")
        Task {
            try await networkController.getDetailedIcon(server: server, authToken: networkController.authToken, iconID: String(describing: selectedIcon?.id ?? 0))
        }
    }
}

//struct  IconsView_Previews: PreviewProvider {
//    static var previews: some View {
//        IconDetailedView()
//    }
//}
